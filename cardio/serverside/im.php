<?php 

 $img = $_GET['img'];

 $img = sys_get_temp_dir()."/".$img;
 
 $fp = fopen($img, 'rb');
 
 // send the right headers
 header("Content-Type: image/png");
 header("Content-Length: " . filesize($img));
 
 // dump the picture and stop the script
 fpassthru($fp);
 exit;
 
?>