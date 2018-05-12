$adapters = Get-NetAdapter -Physical | where status -eq 'up'

foreach ($adapter in $adapters) {
  $switch = Hyper-V\Get-VMSwitch -SwitchType External | where { $_.NetAdapterInterfaceDescription -eq $adapter.InterfaceDescription }
  if ($switch -eq $null) {
    $switch = Hyper-V\New-VMSwitch -Name 'vagrant-subutai' -NetAdapterName $adapter.Name -AllowManagementOS $true -Notes 'Parent OS, VMs, WiFi'
  }

  if ($switch -ne $null) {
    break
  }
}