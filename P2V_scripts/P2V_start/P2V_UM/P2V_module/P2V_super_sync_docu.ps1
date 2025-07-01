#
#
# to describe logic of super_sync 


#------- helper functions  ---
Function get_AD_user
{ # function to verify and select user  via GUI 
  # in P2V_get_user_AD_func.psm1
}
Function select_PS_tenants 
{ # funtion to select tenant via GUI  -> returns list (1..n  tenants)
  # in P2V_PS_func.psm1
}

Function P2V_get_userlist($tenant)
{ # function to retrieve P2V userlist from tenant
  # in P2V_PS_func.psm1
}

Function get_P2V_user($user)   # xkey or logonID ?
{ # function to retrieve singet_P2V_user($user)gle user data from tenant
  # NEW
}

Function get_AD_user($xkey)
{ # function to retrieve single user data from tenant
  # NEW  details including proxyaddresses
  # NEW option to include P2V_groups
  }

Function get_AD_userlist ($adgroup)
{ # function to retrieve list of xkeys for particular AD-group
  # NEW including proxyaddresses
}

Function get_user_P2V_tobe ($xkey)
{ # function to return list of workgroups derived from user <> profile assignment in AD
  # NEW
}

Function get_user_P2V_asis ($xkey, $tenant)
{ # function to return list of workgroups currently assign to  user in particular tenant
  # NEW
}

Function  ($xkey, $tenant)
{ # function to return list of workgroups currently assign to  user in particular tenant
  # NEW
}


