#DLC 03/15/2019 - Public Distro version Created
#DLC uPenn 03/11/2019 - Generic OATH Header POST Invoke-Header Powershell Script to Create Unified Group with Owners and Members
#DLC uPenn 04/05/2019 - Adding Support to Get Owners/Members and report back Created Group info including Owners/Members
#DLC uPenn 04/05/2019 - If Members Blank - Copy Oweners to Members - O365 does not display groups in user GUIs when user is an owner but not
#                       a member
#DLC uPenn 04/05/2019 - Adding support for allowExternalSenders and autoSubscribeNewMembers for when Graph API supports it 
#                     - Currently known issue for allowExternalSenders not working with Post/Patch 
#                       reference: https://docs.microsoft.com/en-us/graph/known-issues
#                     - autoSubscribeNewMembers setting currently requires deligated auth to enable, which is not supported in this script
#<BETA> Represenation - DLC 03/15/2019
#
# PUBLIC Version - This script DOES NOT contain sensitive or propriatory information
#
# Reference: https://docs.microsoft.com/en-us/graph/api/group-post-groups?view=graph-rest-1.0
#
# GraphAPI Application must be registered and given this access:
#                             Application:  Group.ReadWrite.All
#                             Application:  User.Read.All  #Only needed if adding Group Owners or Members
#
# This script expects Application Access - Not Deligated Access, as no username/password signin information is being collected/processed.
# This script is intended for automated Unified Group Creation (no user interaction)
#
# Owners and Members must be provided in an Array - using AzureAD GUID representation for each user
#
# This script is unsigned
#
# --Script Call Examples--
#
# Simplest script call example:        (will create a mail enabled Unified Group with "MyAutomatedGroup01" Displayname and "myautomatedgroup01@costo.com" email address)
#  .\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;#?ij;eroiejr23;s~!e3v' -redirectURL "urn:ietf:wg:oauth:2.0:oob"  
#                                   -GroupDisplayName "MyAutomatedGroup01"
#
# Script call example with Owners and Members:
#  .\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;#?ij;eroiejr23;s~!e3v' -redirectURL "urn:ietf:wg:oauth:2.0:oob"  
#                                   -GroupDisplayName "MyAutomatedGroup01" -GroupOwnerGUIDs ("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168") 
#                                   -GroupMemberGUIDs ("40a0b8dc-abcd-1234-efgh-c9e018656dcd","0b85cc49-abcd-1234-efgh-ea5635e33826")
#
# Custom Call, with AAD_UIDs of individual owners,members specified as well as Manual Group Description and left side email address name (leftside@rightside.edu)
#.\Create-uGroup_PublicDistro.ps1 -TenantID 'fe03a341-0421-1234-4321-12345678abcd' -ClientID "gg034614-0421-1234-4321-12345678abcd" -ClientSecret 'safo;#?ij;eroiejr23;s~!e3v' -redirectURL 'urn:ietf:wg:oauth:2.0:oob'  
#                     -GroupDisplayName "MyAutomatedGroup01" -GroupDescription "Test Group with Manual Entries"-GroupMailEnabled $true -GroupMailNickName "MyAutomatedGroup01emailaddress" 
#                     -GroupOwnerGUIDs ("ff02050a-abcd-1234-efgh-56833853f78e","b29fff3a-abcd-1234-efgh-5d0359224d7f","3d0ed4c0-abcd-1234-efgh-a39c5240b168")
#                     -GroupMemberGUIDs ("40a0b8dc-abcd-1234-efgh-c9e018656dcd","0b85cc49-abcd-1234-efgh-ea5635e33826")
#
#

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TenantID,
    [Parameter(Mandatory=$true)][string]$ClientID,
    [Parameter(Mandatory=$true)][string]$ClientSecret,
    [Parameter(Mandatory=$true)][string]$RedirectURL,
    [Parameter(Mandatory=$true)]
    [ValidateScript({If ($_ -notmatch '\s+') {
        $true
    } Else {
        Throw "$_ Can Not Contain Spaces!"
    }})][string]$GroupDisplayName,
    [Parameter(Mandatory=$false)][string]$GroupDescription = "Automated Group Creation",
    [Parameter(Mandatory=$false)][bool]$GroupMailEnabled = $true,
    [Parameter(Mandatory=$false)]
    [ValidateScript({If ($_ -notmatch '\s+') {
      $true
  } Else {
      Throw "$_ Can Not Contain Spaces!"
  }})][string]$GroupMailNickName,
    [Parameter(Mandatory=$false)][array]$GroupOwnerGUIDs = $null,
    [Parameter(Mandatory=$false)][array]$GroupMemberGUIDs = $null,
    [Parameter(Mandatory=$false)][bool]$AllowEmailFromOutside = $true,
    [Parameter(Mandatory=$false)][bool]$SendConvoAndEventsToInbox = $true
)

