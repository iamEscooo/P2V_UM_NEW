 do
   {
   $ans=read-host -prompt "Continue (y/n)"
   } until ($ans -in "y","n")

write-host ">$ans<"