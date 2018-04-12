require_relative 'subutai_config'

# For managing VM disks
module SubutaiDisk
  DISK_NAME = "SubutaiDisk".freeze
  DISK_FORMAT = "vdi".freeze
  DISK_FORMAT_VIRTUALBOX = "vdi".freeze
  DISK_FORMAT_VMWARE = "vmdk".freeze
  PROVIDER_VMWARE = "vmware".freeze

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

  def self.vmware_crate_disk(grow_by, file_disk)
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      false # Todo add windows vmware disk path
    elsif RbConfig::CONFIG['host_os'] =~ /darwin/
      false # Todo add osx vmware disk path
    elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
      system "vmware-vdiskmanager -c -s #{vmware_size(grow_by)}GB -a lsilogic -t 0 #{file_disk}"
    end
  end

  # Save disk size and port to generated.yml
  def self.save_conf(grow_by)
    SubutaiConfig.put(:_DISK_PORT, port, true)

    generated_disk = SubutaiConfig.get(:_DISK_SIZE)
    if generated_disk.nil?
      SubutaiConfig.put(:_DISK_SIZE, grow_by, true) # we set all size of virtual disks to _DISK_SIZE in unit gb
    else
      SubutaiConfig.put(:_DISK_SIZE, grow_by + generated_disk.to_i, true) # we set all size of virtual disks to _DISK_SIZE in unit gb
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
      # Check is directory exist
      if File.directory?(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
        # check permission
        if File.writable?(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
          File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{DISK_FORMAT}")
        else
          Put.warn "No write permission: #{SubutaiConfig.get(:SUBUTAI_DISK_PATH)}"
          "./#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{DISK_FORMAT}"
        end
      else
        Put.warn "Invalid path: #{SubutaiConfig.get(:SUBUTAI_DISK_PATH)}"
        "./#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{DISK_FORMAT}"
      end
    end
  end

  def self.file_path(grow_by, provider)
    disk_port = port
    disk_format = DISK_FORMAT

    if provider == PROVIDER_VMWARE
      disk_format = DISK_FORMAT_VMWARE
    end

    # get disk path from conf file
    if SubutaiConfig.get(:SUBUTAI_DISK_PATH).nil?
      File.join(Dir.pwd, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{disk_format}")
    else
      # Check is directory exist
      if File.directory?(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
        # check permission
        if File.writable?(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
          File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{disk_format}")
        else
          Put.warn "No write permission: #{SubutaiConfig.get(:SUBUTAI_DISK_PATH)}"
          File.join(Dir.pwd, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{disk_format}")
        end
      else
        Put.warn "Invalid path: #{SubutaiConfig.get(:SUBUTAI_DISK_PATH)}"
        File.join(Dir.pwd, "#{DISK_NAME}-#{disk_port.to_i}-#{grow_by}.#{disk_format}")
      end
    end
  end

  def self.path
    if File.directory?(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
      # check permission
      if File.writable?(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
        File.join(SubutaiConfig.get(:SUBUTAI_DISK_PATH).to_s)
      else
        Put.warn "No write permission: #{SubutaiConfig.get(:SUBUTAI_DISK_PATH)}"
        nil
      end
    else
      nil
    end
  end
end