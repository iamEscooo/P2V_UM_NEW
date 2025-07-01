-- This script resets lastlogin for all users in TENANT
-- intended for "resetting" a tenant after cloning
-- 
Update  COMMON.[User]
set     LastLogin = NULL