<?php 

$img = $_GET['img'];
$text = base64_decode($_GET['text']);

?>
<html>
<head><title>Diagram</title></head>
<body>
<?php echo $text; ?><br>
<img src='im.php?img=<?php echo $img; ?>'>

</body>
</html>
<?php 



?>