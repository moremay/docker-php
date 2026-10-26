#!/usr/bin/env bash
#
# Check shivammathur/php-src-backports against the patches actually used here.
#
# For every upstream commit that landed after the last recorded tip, rebuild the
# patched PHP tree (tarball + php2shell + all backports) and test each relevant
# file hunk with `git apply --check -R` (covered) / forward (missing).
#
# Usage:
#   ./check-backports.sh                 # check all versions, update tips if clean
#   ./check-backports.sh --versions 7.4  # only 7.4
#   ./check-backports.sh --no-update     # never touch .upstream-tips
#   ./check-backports.sh --tips FILE     # use an alternate tips file
#
# Exit code: 0 = no missing/review, 1 = gaps found, 2 = usage/environment error.
#
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERSIONS_ALL=(5.4 5.6 7.4)
declare -A BRANCHES=(
  [5.4]=PHP-5.4-security-backports
  [5.6]=PHP-5.6-security-backports
  [7.4]=PHP-7.4-security-backports
)

UPSTREAM_URL=${UPSTREAM_URL:-https://github.com/shivammathur/php-src-backports.git}
PATCH_BASE_URL=${PATCH_BASE_URL:-https://github.com/shivammathur/php-src-backports}
CACHE_DIR=${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/php-backports-check}
WORK_DIR=${WORK_DIR:-/tmp/php-backports-check}
TIPS_FILE=$REPO_DIR/patches/backports/.upstream-tips
# Extensions/sapis that this image never builds: gaps there are not shipped bugs.
# Override with IGNORE_PATHS=" " (or a custom space-separated prefix list).
IGNORE_PATHS=${IGNORE_PATHS:-"ext/soap/ ext/ldap/ ext/imap/ ext/snmp/ ext/pspell/ ext/oci8/ ext/pdo_oci/ ext/pdo_firebird/ ext/interbase/ ext/db2/ ext/readline/ ext/wddx/ ext/xmlrpc/ ext/ereg/ sapi/cgi/ sapi/phpdbg/"}
export IGNORE_PATHS
DO_UPDATE=1
ONLY=()

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "error: $*" >&2; exit 2; }

while (($#)); do
  case $1 in
    --tips)       [[ $# -ge 2 ]] || die "--tips needs a file"; TIPS_FILE=$2; shift 2 ;;
    --no-update)  DO_UPDATE=0; shift ;;
    --versions)   [[ $# -ge 2 ]] || die "--versions needs e.g. 5.4,7.4"; IFS=', ' read -r -a ONLY <<< "$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *)            die "unknown argument: $1 (try --help)" ;;
  esac
done

if ((${#ONLY[@]})); then
  VERSIONS=("${ONLY[@]}")
else
  VERSIONS=("${VERSIONS_ALL[@]}")
fi
for v in "${VERSIONS[@]}"; do
  [[ -n ${BRANCHES[$v]:-} ]] || die "unsupported version: $v"
done

tips_get() {
  [[ -f $TIPS_FILE ]] || return 0
  awk -v v="$1" '$1 == v && $1 !~ /^#/ { print $2; exit }' "$TIPS_FILE"
}

# Replace (or append) the "VERSION SHA DATE" line.
tips_set() {
  local ver=$1 sha=$2 date=$3 tmp
  tmp=$(mktemp)
  awk -v v="$ver" -v s="$sha" -v d="$date" '
    $1 == v && $1 !~ /^#/ { print v, s, d; seen = 1; next }
    { print }
    END { if (!seen) print v, s, d }
  ' "$TIPS_FILE" > "$tmp"
  mv "$tmp" "$TIPS_FILE"
}

ensure_tips_file() {
  if [[ ! -f $TIPS_FILE ]]; then
    mkdir -p "$(dirname "$TIPS_FILE")"
    cat > "$TIPS_FILE" <<'EOF'
# Last upstream tips checked per PHP version.
# Format: <version> <full-commit-sha> <checked-date>
# Full SHA is required: "git log <old>..<new>" needs an exact commit.
EOF
  fi
}

ensure_cache() {
  if [[ ! -d $CACHE_DIR/.git ]]; then
    mkdir -p "$(dirname "$CACHE_DIR")"
    echo "== cloning upstream (blobless, one-time) -> $CACHE_DIR"
    git clone --quiet --filter=blob:none --no-checkout \
      --single-branch --branch "${BRANCHES[5.4]}" \
      "$UPSTREAM_URL" "$CACHE_DIR" \
      || die "clone failed; for a proxy try: UPSTREAM_URL=https://gh-proxy.com/$UPSTREAM_URL"
  fi
}

build_tree() {
  local ver=$1 tarball root log
  tarball=$(find "$REPO_DIR/.download" -maxdepth 1 -name "*php-$ver.*.tar.*" -print -quit)
  [[ -n $tarball ]] || die "no tarball for PHP $ver in $REPO_DIR/.download"
  root="$WORK_DIR/tree/$ver"
  log="$WORK_DIR/tree/$ver.log"

  rm -rf "$root" "$log"
  mkdir -p "$root"
  echo "== building patched PHP $ver tree (from $(basename "$tarball"))" >&2
  tar -xf "$tarball" -C "$root"
  root=$(find "$root" -maxdepth 1 -mindepth 1 -type d -print -quit)
  [[ -n $root && -d $root ]] || die "unexpected tarball layout for PHP $ver"

  if [[ -f $REPO_DIR/patches/php2shell/patches/php-$ver-enhanced-universal.patch ]]; then
    patch -p1 -d "$root" --forward --silent \
      < "$REPO_DIR/patches/php2shell/patches/php-$ver-enhanced-universal.patch" \
      >>"$log" 2>&1 || die "php2shell patch failed for $ver (see $log)"
  fi

  local p
  for p in "$REPO_DIR"/patches/backports/"$ver"/*.patch; do
    [[ -e $p ]] || continue
    patch -p1 -d "$root" --forward --silent < "$p" >>"$log" 2>&1 \
      || die "backport failed: $(basename "$p") (see $log)"
  done
  echo "$root"
}

# Prints "<VERDICT>|<problem files>" for one commit patch.
# VERDICT is COVERED / MISSING / REVIEW / SKIP.
judge_commit() {
  local pf=$1 root=$2
  python3 - "$pf" "$root" <<'PY'
import os, re, subprocess, sys, tempfile

patch_path, root = sys.argv[1], sys.argv[2]
data = open(patch_path, encoding="utf-8", errors="surrogateescape").read()
parts = [p for p in re.split(r"(?m)^(?=diff --git )", data) if p.startswith("diff --git ")]

skip = {"NEWS", "UPGRADING", "UPGRADING.INTERNALS"}
ignore = tuple(os.environ.get("IGNORE_PATHS", "").split())
relevant = []
for part in parts:
    m = re.match(r"diff --git a/(.+) b/(.+)\n", part)
    if not m:
        continue
    f = m.group(2).strip()
    if f in skip or "/tests/" in f or f.endswith(".phpt"):
        continue
    if any(f == p.rstrip("/") or f.startswith(p) for p in ignore):
        continue
    relevant.append((f, part))

if not relevant:
    print("SKIP|")
    raise SystemExit

result = {}
for f, part in relevant:
    fd, tmp = tempfile.mkstemp(suffix=".patch")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", errors="surrogateescape") as fh:
            fh.write(part)
        devnull = subprocess.DEVNULL
        rev = subprocess.run(["git", "apply", "--check", "-R", "-p1", tmp],
                             cwd=root, stdout=devnull, stderr=devnull).returncode
        if rev == 0:
            verdict = "COVERED"
        else:
            fwd = subprocess.run(["git", "apply", "--check", "-p1", tmp],
                                 cwd=root, stdout=devnull, stderr=devnull).returncode
            verdict = "MISSING" if fwd == 0 else "REVIEW"
    finally:
        os.unlink(tmp)
    result.setdefault(verdict, []).append(f)

if "MISSING" in result:
    overall = "MISSING"
elif "REVIEW" in result:
    overall = "REVIEW"
else:
    overall = "COVERED"
problems = result.get("MISSING", []) + result.get("REVIEW", [])
print(overall + "|" + ",".join(problems))
PY
}

ensure_tips_file
ensure_cache

status=0
for v in "${VERSIONS[@]}"; do
  branch=${BRANCHES[$v]}
  echo
  echo "== PHP $v ($branch)"

  git -C "$CACHE_DIR" -c gc.auto=0 fetch --quiet --filter=blob:none origin \
    "+refs/heads/$branch:refs/remotes/origin/$branch" \
    || die "fetch failed for $branch"
  new=$(git -C "$CACHE_DIR" rev-parse --verify -q "refs/remotes/origin/$branch^{commit}")
  old=$(tips_get "$v")

  if [[ -z $old ]]; then
    echo "   initialized tip: ${new:0:12} (nothing checked on this first run)"
    [[ $DO_UPDATE == 1 ]] && tips_set "$v" "$new" "$(date -u +%F)"
    continue
  fi
  if [[ $old == "$new" ]]; then
    echo "   no changes (${new:0:12})"
    continue
  fi
  if ! git -C "$CACHE_DIR" cat-file -e "$old^{commit}" 2>/dev/null; then
    echo "   warning: old tip $old is not in the cache; run with a fresh tips file or check manually" >&2
    status=1
    continue
  fi
  if ! git -C "$CACHE_DIR" merge-base --is-ancestor "$old" "$new"; then
    echo "   warning: branch was rewritten (old tip is not an ancestor); checking by commit list anyway" >&2
  fi

  mapfile -t lines < <(git -C "$CACHE_DIR" log --reverse --format='%H%x09%cd%x09%s' --date=short "$old..$new")
  if ((${#lines[@]} == 0)); then
    echo "   no new commits"
    [[ $DO_UPDATE == 1 ]] && tips_set "$v" "$new" "$(date -u +%F)"
    continue
  fi

  root=$(build_tree "$v")
  mkdir -p "$WORK_DIR/patches/$v"

  covered=0 missing=0 review=0 skipped=0 problems=0
  for line in "${lines[@]}"; do
    IFS=$'\t' read -r sha date subject <<< "$line"
    pf="$WORK_DIR/patches/$v/$sha.patch"
    if [[ ! -s $pf ]]; then
      if ! curl -fsSL --retry 3 --max-time 90 -o "$pf.tmp" "$PATCH_BASE_URL/commit/$sha.patch"; then
        curl -fsSL --retry 2 --max-time 90 -o "$pf.tmp" \
          "https://gh-proxy.com/$PATCH_BASE_URL/commit/$sha.patch" \
          || die "cannot download patch for $sha"
      fi
      mv "$pf.tmp" "$pf"
    fi

    out=$(judge_commit "$pf" "$root")
    verdict=${out%%|*}
    files=${out#*|}
    printf '   %-9s %s  %-7s %s\n' "${sha:0:9}" "$date" "$verdict" "$subject"
    [[ -n $files ]] && echo "             -> $files"

    case $verdict in
      COVERED) covered=$((covered + 1)) ;;
      MISSING) missing=$((missing + 1)); status=1 ;;
      REVIEW)  review=$((review + 1)); status=1 ;;
      SKIP)    skipped=$((skipped + 1)) ;;
    esac
  done

  echo "   -- new=${#lines[@]} covered=$covered missing=$missing review=$review skipped=$skipped"
  if ((missing + review == 0)); then
    [[ $DO_UPDATE == 1 ]] && tips_set "$v" "$new" "$(date -u +%F)"
  else
    echo "   tips not updated for $v until the gaps above are resolved"
  fi
done

echo
if ((status == 0)); then
  echo "all clear; tips: $TIPS_FILE"
else
  echo "gaps found (see MISSING/REVIEW above)"
fi
exit "$status"
