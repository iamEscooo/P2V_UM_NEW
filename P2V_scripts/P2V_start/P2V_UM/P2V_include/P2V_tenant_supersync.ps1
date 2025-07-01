# all tenant supersync
#
#
#


$selected_tenants = select_PS_tenants

foreach ($ten in $selected_tenants)
{
	
	
	$P2V_userlist= P2V_get_userlist($ten)   #incl. workgroups
	
	
	$user.ADgroups=get_AD_P2V_groups ($xkey)
	$user.P2V_tobe=get_user_P2V_tobe ($xkey)
    $user.P2V_tobe=apply_P2V_rulesets ($user.P2V_tobe) 
	
	compare_permissions ($as_is, $user.P2V_tobe)
	
	
	apply_bulk_changes ($ten,select_changes (compare_permissions ($as_is, $user.P2V_tobe)))
	 
	 
	apply_bulk_changes ($ten,select_changes ( $user.metadata) )
	 
	 
    print_result	 
		
	
}