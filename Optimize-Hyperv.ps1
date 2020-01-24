<#
    .SYNOPSIS
        
    Optimize VHD(X) on all virtual machines in Hyper-V.

    .DESCRIPTION
    
    This will optimize all virtual hard disks on all virtual machines
    attached to Hyper-V.  Options to zero out VHD before optimize as
    will as shutdown and restart VM before and after optimize.

    Optionally set timeout for waiting for machine to turn off.

    Optionally supply alternate path for sDelete.
    
    .PARAMETER Shutdown
    
    Shutdown and Optimize running machines, ignores running machines
    otherwise.
    
    .PARAMETER WaitShutdown

    How long should we wait for machine to shutdown.    
    
    .PARAMETER SDelete
    
    Location of sDelete executable.    
    
    .PARAMETER Zero
    
    Zero out drives before Optimizing.

    .EXAMPLE
    
    Optimize-Hyperv -Shutdown -Zero
    Shutdown, Zero Disk, Optimize, Reboot all VM's

    .EXAMPLE

    Optimize-Hyperv -Shutdown -Zero -WaitShutdown 120
    Shutdown (wait 120 seconds for shutdown), Zero Disk, Optimize, Reboot all VM's

    .INPUTS

    None

    .OUTPUTS

    None

    .NOTES

    None

    .COMPONENT

    Hyper-V
#>

[CmdletBinding(PositionalBinding=$false)]
[OutputType([Boolean])]
Param (
    # Should we shutdown VM's if they are running    
    [Parameter(ValueFromPipelineByPropertyName = $True)]
    [Switch]
    $Shutdown,
    
    # How long should we wait for machine to shutdown
    [Parameter(ValueFromPipelineByPropertyName = $True)]
    [ValidateRange(0,300)]
    [int]
    $WaitShutdown = 45,

    # Location of sDelete executable
    [Parameter(ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()]        
    [string]
    $SDelete = "$PSScriptRoot\exe\sdelete.exe",
    
    # Zero out drives before Optimizing
    [Parameter(ValueFromPipelineByPropertyName = $True)]
    [switch]
    $Zero
)

begin {
    Write-Host "Optimize HyperV : Starting" -ForegroundColor DarkGreen
}

process {

    $Machines = Get-VM

    foreach ($VM in $Machines)
    {
        $Started = $false
        
        Write-Host "Found Virtual Machine : $($VM.Name)" -ForegroundColor Green
        Write-Host " - Machine state is : $($VM.State)" -ForegroundColor Green
        
        if ($VM.State -eq "Running" -and $Shutdown.IsPresent)
        {
            $Started = $true
            Write-Host " - Attempting to shutdown" -ForegroundColor Green
            Stop-VM -Name $VM.Name
            $seconds += 1
            
            while ($VM.State -eq 'Running')
            {
                Start-Sleep 1
                $VM = Get-VM -Name $VM.Name
                if ($seconds -gt $WaitShutdown)
                {
                    Write-Host " - Machine did not shutdown in $WaitShutdown seconds" -ForegroundColor Red
                    continue
                }
            }
            
            Write-Host " - Virtual Machine has been shutdown" -ForegroundColor Green
        }
        elseif ($VM.State -eq "Saved")
        {
            Write-Host " - Skipping this machine becuase its state is suspended" -ForegroundColor Yellow
            continue
        }
        elseif ($VM.State -eq "Running")
        {
            Write-Host " - Skipping this machine becuase its running and you didn't tell me to shutdown" -ForegroundColor Yellow
            continue
        }
        
        # Test for any snapshots
        if ((Get-VM -Name $VM.Name).State -ne "Off" -or $null -ne (Get-VM -Name $VM.Name).ParentCheckpointId)
        {
            Write-Host " - Machine has snapshots and cannot be compressed" -ForegroundColor Red
            if ($Started)
            {
                Write-Host " - Restarting Virtual Machine" -ForegroundColor Green
                Start-VM -Name $VM.Name
            }
            continue
        }
        
        #Write-Host " - Machine is : $($VM.State)" -ForegroundColor Green
        
        foreach ($VHD in ((Get-VMHardDiskDrive -VMName $VM.Name).Path))
        {
            Write-Host " - Found disk attached to Virtual Machine : $VHD" -ForegroundColor Green
            
            Write-Host "  - Working on $VHD, please wait..." -ForegroundColor Gray
            Write-Host "  - Current size $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB)) GB" -ForegroundColor Gray
            
            if ($Zero.IsPresent)
            {
                $Disk = Mount-VHD -Path $VHD -Passthru -ErrorAction Stop
                
                Get-Disk -Number $Disk.Number | Get-Partition | ForEach-Object {
                    if ($_.DriveLetter)
                    {
                        if (Test-Path -Path $SDelete)
                        {
                            Write-Host "  - Zeroing out unused space on drive $($_.DriveLetter):" -ForegroundColor Green
                            & $SDelete -z -c -nobanner "$($_.DriveLetter):"
                        }
                        else
                        {
                            Write-Host "  - $SDelete not found.. skipping zeroing out" -ForegroundColor Red
                        }
                    }
                }
                
                Write-Host "  - Dismounting disk $VHD" -ForegroundColor Green
                Dismount-VHD -DiskNumber $Disk.Number -Confirm:$false
                
            }
            Write-Host "  - Compacting disk $VHD" -ForegroundColor Green
            Optimize-VHD -Path $VHD -Mode Full
            
            Write-Host "  - Optimized size $([math]::truncate($(Get-VHD -Path $VHD).FileSize/ 1GB)) GB"
            
            # Restart the machine if we shut it down
            if ($Started)
            {
                Write-Host " - Restarting Virtual Machine" -ForegroundColor Green
                Start-VM -Name $VM.Name
            }
        }
    }
}

end {
    Write-Host "Optimize HyperV : Complete" -ForegroundColor DarkGreen
}
