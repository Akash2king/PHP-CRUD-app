<?php 
/* Author: Cozy👽 https://github.com/ItsCosmas */

include('connection.php');
include('functions/main.php');

$theUsers = new Main;

if (isset($_SESSION['loggedin']) && $_SESSION['loggedin'] === true) {
    header('Location: ../index.php');
    exit();
}

if ($_POST) {
    $fullName = trim($_POST['fullName'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    $confirmPassword = $_POST['confirmPassword'] ?? '';

    if (empty($fullName) || empty($email) || empty($username) || empty($password) || empty($confirmPassword)) {
        $_SESSION['signup_error'] = '<div class="alert alert-warning"><strong>All fields are required!</strong> Please try again.</div>';
        header('Location: signup.php');
        exit();
    }

    if ($password !== $confirmPassword) {
        $_SESSION['signup_error'] = '<div class="alert alert-warning"><strong>Both passwords should match!</strong> Please try again.</div>';
        header('Location: signup.php');
        exit();
    }

    if ($theUsers->fetchUser($username) >= 1) {
        $_SESSION['signup_error'] = '<div class="alert alert-warning"><strong>Username is taken.</strong> Please try another one.</div>';
        header('Location: signup.php');
        exit();
    }

    $dbPassword = md5($password);
    $query = $pdo->prepare('INSERT INTO `user` (`username`, `userEmail`, `fullName`, `password`) VALUES (?, ?, ?, ?)');
    $query->execute([$username, $email, $fullName, $dbPassword]);

    header('Location: login.php');
    exit();
}

header('Location: signup.php');
exit();
