<?php
$conn = new mysqli("localhost", "groot", "211312", "nextcloud");
if ($conn->connect_error) {
    echo "Failed: " . $conn->connect_error;
} else {
    echo "OK";
}
$conn->close();
?>
