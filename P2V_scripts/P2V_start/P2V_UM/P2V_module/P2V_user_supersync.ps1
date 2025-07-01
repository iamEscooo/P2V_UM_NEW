# single user supersync
#
#
#


$xkey=get_AD_user

# select specific user
$user.ADgroups=get_AD_P2V_groups ($xkey)

# get all P2V related AD group memebership
# translate profile group to set of groups

$user.P2V_tobe=get_user_P2V_tobe ($xkey)
$user.P2V_tobe=apply_P2V_rulesets ($user.P2V_tobe)

$selected_tenants = select_PS_tenants

foreach ($ten in $selected_tenants)
{
	 as_is=Get_P2V_user($user.logonID);
	 
	 
	 compare_permissions ($as_is, $user.P2V_tobe)
	 
	 
	 apply_bulk_changes ($ten,select_changes (compare_permissions ($as_is, $user.P2V_tobe)))
	 
	 
	 apply_bulk_changes ($ten,select_changes ( $user.metadata) )
	 
	 
     print_result	 
	
}

