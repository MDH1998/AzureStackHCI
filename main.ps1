# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# NAMING CONVENTIONS
#
# For functions --> verb-Subject
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ********************************************************************************************************
# FUNCTION: check the path to xml file exists
# ********************************************************************************************************
function check-PathXML {
    if (Test-Path $XML_path) {
    }

    else {
        Write-Host "$XML_path does not exist"
        Write-Host "Stopping the script!"

        exit 100
    }
}

# ********************************************************************************************************
# FUNCTION: check if memory is an int
# ********************************************************************************************************
function check-Memory {
    if ($MemoryStartup -is [int]) {
    }

    else {
        Write-Host "$MemoryStartup is not an int"
        Write-Host "Stopping the script!"

        exit 101
    }
}

# ********************************************************************************************************
# FUNCTION: check the path boot device path exists
# ********************************************************************************************************
function check-BootDevicePath {
    if (Test-Path $BootDevicePath) {
    }

    else {
        Write-Host "$BootDevicePath does not exist"
        Write-Host "Stopping the script!"

        exit 102
    }
}

# ********************************************************************************************************
# FUNCTION: check the boot device extention and assign the generation
# ********************************************************************************************************
function check-BootDeviceExtention {
    if ($BootDeviceExstention -eq "VHD") {
        $global:Generation = "1"
        
    }
    elseif ($BootDeviceExstention -eq "VHDX") {
        $global:Generation = "2"
    }
    else {
        Write-Host "$BootDeviceExstention is incorrect"
        Write-Host "    Should be VHD or VHDX"
        Write-Host "Stopping the script!"

        exit 103
    }
}

# ********************************************************************************************************
# FUNCTION: read data from xml file
# ********************************************************************************************************
function read-DataFromXML {

    param([string]$FileLocation)
    
    [Xml.XmlDocument]$script:XML_ConfigFile = Get-Content -LiteralPath $FileLocation        # "Read" the whole file
    $script:XML_Config = $XML_ConfigFile.Configuration                                      # Configuration element

    # ============================
    # Credential
    # ============================
    [Xml.XmlElement]$CredentialElement = $XML_Config.Credentials                            # Credential element

    $Script:RemoteMachineName = $CredentialElement.MachineName
    $Script:DomainAdmin = $CredentialElement.DomainAdmin

    # ============================
    # Create Virtual Machine
    # ============================
    [Xml.XmlElement]$CreateVMElement = $XML_Config.CreateVM                                 # Create element

    $Script:Hostname = $CreateVMElement.HostName
    $Script:VMName = $CreateVMElement.VMName
    $Script:MemoryStartup = $CreateVMElement.MemoryStartup                                  
    $Script:BootDeviceExstention = $CreateVMElement.BootDeviceExstention                    # VHD or VHDX
    $Script:BootDevicePath = $CreateVMElement.BootDevicePath                                # Path
    $Script:LocationPath = $CreateVMElement.LocationPath

    check-BootDeviceExtention $BootDeviceExstention
    check-BootDevicePath $BootDevicePath

    creat-VirtualMachine
}

# ********************************************************************************************************
# FUNCTION: Create virtual machines
# ********************************************************************************************************
function creat-VirtualMachine {
    $s = New-PSSession -ComputerName $RemoteMachineName -Credential $DomainAdmin 

    Invoke-Command -Session $s -ScriptBlock {

        new-vm -ComputerName $Using:Hostname -name $Using:VMName -MemoryStartupBytes 4GB -Generation 2
        Start-Sleep -s 10
        Remove-VMDvdDrive -VMName $Using:VMName -ControllerNumber 1 -ControllerLocation 0
        Start-Sleep -s 2
        Add-VMHardDiskDrive -VMName $Using:VMName -ControllerType SCSI -Path $Using:BootDevicePath
        Start-Sleep -s 2
        Start-VM -Name $Using:VMName
    }
}

function main-Script {
    $Path_Location = Get-Location
    Write-Host $Path_Location
    $XML_path = "$Path_Location\Config.xml"

    check-PathXML

    read-DataFromXML $XML_path
}

main-Script


# ********************************************************************************************************
# Used sources
# ********************************************************************************************************
# https://docs.microsoft.com/en-us/powershell/module/hyper-v/?view=windowsserver2022-ps
# https://docs.microsoft.com/en-us/powershell/module/hyper-v/start-vm?view=windowsserver2022-ps
# https://docs.microsoft.com/en-us/azure-stack/hci/manage/vm-powershell
# https://docs.microsoft.com/en-us/powershell/module/hyper-v/add-vmharddiskdrive?view=windowsserver2022-ps