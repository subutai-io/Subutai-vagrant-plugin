Try {
  $adapters = Get-NetAdapter -Physical | where status -eq 'up'

  foreach ($adapter in $adapters) {
    $switch = Hyper-V\Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | where { $_.NetAdapterInterfaceDescription -eq $adapter.InterfaceDescription }
    if ($switch -eq $null) {
      $switch = Hyper-V\New-VMSwitch -Name 'vagrant-subutai' -ErrorAction SilentlyContinue -NetAdapterName $adapter.Name -AllowManagementOS $TRUE -Notes 'Parent OS, VMs, WiFi'
    }

    if ($switch -ne $null) {
      break
    }
  }
}
Catch {

}