#try to retrieve Access Token Function
function get-accesstoken{
  [CmdletBinding()]
  param($ClientID,$redirectURL,$clientSecret,$TenantID)
  try {
      $result = Invoke-RestMethod https://login.microsoftonline.com/$TenantID/oauth2/token `
      -Method Post -ContentType "application/x-www-form-urlencoded" `
      -Body @{client_id=$clientId; 
             client_secret=$clientSecret; 
             redirect_uri=$redirectURL; 
             grant_type="client_credentials";
             resource="https://graph.microsoft.com";
             state="32"} -ErrorVariable InvokeError

             if($null -ne $result){return $result}
  }
  catch {write-host -f Red "Could not retrieve Auth Token"
      # Exception is stored in the automatic variable _
      write-host -f Red $InvokeError
      BREAK
  }

}
function get-groupowners{
  [CmdletBinding()]
  param($GroupID,$authHeader)

  #beta
  #Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/beta/groups/$GroupID/owners" -Headers $authHeader -ErrorVariable PostError -ContentType "application/json"
  #v1.0
  Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID/owners" -Headers $authHeader -ErrorVariable PostError -ContentType "application/json"

}

function get-groupmembers{
  [CmdletBinding()]
  param($GroupID,$authHeader)

  #beta
  #Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/beta/groups/$GroupID/members" -Headers $authHeader -ErrorVariable PostError -ContentType "application/json"
  #v1.0
  Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID/members" -Headers $authHeader -ErrorVariable PostError -ContentType "application/json"

}

function set-AllowEmailFromOutside{
  [CmdletBinding()]
  param($GroupID,$authHeader,[bool]$AllowSetting=$true)
  $allowExternalJSON = @"
  {
      "allowExternalSenders": true
  }
"@

  if ($AllowSetting = $true){
  #beta  
  #$AllowEmailFromOutsideReturn = Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/beta/groups/$GroupID" -Headers $authHeader -body $allowExternalJSON -ErrorVariable allowExtermalError -ContentType "application/json"
  #v1.0
  $AllowEmailFromOutsideReturn = Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID" -Headers $authHeader -body $allowExternalJSON -ErrorVariable allowExtermalError -ContentType "application/json"    
}
  else {$AllowEmailFromOutsideReturn = "Not Set"}

  if ($allowExtermalError){write-host -f Red $allowExtermalError}

  return $AllowEmailFromOutsideReturn
}

function set-SendConvoAndEventsToInbox{
  [CmdletBinding()]
  param($GroupID,$authHeader,[bool]$AllowSetting=$true)
  $autoSubscribeNewMembersJSON = @"
  {
      "autoSubscribeNewMembers": true
  }
"@
if ($AllowSetting = $true){
  #beta
  #$AllowEmailFromOutsideReturn = Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/beta/groups/$GroupID" -Headers $authHeader -body $autoSubscribeNewMembersJSON -ErrorVariable subscribeError -ContentType "application/json"
  #v1.0
  $AllowEmailFromOutsideReturn = Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID" -Headers $authHeader -body $autoSubscribeNewMembersJSON -ErrorVariable subscribeError -ContentType "application/json"
  }
  else {$AllowEmailFromOutsideReturn = "Not Set"}
return $AllowEmailFromOutsideReturn
}

#map $GroupDisplayname to $GroupMainNickName if none provided
if(($GroupMailEnabled -eq $true) -and ($GroupMailNickName -match $null)){$GroupMailNickName = $GroupDisplayName}
#force "True/False" Bool into "true/false" String all lowercase --- anything other than all lowercase throws error on post
[string]$GroupMailEnabled = $GroupMailEnabled.ToString().ToLower()
[string]$AllowEmailFromOutside = $AllowEmailFromOutside.ToString().ToLower()
[string]$SendConvoAndEventsToInbox = $SendConvoAndEventsToInbox.ToString().ToLower()

    #User URL Prefix for Graph beta
    #$userprefix = "`"https://graph.microsoft.com/beta/users/"
    #User URL Prefix for Graph v1.0
    $userprefix = "`"https://graph.microsoft.com/v1.0/users/"

  #clear
    $userbuild = $null
    $GOwnerCollection = @()
    
  #if more than one Group Owner GUID provided stack GUIDs with `n - format Array with User URL Previx for Graph v1.0
    foreach ($GroupOwnerGUID in $GroupOwnerGUIDs){
      $userbuild = "$userprefix$GroupOwnerGUID`""
      if ($GroupOwnerGUIDs.count -gt 1){
      $GOwnerCollection+=$userbuild+",`n"}else{$GOwnerCollection=$userbuild}
  }

#Group Owner POST form formatting
  $ownerbind = @"
"owners@odata.bind": [
  $GOwnerCollection
  ]
"@


  #if more than one Group Member GUID provided stack GUIDs with `n - format Array with User URL Previx for Graph v1.0
if ($GroupMemberGUIDs){
  #clear
  $userbuild = $null
  $GMemberCollection = @()
foreach ($GroupMemberGUID in $GroupMemberGUIDs){
  $userbuild = "$userprefix$GroupMemberGUID`""
  if ($GroupMemberGUIDs.count -gt 1){
    $GMemberCollection+=$userbuild+",`n"}else{$GMemberCollection=$userbuild}
}

#Group Member POST form formatting
$memberbind = @"
"members@odata.bind": [
$GMemberCollection
]
"@
}
#Else Copy Owners to Members
else{
$memberbind = @"
"members@odata.bind": [
$GOwnerCollection
]
"@
    }

#retrieve AccessToken with Get-AccessToken Function
$accesstoken = Get-AccessToken -ClientID $ClientID -redirectURL $RedirectURL -clientSecret $ClientSecret -TenantID $TenantID

#Seperate into Strings
$token = $accesstoken.Access_Token
$tokenexp = $accesstoken.expires_on

#format POST body as GraphAPI expects
$authHeader = @{
  'Content-Type'='application/json'
  'Authorization'="Bearer " + $token
  'ExpiresOn'=$tokenexp
  }
  $groupCreateBody = @"
  {
    "description": "$GroupDescription",
    "displayName": "$GroupDisplayName",
    "groupTypes": [
      "Unified"
    ],
    "mailEnabled": $GroupMailEnabled,
    "mailNickname": "$GroupMailNickName",
    "securityEnabled": false,
    $ownerbind,
    $memberbind
}
"@

#Invoke RestMethod with Successful AuthHeader (Token embedded), Posting Group Creation Params
$groupcreatevar = Invoke-RestMethod -Method Post -Uri "https://graph.microsoft.com/v1.0/groups" -Headers $authHeader -Body $groupCreateBody -ErrorVariable PostError -ContentType "application/json"

if ($PostError){
 write-host -f Red "Group Creation Error!"
 write-host -f Yellow $PostError
 write-host -f Blue "AuthHeader:"
 write-host -f Blue $authHeader.Keys
 write-host -f blue $authHeader.Values
 write-host -f Magenta "Body:"
 write-host -f Magenta $groupCreateBody
}

$groupID = $groupcreatevar.id
$groupMailEnabled = $groupcreatevar.mailEnabled
$groupMailNickName = $groupcreatevar.mailNickname
$GroupDisplayName = $groupcreatevar.displayName
$groupCreateDate = $groupcreatevar.createdDateTime
$GroupDescription = $groupcreatevar.description
$groupMail = $groupcreatevar.mail
$groupProxyAddresses = $groupcreatevar.ProxyAddresses
$groupVisability = $groupcreatevar.visibility
$groupOwnerList = get-groupowners -GroupID $groupID -authHeader $authHeader
$groupMemberList = get-groupmembers -GroupID $groupID -authHeader $authHeader
$AllowEmailFromOutsideSetting = $groupcreatevar.allowExternalSenders
$SendConvoAndEventsToInboxSettings = $groupcreatevar.autoSubscribeNewMembers

$groupOwnerUPNList = $null
if($groupOwnerList){
 foreach ($groupOwner in $groupownerList){
 $groupOwnerUPNList += $groupOwner.value.UserPrincipalName
 }
 [String]$groupOwnerUPNList = $groupOwnerUPNList -join ";"
}

$groupMemberUPNList = $null
 if($groupMemberList){
  foreach($groupMember in $groupMemberList){
  $groupMemberUPNList += $groupMember.value.UserPrincipalName
  }
 [String]$GroupMemberUPNList = $GroupMemberUPNList -join ";"
 }

 $returninfo = @{
  "Group ID" =   $groupID
  "Group Display Name" = $GroupDisplayName
  "Group Description" = $GroupDescription
  "Group NickName" = $groupMailNickName
  "Group Create TimeStamp" = $groupCreateDate
  "Group Mail Enabled" = $GroupMailEnabled
  "Group Email" = $groupMail
  "Group Proxy Addresses" = $groupProxyAddresses
  "Group Visability" = $groupVisability
  "Group Owners" = $groupOwnerUPNList
  "Group Members" = $groupMemberUPNList
  "Allow External Senders" = $AllowEmailFromOutsideSetting
  "AutoSubScribe New Members" = $SendConvoAndEventsToInboxSettings
 }

$returnInfoPSOb = New-Object psobject -Property $returninfo

return $returnInfoPSOb