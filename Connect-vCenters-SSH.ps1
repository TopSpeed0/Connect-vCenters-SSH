param (
    [switch]$StartSSH,
    [switch]$StopSSH
)
# Check if both switches are set
if ($StartSSH -and $StopSSH) {
    Write-Host "Error: Both switches cannot be set at the same time. Choose either Start or Stop."
    exit
}

# Import VMmware  module
import-module VMware.VimAutomation.Core -Force -SkipEditionCheck -ErrorAction SilentlyContinue | out-null

# logs
$logs = "C:\Logs\VMwareScriptErrors.log"

# Set VCs
$Site1 = 'vCenterServer1.Domain.local'
$Site2 = 'vCenterServer2.Domain.local'
$Site3 = 'vCenterServer3.Domain.local'
$Site4 = 'vCenterServer4.Domain.local'

# General User and Password
$user = 'administrator@vsphere.local'
$keyFile = "c:\Users\YourUser\Documents\VMware\aes.key"
$pswdFile = "c:\Users\YourUser\Documents\VMware\pswd.txt"


function HandleError {
    param (
        [string]$errorMessage
    )
    Write-Host "An unexpected error occurred: $errorMessage" -ForegroundColor Red
    # Additional error handling actions if needed
}

function PerformOperation {
    param (
        [ScriptBlock]$operation,
        $VMHost,
        $operationType
    )
    try {
        & $operation
    }
    catch [VMware.VimAutomation.exception] {
        $vimError = $_.Exception.Message
    }
    catch {
        # Catch any unexpected error
        $errorMessage = $_.Exception.Message
        HandleError -errorMessage $errorMessage
    }
    finally {
        if ($vimError) { 
            $log = "VMware.VimAutomation Failed with Error:$vimError" ; Write-Host $log -f red
            LogError $log
        } 
        elseif ($errorMessage) {
            $log = "An unexpected error occurred: $errorMessage"  ; Write-Host $log -ForegroundColor Red
            LogError $log
        }
        else { 
            Write-Host "Successfully Run Operation State:$State on VMHost: $VMHost" -f Green 
        }    
    }
}
function LogError {
    param (
        [string]$errorMessage
    )
    $logFilePath = $logs
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - Error: $errorMessage`n"
    Add-Content -Path $logFilePath -Value $logEntry
}

function Set-VMhostSSH {
    param (
        [string]$State,
        $VMhost,
        [bool]$Statup
    )
    $SSH = ($VMHost | Get-VMHostService | Where-Object { $_.Key -eq "TSM-SSH" })
    switch ($State) {
        'Start' {
            if ($SSH.Running -eq $false) {
                Start-VMHostService -HostService $SSH -Confirm:$FALSE | Out-Null
                $Start = 'Set SSH:Start'
            }
            else {
                $Start = 'Skip SSH:Start'
            }
        }
        'stop' {
            if ($SSH.Running -eq $true) {
                Stop-VMHostService -HostService $SSH -Confirm:$FALSE -ErrorAction Stop | Out-Null
                $stop = 'Set SSH:stop'
            }
            else {
                $Stop = 'Skip SSH:Stop'
            }
            if (!$Statup) {
                if ($SSH.Policy -ne 'off') {
                    Set-VMHostService -HostService $SSH -Policy Off -Confirm:$FALSE -ErrorAction Stop  | Out-Null
                    $policy = 'Set policy:off'
                }
                else {
                    $policy = 'skip Set policy:OFF'
                }
            }
        }
        Default {}
    }
    if ($Stop) { 
        $State = $Stop
    } 
    if ($policy) { 
        $State = $Stop, $policy
    } 
    if ($Start) {
        $State = $Start
    }
    $global:State = $State
}

function Set-VMwareSSO {
    param (
        $keyFile,
        $pswdFile,
        $user
    )
    $encryptedPswd = Get-Content -Path $pswdFile | ConvertTo-SecureString -Key (Get-Content -Path $keyFile)
    $password = New-Object System.Management.Automation.PSCredential($user, $encryptedPswd)
    return $password
}
$password = Set-VMwareSSO -keyFile $keyFile -pswdFile $pswdFile -user $user

# Unregister
if ($global:DefaultVIServers) { $global:DefaultVIServers | Disconnect-VIServer -Confirm:$false }
$vCenters  = Read-host -prompt "Site1, Site2, Site3, Site4, Site5"

switch ($vCenters ) {
    'Site1' {
        Write-Host "You Select to Connect to $Site1" -ForegroundColor DarkYellow
        Connect-VIServer $Site1 -Credential $password 
    }
    'Site2' { 
        Write-Host "You Select to Connect to $Site2" -ForegroundColor DarkYellow
        Connect-VIServer $Site2 -Credential $password 
    }
    'Site3' {
        Write-Host "You Select to Connect to $Site3" -ForegroundColor DarkYellow
        Connect-VIServer $Site3 -Credential $password 
    }
    'Site4' {
        Write-Host "You Select to Connect to $Site4" -ForegroundColor DarkYellow
        Connect-VIServer $Site4 -Credential $password 
    }
    'Site5' {
        Write-Host "You Select to Connect to $Site5" -ForegroundColor DarkYellow
        Connect-VIServer $Site5 -Credential $password 
    }
    
    Default {
        Write-Host "You Select to Connect to $Site1,$Site2" -ForegroundColor DarkYellow
        Connect-VIServer $Site1 -Credential $password
        Connect-VIServer $Site2 -Credential $password
    }
}
if ($global:DefaultVIServers) { Write-host "You Re now Connected to:$global:DefaultVIServers" -f DarkBlue } else {Write-error "Failed to Connect to Site:$vCenters" ; break}

# Determine the action based on the switches
$validActions = @('Start', 'Stop')
$SSHAction = switch ($true) {
    $StartSSH { 'Start' }
    $StopSSH { 'Stop' }
    default {
        do {
            $action = Read-Host -Prompt "SSH Stop/Start? [Start/Stop] or Enter to Skipping SSH operation"
        } while (-not ($action -in $validActions + ''))  # Accepts empty string for skipping
        $action
    }
}

# Perform the operation based on the chosen action
if ($SSHAction -ne '') {
    $clusterName = Get-Cluster | Out-GridView -PassThru

    foreach ($cluster in $clusterName) {
        $VMHosts = $cluster | Get-VMHost
        foreach ($VMHost in $VMHosts) {
            PerformOperation -Operation {
                if ($SSHAction -eq 'Start') {
                    Set-VMHostSSH -VMHost $VMHost -State 'Start'
                }
                elseif ($SSHAction -eq 'Stop') {
                    Set-VMHostSSH -VMHost $VMHost -State 'Stop' -Startup:$false
                }
            } -VMHost $VMHost
        }
    }
}
else {
    Write-Host "No action specified. Skipping SSH operation." -ForegroundColor Yellow

}
