
#>

#Add necessary modules
Import-Module ActiveDirectory
Install-Module NTFSSecurity


Write-Host -F Cyan "
###########################################################################################
###########################################################################################
"

#Set domain name
$adDomainName = (Read-Host -Prompt "Enter an domain name")

While ([string]::IsNullOrWhiteSpace($adDomainName)) {$adDomainName = (Read-Host -Prompt "The domain name can't be empty! Enter an domain name")}
Write-Host -F Cyan "[+] Checking if domain name exist ..."
Start-Sleep 1.5

#Check if domain name exist
If (Get-ADDomain -Identity $adDomainName) { 
    Write-Host -F Green "[+] Ok"   
} Else {
    Exit 1
}

Function Add-NewADUser {

        [CmdletBinding()]
        Param ()

        Begin {}
        Process {
                Write-Host "`nSet up user data`n----------------------------------------------------------`n"
                $Global:adUserName = (Read-Host "Name")
                #Match if name is not empty
                While ([string]::IsNullOrWhiteSpace($adUserName)) {$Global:adUserName = (Read-Host -Prompt "AD user name can't be empty")}
                $Global:adUserGivenName = (Read-Host "Given name")
                #Match if given name is not empty
                While ([string]::IsNullOrWhiteSpace($adUserGivenName)) {$Global:adUserGivenName = (Read-Host -Prompt "AD user given name can't be empty")}
                #Check password complexity
                Do {$Global:adUserPassword = (Read-Host "`nCreate a complex password`nThe password must be a minimum length of 14 characters including capital letters, lowercase letters, numbers and specials characters`nPassword")
                } Until (($adUserPassword.Length -ge 14) -and ($adUserPassword -match '[a-z]') -and ($adUserPassword -match '[A-Z]') -and ($adUserPassword -match '\d') -and ($adUserPassword -match '[^a-zA-Z0-9]'))
        }
        End {}
}

#Test Add-NewADUser function
Try{
    Add-NewADUser
}Catch{
    Write-Error "An error has occurred when adding new AD user data."
    Exit 1
}

Function Set-ADLoginID {
<#
#>
    
            [CmdletBinding()]
            Param (
                    [Parameter(Mandatory)]
                    [ValidateNotNullOrEmpty()]
                    [string]$Name,
                    [Parameter(Mandatory)]
                    [ValidateNotNullOrEmpty()]
                    [string]$GivenName
            )
    
            Begin {}
            Process {
                    $_givenName     = $GivenName.Substring(0,1)
                    $ADLoginID = $_givenName.ToLower()+"."+$Name.ToLower()
                    Return $ADLoginID
            }
            End {}
    }
    
Write-Host -F Cyan "`n[+] Generating an login id ..."
$adLoginID  = Set-ADLoginID -Name $adUserName -GivenName $adUserGivenName
$adUserMail = $adLoginID+"@"+$adDomainName
$adUserFullName = "$adUserGivenName $adUserName"
Start-Sleep -Seconds 1.5

Write-Host -F Gray "
    About user
    ----------------------------------------------------------------
        Full name : $adUserFullName
        User principal name : $adLoginID
        Mail : $adUserMail
  
  "

  Function Set-ADUserData {
<#
#>
        [CmdletBinding()]
        Param ()

        Begin {}
        Process {
                #Match if role is not empty
                $Global:adUserRole = (Read-Host "Role")
                While ([string]::IsNullOrWhiteSpace($adUserRole)) {$Global:adUserRole = (Read-Host -Prompt "The role can't be empty")}
                #Match if department is not empty
                $Global:adUserDpt  = (Read-Host "Department [Commercial] [Direction] [Finance] [Informatique] [Logistique] [Marketing] [RH]")
                While ([string]::IsNullOrWhiteSpace($adUserDpt)) {$Global:adUserDpt = (Read-Host -Prompt "The department can't be empty")}
                Write-Host -F Cyan "[*] Assignment of $adUserFullName to $adUserDpt department"
                #Set Organizational unit
                $Global:adUserOU   = (Get-ADOrganizationalUnit -Filter *).DistinguishedName | Out-GridView -Title "Select an Organizational unit" -PassThru
                Write-Host -F Cyan "[*] Assignment of $adUserFullName to $adUserOU OrganizationalUnit"
                #Generate the default global
                $Global:adUserGroup   = "GG_"+$adUserDpt
                Write-Host -F Cyan "[*] Assignment of $adUserFullName to $adUserGroup global security group"        
        }
        End {}
}

Function Add-ADUserData {
<#
#>
        [CmdletBinding()]
        Param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$Role,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [ValidateSet("Commercial","Direction","Finance","Informatique","Logistique","Marketing","RH")]
                [string]$Department,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$OU,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [ValidateScript(
                                {If ([bool](Get-ADGroup -Filter {Name -eq $adUserGroup})) {
                                        $true
                                } Else { 
                                        Write-Error "An error has occurred cause group does not exist"
                                }
                                }
                 )]
                [string]$Group
        )

        Begin {}
        Process {}
        End {}
}

