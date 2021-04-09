<?php
/*
* Database Constants
* Make sure you are putting the values according to your database here 
*/
define('DB_HOST','203.154.91.122:8306'); //127.0.0.1
define('DB_USERNAME','bsrd');
define('DB_PASSWORD','bsrd@helios');
define('DB_NAME', 'userdata');
//Connecting to the database
$conn = new mysqli(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_NAME);
//checking the successful connection
if($conn->connect_error) {
die("Connection failed: " . $conn->connect_error);
}
//making an array to store the response
$response = array(); 
//if there is a post request move ahead 
if($_SERVER["REQUEST_METHOD"] == "POST") {
$_POST = json_decode(file_get_contents('php://input'), true);
if(!empty($_POST)) {
$name = $_POST['name']; 
$status = $_POST['status']; 
}else{
$name = 'empty';
$status = 0;
}
//getting the name from request 
//creating a statement to insert to database 
$stmt = $conn->prepare("INSERT INTO users (name,status) VALUES (?, ?)");
//binding the parameter to statement 
$stmt->bind_param("si", $name, $status);
// if data inserts successfully
if($stmt->execute()){
//making success response 
$response['error'] = false; 
$response['message'] = 'Name saved successfully'; 
}else{
//if not making failure response 
$response['error'] = true; 
$response['message'] = 'Please try later';
}
}else{
$response['error'] = true; 
$response['message'] = "Invalid request"; 
}
//displaying the data in json format 
echo json_encode($response);