<?php 
/* Author: Cozy👽 https://github.com/ItsCosmas */
session_start();

$dbHost = getenv('DB_HOST') ?: 'localhost';
$dbPort = getenv('DB_PORT') ?: '3306';
$dbName = getenv('DB_NAME') ?: 'crud';
$databaseUser = getenv('DB_USER') ?: 'root';
$databasePass = getenv('DB_PASSWORD') ?: '';

$databaseHost = "mysql:host={$dbHost};port={$dbPort};dbname={$dbName}";

$pdoOptions = [];
if (in_array(getenv('DB_SSL'), ['1', 'true', 'yes'], true)) {
    $pdoOptions[PDO::MYSQL_ATTR_SSL_CA] = getenv('DB_SSL_CA') ?: '/etc/ssl/certs/ca-certificates.crt';
}

try{
    $pdo = new PDO($databaseHost, $databaseUser, $databasePass, $pdoOptions);
}catch (PDOException $e){
    print "Connection ERROR!: " .$e -> getMessage(). "<br/>";
    die();
}


?>