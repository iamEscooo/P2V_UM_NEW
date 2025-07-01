# get-psdrive |where {$_.Provider -like '*File*'}|select Name, Root, displayroot
net use