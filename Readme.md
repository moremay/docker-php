# Docker Images for PHP

## PHP-FPM

Thank [docker-library/php](https://github.com/docker-library/php) [Alpine](https://pkgs.alpinelinux.org/)

Build images for php-fpm.

+ php
  + php 5.4.45
  + php 5.6.40
  + php 7.4.33
  + php 8.4.17 2026-01-15
  + php 8.5.2 2026-01-15
+ ext. :
  + add shared :
  bcmath, bz2, exif, gd, gettext, gmp, mcrypt, mysql, mysqli, opcache, openssl, pdo_mysql, pdo_pgsql, pgsql, redis, sockets, sodium, timezonedb, xsl, zip
  + iconv &nbsp;&nbsp;&nbsp;&nbsp; gnu libiconv 1.18
  + mcrypt &nbsp;&nbsp; php 5. php 7, 8: Alternatives: Sodium/OpenSSL
  + mysql &nbsp;&nbsp;&nbsp;&nbsp; php 5. php 7, 8: Alternatives: mysqli
  + odbc &nbsp;&nbsp;&nbsp;&nbsp; php 7, 8: unixODBC
  + openssl &nbsp; php 5: openssl 1.0.2u (curl uses wolfssl 5.8.4); php 7.4: openssl 1.1.1w (curl uses wolfssl 5.8.4); php 8: openssl 3.5.5
  + sodium &nbsp;&nbsp; php 7, 8
+ composer
  php 5: 2.2.25; php 7.4, 8: latest 2.9.4
+ phpcs

```shell
build.sh [[-v|--ver ]ver-dir-name] [-p] [--ali]
  --ali           for os mirrors. Set args: mirrors=mirrors.aliyun.com gnu_mirrors=https://mirrors.aliyun.com/gnu
  -p              push
  -v, --ver VER[-PLAT]  dirname.
                  If Dockerfile is in the current directory, can omit it.
                  If it is the first argument, the switch symbol can be omitted.
```

## PHPCompatibility

[PHPCompatibility ![PHPCompatibility Current Version](https://poser.pugx.org/phpcompatibility/php-compatibility/v)](https://github.com/PHPCompatibility/PHPCompatibility)
[PHP CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) installed coding standards

`phpcs/phpcs.sh`使用目标目录或文件所在目录的 phpcs.xml，如果没有则使用phpcs目录的默认 phpcs.xml。默认 phpcs.xml 测试与php8.4的兼容性（忽略了mcrypt）。

命令行参数将覆盖 phpcs.xml 的设置。

```bash
cd phpcs
./phpcs.sh --usage
./phpcs.sh [-v|--volume list] [-p .]|<-p path/to/php-dir-or-file> [PHP CodeSniffer options]
```

或

```bash
docker run --rm -it -v .:/www/ moremay/php:cs
```

## Extensions

需要其它库、需要编译时开启或需要注意的扩展：

|PHP ext|Libs|configure|
|---|---|---|
|bcmatch||--enable-bcmath|
|bz2|bzip2-dev -*or*- libbz2-dev|--with-bz2|
|calendar||--enable-calendar|
|curl [[1]](#n_1) [[4]](#n_4)|curl *libcurl3-gnutls [[5]](#n_5)*<BR />curl-dev -*or*- libcurl4-openssl-dev|--with-curl[=DIR]|
|dba|[detail](https://www.php.net/manual/en/dba.requirements.php)|[detail](https://www.php.net/manual/zh/dba.installation.php)|
|dom|[libxml](#libxml)||
|enchant|*Enchant + Glib*|--with-enchant[=dir]|
||libenchant.dll glib-2.dll gmodule-2.dll||
|exif||--enable-exif|
||**after** mbstring|php_mbstring.dll<BR />...<BR />php_exif.dll|
|fileinfo||php_fileinfo.dll|
|ftp [[1]](#n_1)||--enable-ftp|
|gd||--with-gd[=DIR]|
|gd:avif|libavif-dev|**>=8.1**--with-avif[=DIR]|
|gd:freetype|freetype-dev *-or-* libfreetype-dev|**<7.4** --with-freetype-dir[=DIR]<BR />**>=7.4** --with-freetype[=DIR]<BR />---<BR />**<7.2** *string function* [--enable-gd-native-ttf]<BR />*Type 1 fonts* [--with-t1lib[=DIR]]<BR />---<BR />~~JIS-mapped Japanese font~~ [--enable-gd-jis-conv]|
|gd:jpeg|libjpeg*62*-turbo-dev -*or*- libjpeg-dev|**<7.4** --with-jpeg-dir[=DIR]<BR />**>=7.4** --with-jpeg[=DIR]|
|gd:png|zlib libpng-dev|**<7.4** [--with-zlib-dir[=DIR]] --with-png-dir[=DIR]<BR />**>=7.4** 存在 libpng 和 zlib 即可|
|gd:webp|libvpx-dev (>=7)libwebp-dev|**<7** --with-vpx-dir[=DIR]<BR />**>=7** --with-webp-dir[=DIR]<BR />**>=7.4** --with-webp[=DIR]|
|gd:xpm|libxpm-dev|**<7.4** --with-xpm-dir[=DIR]<BR />**>=7.4** --with-xpm[=DIR]|
|gettext|gettext-dev*|--with-gettext[=DIR]|
|gmp|gmp-dev -*or*- libgmp-dev|--with-gmp|
|iconv [[3]](#n_3)|*gnu-libiconv-dev [[5]](#n_5)*|--with-iconv=DIR|
|imap [[4]](#n_4)|[detail](https://www.php.net/manual/zh/imap.requirements.php)|--with-imap[=DIR] [--with-imap-ssl[=DIR] \| --with-kerberos[=DIR]]|
|intl|icu-dev|--enable-intl|
|ldap [[4]](#n_4)|*OpenLDAP*|--with-ldap[=DIR] [--with-ldap-sasl[=DIR]]|
|<a id="libxml">libxml</a> [[3]](#n_3)|libxml2-dev|--with-libxml-dir=DIR|
|mbstring [[1]](#n_1)|*libmbfl [[5]](#n_5)*|--enable-mbstring<BR />**<7.3** 可指定 libmbfl: --with-libmbfl[=DIR]|
||多字节 oniguruma-dev *-or-* libonig-dev|**<7.4** 可指定 onig: --with-onig[=DIR]|
|mcrypt|libmcrypt-dev *libltdl-dev*|**>=7.2** 移至 PECL 库。使用 Sodium/OpenSSL|
|mysql|see myqli|**5.5 废弃, 7.0 移除**<BR />--with-mysql[=DIR]|
|mysqli [[6]](#n_6)|[mysqlnd](#mysqlnd) -*or*- libmysqlclient-dev -*or*- libmariadbclient-dev-compat|--with-mysqli[=DIR]<BR />*对于 mysqlnd，5.3必须使用=mysqlnd，高版本是默认值。*|
|<a id="mysqlnd">mysqlnd</a> [[1]](#n_1)|**>=5.3** 开始支持|--enable-mysqlnd|
|oci8|[detail](https://www.php.net/manual/zh/oci8.requirements.php) [oracle](https://www.oracle.com/database/technologies/instant-client.html)|[detail](https://www.php.net/manual/zh/oci8.installation.php)|
|odbc||[detail](https://www.php.net/manual/zh/odbc.installation.php)|
|openssl [[1]](#n_1)|openssl-dev|--with-openssl[=DIR]<BR />**5.3** <1.1<BR />**7.0** >=0.9.8<BR />**7.1~8.0** [1.0.1, 3.0)<BR />**8.1** [1.0.2, 4.0)|
|pcntl [[2]](#n_2) [[7]](#n_7)||--enable-pcntl|
|pcre [[3]](#n_3)||--with-pcre-regex=DIR<BR />**>=7.0.12** [--without-pcre-jit]|
|pdo||php_pdo.dll*必须先于具体数据库加载。*|
|pdo_dblib|MSSQL & Sybase|移至 PECL 库|
|pdo_firebird|Firebird / InterBase|--with-pdo-firebird[=DIR]<BR />**7.4** 移至 PECL 库|
|pdo_mysql|see mysqli|--with-pdo-mysql[=DIR]|
|pdo_oci|[detail](https://www.php.net/manual/zh/oci8.requirements.php) Oracle|--with-pdo-oci=instantclient,prefix,version \|<BR />--with-pdo-oci[=DIR] *default: $ORACLE_HOME*<BR />PECL 也包含。|
|pdo_odbc|[detail](https://www.php.net/manual/zh/ref.pdo-odbc.php)||
|pdo_pgsql|PostgreSQL|--with-pdo-pgsql[=DIR]|
|pdo_sqlite [[3]](#n_3)|libsqlite|--with-pdo-sqlite=DIR|
|pgsql|PostgreSQL|--with-pgsql[=DIR]|
|phar|zlib bzip2 openssl||
|posix||不支持 Windows|
|pspell|aspell|--with-pspell[=dir]|
||aspell-15.dll|aspell >= 0.5|
|readline [[1]](#n_1) [[8]](#n_8)|readline-dev *-or-* libreadline-dev|--with-readline[=DIR]|
||libedit-dev|--with-libedit[=DIR]|
|recode|[detail](https://github.com/rrthomas/recode/)|--with-recode[=DIR]<BR />**7.4** 移至 PECL 库|
|shmop [[2]](#n_2)||--enable-shmop|
|simplexml|[libxml](#libxml)||
|snmp|Net-SNMP||
|soap|[libxml](#libxml)|--enable-soap|
|sockets||--enable-sockets|
|sodium|libsodium|**>=7.2**|
|sqlite3|libsqlite||
|sysvmsg [[2]](#n_2)||--enable-sysvmsg|
|sysvsem [[2]](#n_2)||--enable-sysvsem|
|sysvshm [[2]](#n_2)||--enable-sysvshm|
|tidy|tidyhtml-dev *-or-* libtidy-dev *-or-* libtidy5-dev *-or-* libtidyp-dev|--with-tidy|
|wddx|[libxml](#libxml) expat|--enable-wddx [--with-libexpat-dir]<BR />**7.4** 移至 PECL 库|
|xml|[libxml](#libxml)||
|xmlreader|[libxml](#libxml)||
|xmlrpc|[libxml](#libxml)|--with-xmlrpc[=DIR]|
|xmlwriter|[libxml](#libxml)||
|xsl|[libxml](#libxml) libxslt-dev *libxslt1-dev*|--with-xsl[=DIR]|
|zip|libzip|**<7.4** --enable-zip<BR />**7.4** --with-zip [--with-libzip=DIR]<BR />所有版本可用 PECL|
|zlib [[1]](#n_1)|zlib-dev *-or-* zlib*1g*-dev|--with-zlib[=DIR]|

1. <a id="n_1"> </a>需要/推荐与 PHP 一起编译。
2. <a id="n_2"> </a>一般不推荐用于 Web。
3. <a id="n_3"> </a>PHP 编译时默认激活，但可以配置所需库的路径。
4. <a id="n_4"> </a>Windows 需要 OpenSSL：libeay32.dll libssh2.dll ssleay32.dll。如果是 OpenSSL 1.1 及以上需要： libcrypto-\*.dll libssl-\*.dll。
5. <a id="n_5"> </a>系统中可能已经存在(相似)库。
6. <a id="n_6"> </a>MySQL 8 需要设置 my.cnf: `default_authentication_plugin=mysql_native_password`。
7. <a id="n_7"> </a>pcntl 建议只用于 CLI。仅 Unix 支持。
8. <a id="n_8"> </a>readline 用于 CGI / CLI。Windows 从 PHP 7.1 开始默认启用。
