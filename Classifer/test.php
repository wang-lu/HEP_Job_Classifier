<?php 
$pattern=$_GET["pattern"];
#echo $pattern;
system("/usr/local/bin/th /home/wanglu/jobana/final/label.lua -save /home/wanglu/jobana/final/mmlp -pattern $pattern");
#echo "system(/usr/local/bin/th /home/wanglu/jobana/final/label.lua -save mmlp -pattern $pattern)";
#system("hostname"); 
?> 
