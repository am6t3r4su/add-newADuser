<#

#>

#Declare variables
$fileOfLog = "C:\Users\Administrateur\Documents\PasswordReset.log.txt"
$dateOfLog  = (Get-Date -Format "MM/dd/yyyy HH:mm:ss")

Write-Host -F Cyan "
###########################################################################################
###########################################################################################
"


#Check if default log file exist
Write-Host -F Cyan "[*] Checking if default log file exist ..."
If ([bool](Test-Path $fileOfLog)) {
        Write-Host -F Green "[+] Ok!"       
} Else {
        Write-Host -F Yellow "[!] Warning! Default usefull log file does not exist"
        Write-Host -F Cyan "[*] Creating default usefull log file at $fileOfLog location..." 
        Start-Sleep -Seconds 1.5
        New-Item -Path $fileOfLog -ItemType File | Out-Null
}


Function Get-ADUserCreds {

        [CmdletBinding()]
        Param ()

        Begin {}
        Process {
                # Match if login exist 
                Do{$Global:adLoginID   = (Read-Host "Set an user login who exist in domain`nLogin")
                While ([string]::IsNullOrWhiteSpace($adLoginID)) {$Global:adLoginID = (Read-Host -Prompt "Login can't be empty")}} Until ([bool](Get-ADUser -Filter {SamAccountName -eq $adLoginID}))
                # Match if password is complex
                Do {$Global:adUserPassword = (Read-Host "`nCreate a complex password`nThe password must be a minimum length of 14 characters including capital letters, lowercase letters, numbers and specials characters`nPassword")
                } Until (($adUserPassword.Length -ge 14) -and ($adUserPassword -match '[a-z]') -and ($adUserPassword -match '[A-Z]') -and ($adUserPassword -match '\d') -and ($adUserPassword -match '[^a-zA-Z0-9]'))
                Start-Sleep -Seconds 1.5; Write-Host -F Green "[+] Password of $adLoginID has been successfully created!"
                #Saisie du motif de l'incident
                $Global:causeOfIncident   = (Read-Host "Cause of incident")
                While ([string]::IsNullOrWhiteSpace($causeOfIncident)) {$Global:causeOfIncident = (Read-Host -Prompt "Cause of incident can't be empty")}
        }
        End {}
}


Function Reset-ADUserPassword {

        [CmdletBinding()]
        Param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$User,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$Password,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$Incident
        )

        Begin {}
        Process {}
        End {}
}


#Test Get-ADUserCreds, Reset-ADUserPassword, Set-ADAccountPassword functions
Try{
        Get-ADUserCreds     
        Reset-ADUserPassword -User $adLoginID `
                             -Password $adUserPassword `
                             -Incident $causeOfIncident
        #Apply password reset
        #Set-ADAccountPassword -Identity $adLoginID -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $adUserPassword -Force)
        #Set-ADUser -Identity $adLoginID -ChangePasswordAtLogon $true
        Write-Host -F Green "[+] Password for $adLoginID user has been successfully reseted!"
}Catch{
        Write-Error "An error has occurred to reset password`nAborded!"
        Exit 1
}

$messageTXT = "[$dateOfLog] Password reset for : $adLoginID - Cause of incident: $causeOfIncident"

Function Trace-ResetActivity {

        [CmdletBinding()]
        Param (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$File,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string]$ActivityReport
        )

        Begin {}
        Process {
                #Add cause of incident to log file
                Add-Content -Path $File -Value $ActivityReport
                Start-Sleep -Seconds 1.5
        }
        End {}
}

#Test Trace-ResetActivity function
Try {
        Trace-ResetActivity -File $fileOfLog -ActivityReport "$messageTXT"
        Write-Host -F Green "[+] Password reset for $adLoginID user has been logged to default log file"

        #Print
        Write-Host -F Gray "
        About user
        ----------------------------------------------------------------
            Login : $adLoginID

        Incident
        ----------------------------------------------------------------
            Date : $dateOfLog
            Cause : $causeOfIncident

        Log
        ----------------------------------------------------------------
            Log file location : $fileOfLog
        "
} Catch {
        Write-Error "An error has occurred to trace reset activity`nArboded!"
        Exit 1
}
