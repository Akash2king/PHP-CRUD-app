<?php
/* Author: Cozy https://github.com/ItsCosmas */

include_once('connection.php');

if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
    header('Location: login.php');
    exit();
}

if (isset($_GET['noteID'])) {
    $noteID = $_GET['noteID'];
    $query = $pdo->prepare('DELETE FROM `notes` WHERE `noteID` = ?');
    $query->execute([$noteID]);
}

header('Location: ../index.php');
exit();
