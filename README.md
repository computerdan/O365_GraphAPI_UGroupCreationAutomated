 O365_GraphAPI_UGroupCreationAutomated
 
	DLC 03/15/2019 - Public Distro version Created
	DLC uPenn 03/11/2019 - Generic OATH Header POST Invoke-Header Powershell Script to Create Unified Group with Owners and Members
	DLC uPenn 04/05/2019 - Adding Support to Get Owners/Members and report back Created Group info including Owners/Members
	DLC uPenn 04/05/2019 - If Members Blank - Copy Oweners to Members - O365 does not display groups in user GUIs when user is an owner but not a member
                       
	DLC uPenn 04/05/2019 - Adding support for allowExternalSenders and autoSubscribeNewMembers for when Graph API supports it 
                     - Currently known issue for allowExternalSenders not working with Post/Patch 
                       reference: https://docs.microsoft.com/en-us/graph/known-issues
                     - autoSubscribeNewMembers setting currently requires deligated auth to enable, which is not supported in this script
	<CurrentVersion> Represenation - DLC 03/15/2019

 	PUBLIC Version - This script DOES NOT contain sensitive or propriatory information

 	Reference: https://docs.microsoft.com/en-us/graph/api/group-post-groups?view=graph-rest-1.0

 	GraphAPI Application must be registered and given this access:
                             	Application:  Group.ReadWrite.All
                             	Application:  User.Read.All  Only needed if adding Group Owners or Members

 	This script expects Application Access - Not Deligated Access, as no username/password signin information is being collected/processed.
 	This script is intended for automated Unified Group Creation (no user interaction)

 	Owners and Members must be provided in an Array - using AzureAD GUID representation for each user

 	This script is unsigned

 		--Script Call Examples--

 			Simplest script call example:        (will create a mail enabled Unified Group with "MyAutomatedGroup01" Displayname and "myautomatedgroup01@costo.com" email address)
  				.\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;?ij;eroiejr23;s~!e3v' -redirectURL "urn:ietf:wg:oauth:2.0:oob" -GroupDisplayName "MyAutomatedGroup01"

 			Script call example with Owners and Members:
  				.\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;?ij;eroiejr23;s~!e3v' -redirectURL "urn:ietf:wg:oauth:2.0:oob" -GroupDisplayName "MyAutomatedGroup01" -GroupOwnerGUIDs ("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168") -GroupMemberGUIDs ("40a0b8dc-abcd-1234-efgh-c9e018656dcd","0b85cc49-abcd-1234-efgh-ea5635e33826")

 			Custom Call, with AAD_UIDs of individual owners,members specified as well as Manual Group Description and left side email address name (leftside@rightside.edu)
				.\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -GroupDisplayName "MyAutomatedGroup01" -GroupDescription "Test Group with Manual Entries"-GroupMailEnabled $true -GroupMailNickName "MyAutomatedGroup01emailaddress" -GroupOwnerGUIDs ("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168") -GroupMemberGUIDs ("40a0b8dc-abcd-1234-efgh-c9e018656dcd","0b85cc49-abcd-1234-efgh-ea5635e33826")


