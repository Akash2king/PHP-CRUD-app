<?php 
	/* Author: Cozy👽 https://github.com/ItsCosmas */


	include ('connection.php');
    include ('functions/main.php');
    

	if (!isset($_SESSION['loggedin']) || $_SESSION['loggedin'] !== true) {
		header('Location: login.php');
		exit();
	}

 	if($_POST){
		$noteTitle = $_POST['noteTitle'];
        $noteContent = $_POST['noteContent'];
        
        

 		if(empty($noteTitle) or empty($noteContent)){
			$errors = '<div class="alert alert-warning"><strong> All fields are required! </strong> Please try again 😒</div>';
		}else{
				 	
			$query = $pdo->prepare('INSERT INTO `notes` (`noteTitle`, `noteContent`) VALUES (?, ?)');
			$query->execute([$noteTitle, $noteContent]);
		    header('Location: ../index.php');
		    exit();
		}
	}

?>