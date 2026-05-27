<?php  /*
    code by Cozy 👽 https://github.com/ItsCosmas
*/
include('connection.php');

if (isset($_POST['username'], $_POST['password'])) {
    $username = trim($_POST['username']);
    $password = md5($_POST['password']);

    if (empty($username) || empty($password)) {
        $error = '<div class="alert alert-warning"><strong>Warning!</strong> Enter a username and password.</div>';
    } else {
        $query = $pdo->prepare('SELECT * FROM `user` WHERE username = ? AND password = ?');
        $query->execute([$username, $password]);

        if ($query->rowCount() === 1) {
            $_SESSION['loggedin'] = true;
            $_SESSION['username'] = $username;
            header('Location: ../index.php');
            exit();
        }

        $error = '<div class="alert alert-danger"><strong>Error!</strong> Incorrect username or password.</div>';
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>CRUD</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" type="text/css" media="screen" href="../CSS/style.css" />
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
</head>
<body>
    <div class="container">
        <div class="col-lg-8 col-md-8 col-sm-12 col-xs-12 text-left pageBelowNav">
            <form method="post" action="login.php">
            <div class="form-group">
                <label for="Username">Username *</label>
                <input type="text" class="form-control" name="username" placeholder="Enter your username" required>
            </div>
            <div class="form-group">
                <label for="password">Password *</label>
                <input type="password" class="form-control" name="password" placeholder="Password" required>
            </div>
            <button type="submit" name="login" class="btn btn-primary">Log In</button>
            <div class="form-group" style="margin-top:5px;">New User? <a href="signup.php">Sign Up</a></div>
            <div style="margin-top:10px">
                <?php if (isset($error)) { echo $error; } ?>
            </div>
            </form>
        </div>
    </div>
</body>
</html>
