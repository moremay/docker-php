<?php
/**
 * Regression probe for the PHPCompatibilityPeclMcrypt ruleset.
 *
 * This file intentionally exercises every mcrypt-related item that
 * PHPCompatibility flags as deprecated/removed. When scanned with
 * --standard=PHPCompatibilityPeclMcrypt it must produce NO mcrypt-related
 * messages (they are all excluded), proving the exclusions are complete.
 *
 * Run from the package root (vendor/phpcompatibility/php-compatibility must
 * be installed as a sibling standard):
 *   phpcs --standard=PHPCompatibilityPeclMcrypt --runtime-set testVersion 8.5 \
 *         tests/mcrypt_probe.php
 *
 * Expected result: 0 errors / 0 warnings.
 */

// ---- MCRYPT_* constants (RemovedConstants) ----
$constants = [
    MCRYPT_3DES, MCRYPT_ARCFOUR, MCRYPT_ARCFOUR_IV, MCRYPT_BLOWFISH,
    MCRYPT_CAST_128, MCRYPT_CAST_256, MCRYPT_CRYPT, MCRYPT_DECRYPT, MCRYPT_DES,
    MCRYPT_DES_COMPAT, MCRYPT_DEV_RANDOM, MCRYPT_DEV_URANDOM, MCRYPT_ENCRYPT,
    MCRYPT_ENIGMA, MCRYPT_GOST, MCRYPT_IDEA, MCRYPT_LOKI97, MCRYPT_MARS,
    MCRYPT_MODE_CBC, MCRYPT_MODE_CFB, MCRYPT_MODE_ECB, MCRYPT_MODE_NOFB,
    MCRYPT_MODE_OFB, MCRYPT_MODE_STREAM, MCRYPT_PANAMA, MCRYPT_RAND, MCRYPT_RC2,
    MCRYPT_RC4, MCRYPT_RC6, MCRYPT_RC6_128, MCRYPT_RC6_192, MCRYPT_RC6_256,
    MCRYPT_RIJNDAEL_128, MCRYPT_RIJNDAEL_192, MCRYPT_RIJNDAEL_256, MCRYPT_SAFER128,
    MCRYPT_SAFER64, MCRYPT_SAFERPLUS, MCRYPT_SERPENT, MCRYPT_SERPENT_128,
    MCRYPT_SERPENT_192, MCRYPT_SERPENT_256, MCRYPT_SKIPJACK, MCRYPT_TEAN,
    MCRYPT_THREEWAY, MCRYPT_TRIPLEDES, MCRYPT_TWOFISH, MCRYPT_TWOFISH128,
    MCRYPT_TWOFISH192, MCRYPT_TWOFISH256, MCRYPT_WAKE, MCRYPT_XTEA,
];

// ---- mcrypt.* ini directives (RemovedIniDirectives) ----
ini_set('mcrypt.algorithms_dir', '/foo');
ini_set('mcrypt.modes_dir', '/bar');

// ---- mcrypt_* functions (RemovedFunctions) ----
$td = MCRYPT_DES;
mcrypt_ecb('des', 'key', 'data', MCRYPT_ENCRYPT);
mcrypt_cbc('des', 'key', 'data', MCRYPT_ENCRYPT);
mcrypt_cfb('des', 'key', 'data', MCRYPT_ENCRYPT);
mcrypt_ofb('des', 'key', 'data', MCRYPT_ENCRYPT);
mcrypt_create_iv(16, MCRYPT_DEV_URANDOM);
mcrypt_decrypt('des', 'key', 'data', MCRYPT_MODE_CBC);
mcrypt_enc_get_algorithms_name($td);
mcrypt_enc_get_block_size($td);
mcrypt_enc_get_iv_size($td);
mcrypt_enc_get_key_size($td);
mcrypt_enc_get_modes_name($td);
mcrypt_enc_get_supported_key_sizes($td);
mcrypt_enc_is_block_algorithm_mode($td);
mcrypt_enc_is_block_algorithm($td);
mcrypt_enc_is_block_mode($td);
mcrypt_enc_self_test($td);
mcrypt_encrypt('des', 'key', 'data', MCRYPT_MODE_CBC);
mcrypt_generic_deinit($td);
mcrypt_generic_init($td, 'key', 'iv');
mcrypt_generic($td, 'data');
mcrypt_get_block_size('des');
mcrypt_get_cipher_name('des');
mcrypt_get_iv_size('des');
mcrypt_get_key_size('des');
mcrypt_list_algorithms();
mcrypt_list_modes();
mcrypt_module_close($td);
mcrypt_module_get_algo_block_size('des');
mcrypt_module_get_algo_key_size('des');
mcrypt_module_get_supported_key_sizes('des');
mcrypt_module_is_block_algorithm_mode('des');
mcrypt_module_is_block_algorithm('des');
mcrypt_module_is_block_mode('des');
mcrypt_module_open('des', '', 'cbc', '');
mcrypt_module_self_test('des');
mcrypt_generic_end($td);

// Keep $constants referenced so the constant usages are "live".
return count($constants) + strlen($td);
