Try {
  $adapters = Get-NetAdapter -Physical | where status -eq 'up'

  foreach ($adapter in $adapters) {
    $switch = Hyper-V\Get-VMSwitch -SwitchType External | where { $_.NetAdapterInterfaceDescription -eq $adapter.InterfaceDescription } 2>nul
    if ($switch -eq $null) {
      $switch = Hyper-V\New-VMSwitch -Name 'vagrant-subutai' -NetAdapterName $adapter.Name -AllowManagementOS $TRUE -Notes 'Parent OS, VMs, WiFi' 2>nul
    }

    if ($switch -ne $null) {
      break
    }
  }
}
Catch {
  echo "Failed to create Virtual Switch"
}
