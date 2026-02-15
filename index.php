<?php
echo "PHP ". phpversion() . " ok\n";

$output = [];
$return_var = 0;
exec('composer --version', $output, $return_var);
if ($return_var === 0) {
    echo "" . $output[0] ."\n"; // 输出第一行，通常是版本信息
} else {
    echo "Failed to get Composer version.\n";
}

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