#Test Set-ADUserData, Add-ADUserData function
Try {
        Set-ADUserData
        Add-ADUserData -Role $adUserRole `
                       -Department $adUserDpt `
                       -OU $adUserGroup `
                       -Group $adUserGroup

        Start-Sleep -Seconds 1.5
        Write-Host -F Green "[+] SUCCESS!"
} Catch {
        Write-Error "An error has occurred when new AD user data has been added."
        Exit 1
}


#Variables
$directorID = ""
$directorGG = ""
$directionGG = ""
$directorADGroups = ("$directorGG","$directionGG")

Function Create-UserToAD {
<#
#>
        [CmdletBinding()]
        Param ()

        Begin {}
        Process {
                #Check if AD user exist
                If (Get-ADUser -Filter {SamAccountName -eq $adLoginID}) { 
                        Write-Error "$adLoginID already exist in $adDomainName"
                        Exit 1
                } Else {
                        #Crate new user to AD
                        New-ADUser -Name "$adUserName" `
                                   -DisplayName "$adUserFullName" `
                                   -GivenName $adUserGivenName `
                                   -Surname $adUserName `
                                   -SamAccountName $adLoginID `
                                   -UserPrincipalName $adUserMail `
                                   -EmailAddress $adUserMail `
                                   -Title $adUserDpt `
                                   -Path $adUserOU `
                                   -AccountPassword (ConvertTo-SecureString -AsPlainText $adUserPassword -Force) `
                                   -ChangePasswordAtLogon $true `
                                   -Enabled $true
                        Write-Host -F Green "[+] The new AD user $adUserFullName has been successfully added to $adDomainName"
                }
                #Add user to his affected global security group
                Try {
                        If ($adLoginID -eq $directorID ) {
                                Foreach($GlobalGroup in $directorADGroups) { 
                                        Add-ADGroupMember -Identity $GlobalGroup -Members $directorID
                                        Write-Host -F Green "[+] The director $directorID  has been successfully added to $GlobalGroup"
                                }
                        } Else {
                                Foreach ($GlobalGroup in $adUserGroup) { 
                                        Add-ADGroupMember -Identity $GlobalGroup -Members $adLoginID
                                        Write-Host -F Green "[+] The new AD user $adUserFullName has been successfully added to $GlobalGroup"
                                }
                        }
                } Catch {
                        Write-Error "An error has occurred to added the new user to group"
                }
        }
        End {}
}

#Test Create-UserToAD function
Try {
        Create-UserToAD
} Catch {
        Write-Host -F Red  "[!] An error has occured to add the new user to $adDomainName."
        Write-Host -F Cyan "[*] Cleaning credentials ..."
        Remove-ADUser -Identity $adDomainName
        Exit 1
}


#Private folder variables
$privateFolder = "E:\Private\$adUserDpt\$adUserName"
$privateFolderSharedName  = "$adUserName$"
$privateFolderNetworkName = "\\SRV-AD\$privateFolderSharedName"
$privateFolderDrive       = "\\SRV-AD.$adDomainName\$privateFolderSharedName"

Function Set-UserPrivateFolder {
<#
#>
        [CmdletBinding()]
        Param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$Folder,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$SharedName,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$SharedFolder,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$NetworkDrive
        )

        Begin {}
        Process {
                If(Test-Path $Folder) {
                        Write-Host -F Yellow "[!] Warning! The private folder already exist"               
                } Else {
                        New-Item -ItemType Directory -Path $Folder
                        Write-Host -F Green "[+] The private folder at location $Folder has been successfully created"                       
                }

                If (Test-Path $Folder) {
                        #Add Smb rights
                        Write-Host -F Cyan "[*] Creating Smb share and add change access rights to $adLoginID ..."
                        New-SmbShare -Name "$SharedName" -Path $Folder -FullAccess Administrateur -ChangeAccess $adLoginID | Out-Null
                        Start-Sleep 1.5
                        #Add Ntfs rights
                        Write-Host -F Cyan "[*] Creating Ntfs share and add access rights to $adLoginID ..."
                        Add-NTFSAccess -Path $Folder -Account $adLoginID -AccessRights Modify | Out-Null
                        Start-Sleep 1.5
                } Else {
                        Write-Error "An error has occured to add Smb or Ntfs $Folder share and rights."
                }

                #Test to create home drive
                Try{
                        Write-Host -F Cyan "[*] Creating automatic home drive mapped on P letter to $NetworkDrive"
                        Set-ADUser -Identity $adLoginID -HomeDrive P -HomeDirectory $NetworkDrive

                        Start-Sleep -Seconds 1.5
                        Write-Host -F Green "[+] The home drive mapped on P letter to $NetworkDrive has been created"
                }Catch{
                        Write-Error "An error has occured to create home drive mapped on P letter to $NetworkDrive"
                }

        }
        End {}
}

#Test Set-UserPrivateFolder function
Try {
        Set-UserPrivateFolder -Folder $privateFolder `
                              -SharedName $privateFolderSharedName `
                              -SharedFolder $privateFolderNetworkName `
                              -NetworkDrive $privateFolderDrive
} Catch {
        Write-Host -F Red  "[!] An error has occured to create and set private folder options"
}

#Print results
Write-Host -F Gray "
        About user
        ----------------------------------------------------------------------------------------
            Name : $adUserName
            Given name : $adUserGivenName
            Full name : $adUserFullName
            Login : $adLoginID
            Mail : $adUserMail
            Role: $adUserRole
            Department : $adUserDpt

        Organizational unit
        ----------------------------------------------------------------------------------------
            Organizational unit : $adUserOU

        Group
        ----------------------------------------------------------------------------------------
            Global security group : $adUserGroup
       
        Network sharing
        ----------------------------------------------------------------------------------------
            Personnal folder location : $privateFolder
            Shared name : $privateFolderSharedName
            Shared folder location : $privateFolderNetworkName
            Home drive : $privateFolderDrive
"
