param (
    [string]$VmId = $(throw "-VmId is required.")
)

try {
    $vm = Get-VM -Id $VmId -ErrorAction "stop"
    Get-VMHardDiskDrive -VMName $vm.Name -ControllerType SCSI | Remove-VMHardDiskDrive
}
catch {
    Write-Error-Message "Failed to remove virtual disk "
}