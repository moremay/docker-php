# Docker Images for PHP

## PHP-FPM

Thank [docker-library/php](https://github.com/docker-library/php)

Build images for php-fpm.

+ ext. :
  + add shared :
  bcmath, bz2, exif, gd, gettext, gmp, mcrypt, mysql, mysqli, opcache, openssl, pdo_mysql, redis, sockets, sodium, timezonedb, xsl, zip
  + iconv &nbsp;&nbsp;&nbsp;&nbsp; php 5: gnu libiconv 1.15; php 7, 8: gnu libiconv 1.17
  + mcrypt &nbsp;&nbsp; php 5. php 7, 8: Alternatives: Sodium/OpenSSL
  + mysql &nbsp;&nbsp;&nbsp;&nbsp; php 5. php 7, 8: Alternatives: mysqli
  + openssl &nbsp; php 5: openssl 1.0.2u; php 7.4: openssl 1.1.1u; php 8.2: openssl 3.1.0
  + sodium &nbsp;&nbsp; php 7, 8
+ composer
  php 5: 2.2.21; php 7.4, 8.2: 2.5.7

## PHPCompatibility

[PHPCompatibility ![PHPCompatibility Current Version](https://poser.pugx.org/phpcompatibility/php-compatibility/v)](https://github.com/PHPCompatibility/PHPCompatibility)

    curl -O https://raw.githubusercontent.com/moremay/docker-php/master/phpcs
    chmod u+x phpcs
    ./phpcs --usage
    ./phpcs [--volume list] [-p .]|<-p path/to/php/files> [--standard PHPCompatibility[,...]] [--version ver_min[-[ver_max]]] [PHP CodeSniffer options]

[PHP CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) installed coding standards

    ./phpcs -i

## Extensions

需要其它库、需要编译时开启或需要注意的扩展：

|PHP ext|Libs|configure|
|---|---|---|
|bcmatch||--enable-bcmath|
|bz2|bzip2-dev -*or*- libbz2-dev|--with-bz2|
|calendar||--enable-calendar|
|curl [<sup>[1]</sup>](#n_1) [<sup>[4]</sup>](#n_4)|curl *libcurl3-gnutls [<sup>[5]</sup>](#n_5)*<BR />curl-dev -*or*- libcurl4-openssl-dev|--with-curl[=DIR]|
|dba|[detail](https://www.php.net/manual/en/dba.requirements.php)|[detail](https://www.php.net/manual/zh/dba.installation.php)
|dom|[libxml](#libxml)|
|enchant|*Enchant + Glib*|--with-enchant[=dir]|
||libenchant.dll glib-2.dll gmodule-2.dll|
|exif||--enable-exif|
||**after** mbstring|php_mbstring.dll<BR />...<BR />php_exif.dll|
|fileinfo||php_fileinfo.dll|
|ftp [<sup>[1]</sup>](#n_1)||--enable-ftp|
|gd| |--with-gd[=DIR]|
|gd:avif|libavif-dev|**>=8.1**--with-avif[=DIR]|
|gd:freetype|freetype-dev *-or-* libfreetype-dev|**<7.4** --with-freetype-dir[=DIR]<BR />**>=7.4** --with-freetype[=DIR]<BR />---<BR />**<7.2** *string function* [--enable-gd-native-ttf]<BR />*Type 1 fonts* [--with-t1lib[=DIR]]<BR />---<BR /><del>JIS-mapped Japanese font</del> [--enable-gd-jis-conv]|
|gd:jpeg|libjpeg*62*-turbo-dev -*or*- libjpeg-dev|**<7.4** --with-jpeg-dir[=DIR]<BR />**>=7.4** --with-jpeg[=DIR]|
|gd:png|zlib libpng-dev|**<7.4** [--with-zlib-dir[=DIR]] --with-png-dir[=DIR]<BR />**>=7.4** 存在 libpng 和 zlib 即可|
|gd:webp|libvpx-dev (>=7)libwebp-dev|**<7** --with-vpx-dir[=DIR]<BR />**>=7** --with-webp-dir[=DIR]<BR />**>=7.4** --with-webp[=DIR]|
|gd:xpm|libxpm-dev|**<7.4** --with-xpm-dir[=DIR]<BR />**>=7.4** --with-xpm[=DIR]|
|gettext|gettext-dev*|--with-gettext[=DIR]|
|gmp|gmp-dev -*or*- libgmp-dev|--with-gmp|
|iconv [<sup>[3]</sup>](#n_3)|*gnu-libiconv-dev [<sup>[5]</sup>](#n_5)*|--with-iconv=DIR|
|imap [<sup>[4]</sup>](#n_4)|[detail](https://www.php.net/manual/zh/imap.requirements.php)|--with-imap[=DIR] [--with-imap-ssl[=DIR] \| --with-kerberos[=DIR]]|
|intl|icu-dev|--enable-intl|
|ldap [<sup>[4]</sup>](#n_4)|*OpenLDAP*|--with-ldap[=DIR] [--with-ldap-sasl[=DIR]]|
|<span id="libxml">libxml</span> [<sup>[3]</sup>](#n_3)|libxml2-dev|--with-libxml-dir=DIR|
|mbstring [<sup>[1]</sup>](#n_1)|*libmbfl [<sup>[5]</sup>](#n_5)*|--enable-mbstring<BR />**<7.3** 可指定 libmbfl: --with-libmbfl[=DIR]|
||多字节 oniguruma-dev *-or-* libonig-dev|**<7.4** 可指定 onig: --with-onig[=DIR]|
|mcrypt|libmcrypt-dev *libltdl-dev*|**>=7.2** 移至 PECL 库。使用 Sodium/OpenSSL|
|mysql|see myqli|**5.5 废弃, 7.0 移除**<BR />--with-mysql[=DIR]|
|mysqli [<sup>[6]</sup>](#n_6)|[mysqlnd](#mysqlnd) -*or*- libmysqlclient-dev -*or*- libmariadbclient-dev-compat|--with-mysqli[=DIR]<BR />*对于 mysqlnd，5.3必须使用=mysqlnd，高版本是默认值。*|
|<span id="mysqlnd">mysqlnd</span> [<sup>[1]</sup>](#n_1)|**>=5.3** 开始支持|--enable-mysqlnd|
|oci8|[detail](https://www.php.net/manual/zh/oci8.requirements.php) [oracle](https://www.oracle.com/database/technologies/instant-client.html)|[detail](https://www.php.net/manual/zh/oci8.installation.php)|
|odbc||[detail](https://www.php.net/manual/zh/odbc.installation.php)|
|openssl [<sup>[1]</sup>](#n_1)|openssl-dev|--with-openssl[=DIR]<BR />**5.3** <1.1<BR />**7.0** >=0.9.8<BR />**7.1~8.0** [1.0.1, 3.0)<BR />**8.1** [1.0.2, 4.0)|
|pcntl [<sup>[2]</sup>](#n_2) [<sup>[7]</sup>](#n_7)||--enable-pcntl|
|pcre [<sup>[3]</sup>](#n_3)||--with-pcre-regex=DIR<BR />**>=7.0.12** [--without-pcre-jit]|
|pdo||php_pdo.dll*必须先于具体数据库加载。*|
|pdo_dblib|MSSQL & Sybase|移至 PECL 库|
|pdo_firebird|Firebird / InterBase|--with-pdo-firebird[=DIR]<BR />**7.4** 移至 PECL 库|
|pdo_mysql|see mysqli|--with-pdo-mysql[=DIR]|
|pdo_oci|[detail](https://www.php.net/manual/zh/oci8.requirements.php) Oracle|--with-pdo-oci=instantclient,prefix,version \|<BR />--with-pdo-oci[=DIR] *default: $ORACLE_HOME*<BR />PECL 也包含。|
|pdo_odbc|[detail](https://www.php.net/manual/zh/ref.pdo-odbc.php)||
|pdo_pgsql|PostgreSQL|--with-pdo-pgsql[=DIR]|
|pdo_sqlite [<sup>[3]</sup>](#n_3)|libsqlite|--with-pdo-sqlite=DIR|
|pgsql|PostgreSQL|--with-pgsql[=DIR]|
|phar|zlib bzip2 openssl||
|posix||不支持 Windows|
|pspell|aspell|--with-pspell[=dir]|
||aspell-15.dll|aspell >= 0.5|
|readline [<sup>[1]</sup>](#n_1) [<sup>[8]</sup>](#n_8)|readline-dev *-or-* libreadline-dev|--with-readline[=DIR]|
||libedit-dev|--with-libedit[=DIR]|
|recode|[detail](https://github.com/rrthomas/recode/)|--with-recode[=DIR]<BR />**7.4** 移至 PECL 库|
|shmop [<sup>[2]</sup>](#n_2)||--enable-shmop|
|simplexml|[libxml](#libxml)|
|snmp|Net-SNMP||
|soap|[libxml](#libxml)|--enable-soap|
|sockets||--enable-sockets|
|sodium|libsodium|**>=7.2**|
|sqlite3|libsqlite||
|sysvmsg [<sup>[2]</sup>](#n_2)||--enable-sysvmsg|
|sysvsem [<sup>[2]</sup>](#n_2)||--enable-sysvsem|
|sysvshm [<sup>[2]</sup>](#n_2)||--enable-sysvshm|
|tidy|tidyhtml-dev *-or-* libtidy-dev *-or-* libtidy5-dev *-or-* libtidyp-dev|--with-tidy|
|wddx|[libxml](#libxml) expat|--enable-wddx [--with-libexpat-dir]<BR />**7.4** 移至 PECL 库|
|xml|[libxml](#libxml)||
|xmlreader|[libxml](#libxml)||
|xmlrpc|[libxml](#libxml)|--with-xmlrpc[=DIR]|
|xmlwriter|[libxml](#libxml)||
|xsl|[libxml](#libxml) libxslt-dev *libxslt1-dev*|--with-xsl[=DIR]|
|zip|libzip|**<7.4** --enable-zip<BR />**7.4** --with-zip [--with-libzip=DIR]<BR />所有版本可用 PECL|
|zlib [<sup>[1]</sup>](#n_1)|zlib-dev *-or-* zlib*1g*-dev|--with-zlib[=DIR]|

1. <SPAN id="n_1"> </SPAN>需要/推荐与 PHP 一起编译。
2. <SPAN id="n_2"> </SPAN>一般不推荐用于 Web。
3. <SPAN id="n_3"> </SPAN>PHP 编译时默认激活，但可以配置所需库的路径。
4. <SPAN id="n_4"> </SPAN>Windows 需要 OpenSSL：libeay32.dll libssh2.dll ssleay32.dll。如果是 OpenSSL 1.1 及以上需要： libcrypto-\*.dll libssl-\*.dll。
5. <SPAN id="n_5"> </SPAN>系统中可能已经存在(相似)库。
6. <SPAN id="n_6"> </SPAN>MySQL 8 需要设置 my.cnf: `default_authentication_plugin=mysql_native_password`。
7. <SPAN id="n_7"> </SPAN>pcntl 建议只用于 CLI。仅 Unix 支持。
8. <SPAN id="n_8"> </SPAN>readline 用于 CGI / CLI。Windows 从 PHP 7.1 开始默认启用。
