require_relative 'subutai_config'
require_relative '../../../lib/vagrant-subutai/util/powershell'
require_relative '../../../lib/vagrant-subutai/util/terminal'

# For managing VM disks
module SubutaiDisk
  DISK_NAME = "SubutaiDisk".freeze
  DISK_FORMAT = "vdi".freeze

  DISK_FORMAT_VIRTUALBOX = "vdi".freeze
  DISK_FORMAT_VMWARE = "vmdk".freeze
  DISK_FORMAT_HYPERV = "vhdx".freeze
  DISK_FORMAT_LIBVIRT = "qcow2".freeze

  PROVIDER_VMWARE = "vmware".freeze
  PROVIDER_HYPERV = "hyper_v".freeze
  PROVIDER_LIBVIRT = "libvirt".freeze

  SCRIPT_HYPERV_DISK_CREATE_PATH = 'script/create_disk_and_attach.ps1'.freeze
  SCRIPT_HYPERV_DISK_REMOVE_PATH = 'script/remove_virtual_disk.ps1'.freeze

  # Checks disk size for adding new VM disks
  def self.has_grow
    grow_by = SubutaiConfig.get_grow_by

    if grow_by.nil?
      [false, nil]
    elsif grow_by > 0
      [true, grow_by]
    else
      [false, nil]
    end
  end

  # Save disk pathes. We saves for cleanup while destroying peer
  def self.save_path(port, file_path)
    if SubutaiConfig.get(:_DISK_PATHES).nil?
      hash = {}
      hash[port] = file_path
      SubutaiConfig.put(:_DISK_PATHES, hash, true)
      true
    else
      hash = SubutaiConfig.get(:_DISK_PATHES)
      hash[port] = file_path
      SubutaiConfig.put(:_DISK_PATHES, hash, true)
      true
    end
  end

  # Gives disk port
  def self.port
    port = SubutaiConfig.get(:_DISK_PORT)

    # Default port value is 1
    if port.nil?
      1
    else
      port.to_i + 1 # increasing by one for next vm disk attach
    end
  end

  def self.size(grow_by)
    grow_by.to_i * 1024 + 2 * 1024 # 2 gb for overhead, unit in megabytes
  end

  def self.libvirt_size(grow_by)
    size = grow_by.to_i + 2   # 2 gb for overhead, unit in gb
    "#{size}G"
  end

  def self.vmware_size(grow_by)
    grow_by.to_i + 2 # 2 gb for overhead, unit in gb
  end

  def self.vmware_create_disk(grow_by, file_disk)
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      system("\"C:\\Program Files (x86)\\VMware\\VMware Workstation\\vmware-vdiskmanager.exe\" -c -s #{vmware_size(grow_by)}GB -a lsilogic -t 0 #{file_disk}")
    elsif RbConfig::CONFIG['host_os'] =~ /darwin/
      system("\"/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager\" -c -s #{vmware_size(grow_by)}GB -a lsilogic -t 0 #{file_disk}")
    elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
      system "vmware-vdiskmanager -c -s #{vmware_size(grow_by)}GB -a lsilogic -t 0 #{file_disk}"
    end
  end

  def self.hyperv_create_disk(grow_by, file_disk)
    script = File.join(File.expand_path(File.dirname(__FILE__)), SCRIPT_HYPERV_DISK_CREATE_PATH)
    id = SubutaiConfig.machine_id(:hyper_v)

    if id.nil?
      Put.error("[FAILED] Disk Creation. Not found machine id")
      false
    else
      VagrantSubutai::Util::Powershell.execute(script, "-VmId", id, "-DiskPath", "'#{file_disk}'", "-DiskSize", "#{vmware_size(grow_by)}")
    end
  end

  def self.parallels_create_disk(grow_by)
    id = SubutaiConfig.machine_id(:parallels)

    if id.nil?
      Put.error("[FAILED] Disk Creation. Not found machine id")
      false
    else
      # prlctl set ec45bf0c-1d1e-44c0-b5b8-6d80623b8364 --device-add=hdd --size=4092 # in megabytes
      VagrantSubutai::Util::Terminal.execute_cmd("prlctl", "set", id, "--device-add=hdd", "--size=#{SubutaiDisk.size(grow_by)}")
    end
  end

  def self.hyperv_remove_disk
    script = File.join(File.expand_path(File.dirname(__FILE__)), SCRIPT_HYPERV_DISK_REMOVE_PATH)
    id = SubutaiConfig.machine_id(:hyper_v)

    if id.nil?
      Put.error("[FAILED] Remove virtual disk. Not found machine id")
      false
    else
      VagrantSubutai::Util::Powershell.execute(script, "-VmId", id)
    end
  end

  # Save disk size and port to generated.yml
  def self.save_conf(grow_by)
    SubutaiConfig.put(:_DISK_PORT, port, true)

    generated_disk = SubutaiConfig.get(:_DISK_SIZE)
    if generated_disk.nil?
      SubutaiConfig.put(:_DISK_SIZE, grow_by, true) # we set all size of virtual disks to _DISK_SIZE in unit gb
      true
    else
      SubutaiConfig.put(:_DISK_SIZE, grow_by + generated_disk.to_i, true) # we set all size of virtual disks to _DISK_SIZE in unit gb
      true
    end
  end

  def self.message(grow_by)
    disk_size = SubutaiConfig.get(:DISK_SIZE)

    unless disk_size.nil?
      disk_size = disk_size.to_i
      "==> default: Disk size configured to #{disk_size}GB, increasing #{disk_size - grow_by}GB default by #{grow_by}GB."
    end
  end

  # Gives disk file name
  # THIS IS FOR OLD VERSION BOXES
  # UNDER <= v3.0.5
  def self.file(grow_by)
    disk_port = port

    # get disk path from conf file
    if SubutaiConfig.get(:SUBUTAI_DISK_PATH).nil?
      "./#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{DISK_FORMAT}"
    else
      File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{DISK_FORMAT}")
    end
  end

  def self.file_path(grow_by, provider)
    disk_port = port
    disk_format = DISK_FORMAT

    case provider
    when PROVIDER_VMWARE
      disk_format = DISK_FORMAT_VMWARE
    when PROVIDER_HYPERV
      disk_format = DISK_FORMAT_HYPERV
    when PROVIDER_LIBVIRT
      disk_format = DISK_FORMAT_LIBVIRT
    end

    # get disk path from conf file
    if SubutaiConfig.get(:SUBUTAI_DISK_PATH).nil?
      File.expand_path "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{disk_format}"
    else
      File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{disk_format}")
    end
  end
end