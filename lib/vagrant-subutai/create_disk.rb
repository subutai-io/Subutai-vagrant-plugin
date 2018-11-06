require_relative '../vagrant-subutai'
require 'pathname'


module VagrantSubutai
  class CreateDisk < Vagrant.plugin(2, :provisioner)
    attr_reader :machine
    attr_reader :config

    # Initializes the provisioner with the machine that it will be
    # provisioning along with the provisioner configuration (if there
    # is any).
    #
    # The provisioner should _not_ do anything at this point except
    # initialize internal state.
    #
    # @param [Machine] machine The machine that this will be provisioning.
    # @param [Object] config Provisioner configuration, if one was set.
    def initialize(machine, config)
      @machine = machine
      @config  = config
    end

    # Called with the root configuration of the machine so the provisioner
    # can add some configuration on top of the machine.
    #
    # During this step, and this step only, the provisioner should modify
    # the root machine configuration to add any additional features it
    # may need. Examples include sharing folders, networking, and so on.
    # This step is guaranteed to be called before any of those steps are
    # done so the provisioner may do that.
    #
    # No return value is expected.
    def configure(root_config)
    end

    # This is the method called when the actual provisioning should be
    # done. The communicator is guaranteed to be ready at this point,
    # and any shared folders or networks are already setup.
    #
    # No return value is expected.
    # Create virtual disk for hyperv
    def hyperv
      has_grow, grow_by = SubutaiDisk.has_grow
      file_disk = SubutaiDisk.file_path(grow_by, "hyper_v")
      disk_path = Pathname.new file_disk

      unless disk_path.exist?
        Put.warn SubutaiDisk.message(grow_by)

        if has_grow
          if SubutaiDisk.hyperv_create_disk(grow_by, disk_path.to_s)
            SubutaiDisk.save_path(SubutaiDisk.port, disk_path.to_s)
            SubutaiDisk.save_conf(grow_by)
          end
        end
      else
        Put.error "Disk file already exist in #{file_disk}"
      end
    end

    # Create virtual disk for parallels
    def parallels
      has_grow, grow_by = SubutaiDisk.has_grow
      
      if has_grow
        if SubutaiDisk.parallels_create_disk(grow_by)
          Put.warn SubutaiDisk.message(grow_by)
          SubutaiDisk.save_conf(grow_by)
        end
      end
    end

    def provision
      if SubutaiConfig.provider == :hyper_v
        hyperv
      elsif SubutaiConfig.provider == :parallels
        parallels
      end
    end

    # This is the method called when destroying a machine that allows
    # for any state related to the machine created by the provisioner
    # to be cleaned up.
    def cleanup
    end
  end
end