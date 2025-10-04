<?php
echo "main ok\n";

echo "". OPENSSL_VERSION_TEXT . "\n";

$ver_info = curl_version();
echo "curl {$ver_info['version']}\n";
echo "    protocols   : ". implode(' ', $ver_info['protocols']) . "\n";
echo "    ssl version : {$ver_info['ssl_version']}\n";

$ch = curl_init();
curl_setopt_array($ch, array(
    CURLOPT_URL => 'https://www.baidu.com/',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_NOSIGNAL => 1,
));
curl_exec($ch) && print("    check https ok\n");

echo "\n";
