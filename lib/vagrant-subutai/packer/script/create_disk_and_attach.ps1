param (
    [string]$VmId = $(throw "-VmId is required."),
    [System.IO.DirectoryInfo]$DiskPath = $(throw "-DiskPath is required."),
    [Int32]$DiskSize = $(throw "-DiskSize is required.")
)

try {
    $vm = Get-VM -Id $VmId -ErrorAction "stop"
    Write-Output $DiskPath.FullName

    # create new disk
    # converting GB to Byte
    NEW-VHD -Dynamic $DiskPath.FullName -SizeBytes $($DiskSize*1073741824)
    # attach new disk to VM
    ADD-VMHardDiskDrive -vmname $vm.Name -path $DiskPath.FullName -ControllerType SCSI
}
catch {
    Write-Error-Message "Failed to create disk or attach to VM "
}