
#layout
$linesep="+-------------------------------------------------------------------------------+"
$form1=  "|  {0,-71}      |"
$form2=  "|  {0,-10} {1,-60}      |"
$form2_1="|  {0,-35} {1,35}      |"
$form3=  "|  {0,-10} {1,-50} {2,-10}     |"
#         0         1         2         3         4         5         6         7         8
$linesep
$form2_1 -f "[$($MyInvocation.MyCommand.Name)]",(get-date -format "dd/MM/yyyy HH:mm:ss") 


$linesep
$form1 -f $MyInvocation.MyCommand.Name
$form2 -f "script","[$($MyInvocation.MyCommand.Name)]"
$form3 -f "Start","[$($MyInvocation.MyCommand.Name)]","STOP"
$linesep