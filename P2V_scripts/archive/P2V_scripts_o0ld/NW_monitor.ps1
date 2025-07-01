
$servers=@("somvae501603","SOMVAT002002","Somviq001601","somvly501602","SOMVNO501605","SOMVNZ001602","somvpk001401","SOMVTN001601","spetkz502601","SPETRO201601")

foreach ($s in $servers  ) 
{
   $result = Test-NetConnection -computername $s -traceroute 
   
$result |format-table
   }











