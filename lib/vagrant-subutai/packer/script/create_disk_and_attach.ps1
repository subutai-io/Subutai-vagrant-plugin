param (
    [string]$VmId = $(throw "-VmId is required."),
    [string]$DiskPath = $(throw "-DiskPath is required."),
    [Int32]$DiskSize = $(throw "-DiskSize is required.")
)

try {
    $vm = Get-VM -Id $VmId -ErrorAction "stop"
    Write-Output $DiskPath

    # create new disk
    # converting GB to Byte
    NEW-VHD -Dynamic $DiskPath -SizeBytes $($DiskSize*1073741824)
    # attach new disk to VM
    ADD-VMHardDiskDrive -vmname $vm.Name -path $DiskPath -ControllerType SCSI
}
catch {
    Write-Error-Message "Failed to create disk or attach to VM "
}