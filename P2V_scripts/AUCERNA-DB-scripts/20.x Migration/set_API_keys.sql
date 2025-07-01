-- This script created for new nodes
-- MKR

--  0 ... readonly    1 ... write changes 
Declare @readonly  bit = 0

-- select DB (if needed)
-- USE [P2V_T_PS20_TEST1];
-- GO

   select [LoginID],[ApiKey] 
   from [COMMON].[User]
   where LoginID in ('svc.ww.at.p2v_useradmin@ww.omv.com', 'Pascale.Neff@omv.com','s.at.p2vpbi1','s.at.p2vpbi2','s.at.p2vpbi3','s.at.p2vpbi4','s.at.p2vpbi5','s.at.p2vpbi6','s.at.p2vpbi7','s.at.p2vpbi8','s.at.p2vpbi9',
   's.at.p2vpbi10','s.at.p2vpbi11','s.at.p2vpbi12','s.at.p2vpbi13','s.at.p2vpbi14','s.at.p2vpbi15','PBI.corporate','PBI.corporate.BD' ,'Danut.Domnitanu@petrom.com')

-- If (@readonly = 1)
-- begin
   print 'changing APIKEY'

  
   -- update [COMMON].[User]
   -- set ApiKey = 'H01:1000:0sJd9ZE6Qv8b3496jT8FO7nhylEQWR+m:xOfcKty2k7Q6pEUsRyZ54tcu/3qlyTlQ'
   -- where LoginID = 'svc.ww.at.p2v_useradmin@ww.omv.com'
   -- 1

   update [COMMON].[User]
   -- set ApiKey = 'H02:AQAAAAEAACcQAAAAEE8NqZPRtQGwDM31peP8MV2VaAFHKtRsiKDasB3p5cjLw2bkpFBl9l4PiIZ+bHC4gA=='
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEMxqz6ZWnSWqIfehWQxi7udJHS+DZsi3eHHf4ZoTno7m4OD0179x73hXlXj5VMWU2g==' 
   where LoginID = 'svc.ww.at.p2v_useradmin@ww.omv.com'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEC3Gi76BJvLMgr91O7JS1EPi5dmnFgGlVpeRYxS+KtvonXBUcDwyBNEBAUR1JQEp2A=='
   where LoginID = 'Pascale.Neff@omv.com'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEMkSWRsatY320bTbk35+3usZPC8deHs3LkwRLIeq6JAAi46XCOzCjB9TgkFJesr8Vw=='
   where LoginID  = 's.at.p2vpbi1'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEDm67qu+NmYPPyLJ/sB+xbZk/50RyNPs5BBWx48HRrN1AKObKTF/iCfWwXKs/45fjw=='
   where LoginID = 's.at.p2vpbi2'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEHdRc/4JUQqyylkxwZwVJAZ39kJuNjls9Jg6WY7FDljxXIx6mNS8AAhcbrPZiVNTDg=='
   where LoginID = 's.at.p2vpbi3'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEHiJMs9ylnFWSItguGkfKSSkVB8br4lfy0LTiQnLRIDzZn+Y0WExhhjM91DRmTTQFQ=='
   where LoginID = 's.at.p2vpbi4'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAENpZqla0M6SOejFLTUjVToB/s9RG3HPxNX4EzX16x4z6M9U6CmPFzuK+/GW218UOXw=='
   where LoginID = 's.at.p2vpbi5'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEHsVo63cEMTAL+wrK6k37RdfVlYtcQridFkB3b6tGk75FdY+Ad91ga4ONzwTcoaSaw=='
   where LoginID = 's.at.p2vpbi6'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEB3LIGO4FgajYV4bY0XPdwglHbjdEXxHYemVnkdnsCPlhQBQvc/uXzGMhV2rtYzfoQ=='
   where LoginID = 's.at.p2vpbi7'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEK//7wZUbtG8vhAequg6ODu4+82yHmmePwG8HQUpB0w/shGVBIvpQN9tjYwEvVsw2w=='
   where LoginID = 's.at.p2vpbi8'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEN2ngxSdy5glSJZLpzXhURA7I+busWkpMyi99gGUmtX+TiJVx+hBlca+bqMgPN8dZw=='
   where LoginID = 's.at.p2vpbi9'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAECXXYPtDXqvsnD2R6n6BE/dnML1myvObJBTnsljYlD9A8oKr/1FvIoJ0QcMImAP2GA=='
   where LoginID = 's.at.p2vpbi10'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEBHmofTcLiqOIAQ7AukGZ/KiRa+rTbnipyGr5dZiJrhRxzmSljk5fNspOUxau5+5Nw=='
   where LoginID = 's.at.p2vpbi11'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEOVCKfa/nui6cm+MKQ/DhrMiPHCw/jZXWL4Zvyo+tewKIVacrW4rSCPiBVTOpEsY9Q=='
   where LoginID = 's.at.p2vpbi12'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEJtG3u4o+KcYHsEg9h2gcM3VJV7Ac/sYNy61sHmKg5GdlqrcFvSvI6SIHQCxFfXWzA=='
   where LoginID = 's.at.p2vpbi13'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEFpm2Ihol/nIMJDTDODgh3kmliMDlChbmkGrIagFiyR9x2V2M5J3LtUKOvUT2OMzYQ=='
   where LoginID = 's.at.p2vpbi14'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEMUxBIWmmqcshoaFRkfPL8mCn3sp/Pb4p1Dv7Wr78APyfYcuTcFkCqEfhbGH8PPVZQ=='
   where LoginID = 's.at.p2vpbi15'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEO40HVURmuvw6IOZNqAs7vPJp7Tr22kEjDjtj0dqmekzQYkdqwZR/a0+bJ6Bc17rRA=='
   where LoginID = 'PBI.corporate'

   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAEAACcQAAAAEKyxJMuAgVqzpDtEppBI5uV9DTLfXqXFBjB0uzgm8cf6v3qQDu8rdtlWVHsJXAmIlw=='
   where LoginID = 'PBI.corporate.BD'


   update [COMMON].[User]
   set ApiKey = 'H02:AQAAAAIAAYagAAAAEBZ/TnhaRGGpLJYELLMXq/enNqqTb/rJ2d+guxiHMHCJ3YVjOb7h8+uT+pLT31TYKA=='
   where LoginID = 'Danut.Domnitanu@petrom.com'

--   update [COMMON].[User]
--   set ApiKey = ''
--   where LoginID = ''



   select [LoginID],[ApiKey] 
   from [COMMON].[User]
   where LoginID in ('svc.ww.at.p2v_useradmin@ww.omv.com', 'Pascale.Neff@omv.com','s.at.p2vpbi1','s.at.p2vpbi2','s.at.p2vpbi3','s.at.p2vpbi4','s.at.p2vpbi5','s.at.p2vpbi6','s.at.p2vpbi7','s.at.p2vpbi8','s.at.p2vpbi9',
   's.at.p2vpbi10','s.at.p2vpbi11','s.at.p2vpbi12','s.at.p2vpbi13','s.at.p2vpbi14','s.at.p2vpbi15','PBI.corporate','PBI.corporate.BD','Danut.Domnitanu@petrom.com' )
-- end