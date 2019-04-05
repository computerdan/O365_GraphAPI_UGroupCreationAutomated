# Simplest script call example:        (will create a mail enabled Unified Group with "MyAutomatedGroup01" Displayname and "myautomatedgroup01@costo.com" email address)
#  .\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;#?ij;eroiejr23;s~!e3v' -redirectURL 'urn:ietf:wg:oauth:2.0:oob'
#                                   -GroupDisplayName "MyAutomatedGroup01"
#
# Script call example with Owners and Members:
#  .\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;#?ij;eroiejr23;s~!e3v' -redirectURL 'urn:ietf:wg:oauth:2.0:oob'  
#                                   -GroupDisplayName "MyAutomatedGroup01" -GroupOwnerGUIDs ("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168") 
#                                   -GroupMemberGUIDs ("40a0b8dc-abcd-1234-efgh-c9e018656dcd","0b85cc49-abcd-1234-efgh-ea5635e33826")
#
# Custom Call, with AAD_UIDs of individual owners,members specified as well as Manual Group Description and left side email address name (leftside@rightside.edu)
#.\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;#?ij;eroiejr23;s~!e3v' -redirectURL 'urn:ietf:wg:oauth:2.0:oob'  
#                     -GroupDisplayName "MyAutomatedGroup01" -GroupDescription "Test Group with Manual Entries"-GroupMailEnabled $true -GroupMailNickName "MyAutomatedGroup01emailaddress" 
#                     -GroupOwnerGUIDs ("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168")
#                     -GroupMemberGUIDs ("40a0b8dc-abcd-1234-efgh-c9e018656dcd","0b85cc49-abcd-1234-efgh-ea5635e33826")

$TenantID = 'fe03a341-0421-1234-4321-12345678abcd'
$ClientID = "gg034614-0421-1234-4321-12345678abcd"
$ClientSecret = 'safo;#?ij;eroiejr23;s~!e3v'
$redirectURL = 'urn:ietf:wg:oauth:2.0:oob'
$GroupOwnersList = @("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168")

#without Owners
.\Create-uGroup_PublicDistro.ps1 -GroupDisplayName "MyAutomatedGroup01" -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret -RedirectURL $redirectURL
#with Owners
.\Create-uGroup_PublicDistro.ps1 -GroupDisplayName "MyAutomatedGroup01" -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret -RedirectURL $redirectURL -GroupOwnerGUIDs $GroupOwnersList