#!/usr/bin/awk -f

BEGIN {
    for (env in ENVIRON) {
        if (env ~ /^TMPL_/) {
            varname = substr(env, 6)
            vars[varname] = ENVIRON[env]
        }
    }
    output_enabled = 1
    if_depth = 0
    case_depth = 0
}

function trim(s) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    return s
}

function split_values(str, arr,   n, i, part) {
    delete arr
    n = split(str, parts, ",")
    arr[0] = 0
    for (i = 1; i <= n; i++) {
        part = trim(parts[i])
        if (part != "") {
            arr[++arr[0]] = part
        }
    }
}

function substitute_vars(s,   result, match_start, match_end, var_name, var_val) {
    result = s
    while (match(result, /#{{[^{}]+}}/)) {
        match_start = RSTART
        match_end = match_start + RLENGTH - 1
        var_name = trim(substr(result, match_start + 3, RLENGTH - 5))
        var_val = (var_name in vars) ? vars[var_name] : ""
        result = substr(result, 1, match_start - 1) var_val substr(result, match_end + 1)
    }
    return result
}

function eval_condition(cond,   left, right, op, pos, parts, val, matched, left_val, right_val) {
    cond = trim(cond)
    if (index(cond, ">=") > 0) {
        pos = index(cond, ">=")
        left = trim(substr(cond, 1, pos-1))
        right = trim(substr(cond, pos+2))
        left_val = (left in vars) ? vars[left] : ""
        right_val = right
        if (right_val ~ /^".*"$/ || right_val ~ /^'.*'$/) right_val = substr(right_val, 2, length(right_val)-2)
        return (left_val+0) >= (right_val+0)
    }
    if (index(cond, "<=") > 0) {
        pos = index(cond, "<=")
        left = trim(substr(cond, 1, pos-1))
        right = trim(substr(cond, pos+2))
        left_val = (left in vars) ? vars[left] : ""
        right_val = right
        if (right_val ~ /^".*"$/ || right_val ~ /^'.*'$/) right_val = substr(right_val, 2, length(right_val)-2)
        return (left_val+0) <= (right_val+0)
    }
    if (index(cond, ">") > 0) {
        pos = index(cond, ">")
        left = trim(substr(cond, 1, pos-1))
        right = trim(substr(cond, pos+1))
        left_val = (left in vars) ? vars[left] : ""
        right_val = right
        if (right_val ~ /^".*"$/ || right_val ~ /^'.*'$/) right_val = substr(right_val, 2, length(right_val)-2)
        return (left_val+0) > (right_val+0)
    }
    if (index(cond, "<") > 0) {
        pos = index(cond, "<")
        left = trim(substr(cond, 1, pos-1))
        right = trim(substr(cond, pos+1))
        left_val = (left in vars) ? vars[left] : ""
        right_val = right
        if (right_val ~ /^".*"$/ || right_val ~ /^'.*'$/) right_val = substr(right_val, 2, length(right_val)-2)
        return (left_val+0) < (right_val+0)
    }
    if (index(cond, "!~") > 0) {
        pos = index(cond, "!~")
        left = trim(substr(cond, 1, pos-1))
        right = trim(substr(cond, pos+2))
        if (right ~ /^".*"$/ || right ~ /^'.*'$/) right = substr(right, 2, length(right)-2)
        val = (left in vars) ? vars[left] : ""
        matched = (match(val, right) > 0)
        return !matched
    }
    if (index(cond, "~") > 0) {
        pos = index(cond, "~")
        left = trim(substr(cond, 1, pos-1))
        right = trim(substr(cond, pos+1))
        if (right ~ /^".*"$/ || right ~ /^'.*'$/) right = substr(right, 2, length(right)-2)
        val = (left in vars) ? vars[left] : ""
        return (match(val, right) > 0)
    }
    if (index(cond, "==") > 0) {
        split(cond, parts, "==")
        left = trim(parts[1])
        right = trim(parts[2])
        if (right ~ /^".*"$/ || right ~ /^'.*'$/) right = substr(right, 2, length(right)-2)
        left_val = (left in vars) ? vars[left] : ""
        return (left_val == right)
    }
    if (index(cond, "!=") > 0) {
        split(cond, parts, "!=")
        left = trim(parts[1])
        right = trim(parts[2])
        if (right ~ /^".*"$/ || right ~ /^'.*'$/) right = substr(right, 2, length(right)-2)
        left_val = (left in vars) ? vars[left] : ""
        return (left_val != right)
    }
    return (vars[cond] != "" && vars[cond] != "0")
}

function handle_directive(cmd,   parts, cond, var_name, val_str, values, matched_any, i, cond_result) {
    cmd = trim(cmd)
    # if 指令
    if (cmd ~ /^if /) {
        cond = substr(cmd, 4)
        cond_result = eval_condition(cond)
        # 保存进入 if 前的 output_enabled 和当前条件结果
        if_stack[if_depth] = output_enabled
        cond_stack[if_depth] = cond_result
        if_depth++
        # 新的输出状态 = 原状态 AND 条件
        output_enabled = output_enabled && cond_result
        return
    }
    if (cmd == "else") {
        if (if_depth > 0) {
            # 恢复进入 if 前的 output_enabled
            orig = if_stack[if_depth-1]
            # 条件结果取反
            output_enabled = orig && (!cond_stack[if_depth-1])
        } else {
            print "Error: unmatched #{{else}}" > "/dev/stderr"
        }
        return
    }
    if (cmd == "fi") {
        if (if_depth > 0) {
            if_depth--
            output_enabled = if_stack[if_depth]
        } else {
            print "Error: unmatched #{{fi}}" > "/dev/stderr"
        }
        return
    }

    # case 指令
    if (cmd ~ /^case /) {
        var_name = trim(substr(cmd, 6))
        case_stack[case_depth] = output_enabled
        case_var_stack[case_depth] = var_name
        case_matched_stack[case_depth] = 0
        case_depth++
        output_enabled = 0
        return
    }
    if (cmd ~ /^when /) {
        if (case_depth == 0) {
            print "Error: #{{when}} outside #{{case}}" > "/dev/stderr"
            return
        }
        val_str = trim(substr(cmd, 6))
        if (val_str == "else") {
            if (case_matched_stack[case_depth-1] == 0) {
                case_matched_stack[case_depth-1] = 1
                output_enabled = 1
            } else {
                output_enabled = 0
            }
            return
        }
        split_values(val_str, values)
        matched_any = 0
        var_name = case_var_stack[case_depth-1]
        for (i = 1; i <= values[0]; i++) {
            if (vars[var_name] == values[i]) {
                matched_any = 1
                break
            }
        }
        if (case_matched_stack[case_depth-1] == 0 && matched_any) {
            case_matched_stack[case_depth-1] = 1
            output_enabled = 1
        } else {
            output_enabled = 0
        }
        return
    }
    if (cmd == "endcase") {
        if (case_depth > 0) {
            case_depth--
            output_enabled = case_stack[case_depth]
        } else {
            print "Error: unmatched #{{endcase}}" > "/dev/stderr"
        }
        return
    }

    # define 指令（可选）
    if (cmd ~ /^define /) {
        parts = substr(cmd, 8)
        eq = index(parts, "=")
        if (eq > 0) {
            var_name = trim(substr(parts, 1, eq-1))
            val_str = trim(substr(parts, eq+1))
            vars[var_name] = val_str
        }
        return
    }

    print "Warning: unknown directive: #{{" cmd "}}" > "/dev/stderr"
}

{
    line = $0
    stripped = line
    gsub(/^[ \t]+|[ \t]+$/, "", stripped)
    if (stripped ~ /^#{{[^{}]+}}$/) {
        directive = substr(stripped, 4, length(stripped) - 5)
        handle_directive(directive)
        next
    }
    if (output_enabled) {
        print substitute_vars(line)
    }
}