# Optimize-HyperV
Optimize all VHD's attached to all virtual machines. Shutdown / Blank / Optimize / Restart

```

NAME
    Optimize-Hyperv.ps1

SYNOPSIS
    Optimize VHD(X) on all virtual machines in Hyper-V.


SYNTAX
    Optimize-Hyperv.ps1 [-Shutdown] [-WaitShutdown <Int32>] [-SDelete <String>] [-Zero] [<CommonParameters>]
    

DESCRIPTION
    This will optimize all virtual hard disks on all virtual machines
    attached to Hyper-V.  Options to zero out VHD before optimize as
    will as shutdown and restart VM before and after optimize.
    
    Optionally set timeout for waiting for machine to turn off.

    Optionally supply alternate path for sDelete.


PARAMETERS
    -Shutdown [<SwitchParameter>]
        Shutdown and Optimize running machines, ignores running machines
        otherwise.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    -WaitShutdown <Int32>
        How long should we wait for machine to shutdown.
        
        Required?                    false
        Position?                    named
        Default value                45
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false

    -SDelete <String>
        Location of sDelete executable.
        
        Required?                    false
        Position?                    named
        Default value                "$PSScriptRoot\exe\sdelete.exe"
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false

    -Zero [<SwitchParameter>]
        Zero out drives before Optimizing.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       true (ByPropertyName)
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 

INPUTS
    None


OUTPUTS
    None


NOTES
    

        None
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS > Optimize-Hyperv -Shutdown -Zero
    
    Shutdown, Zero Disk, Optimize, Reboot all VM's


    

    -------------------------- EXAMPLE 2 --------------------------

    PS > Optimize-Hyperv -Shutdown -Zero -WaitShutdown 120

    Shutdown (wait 120 seconds for shutdown), Zero Disk, Optimize, Reboot all VM's
```