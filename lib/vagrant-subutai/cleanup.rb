require_relative '../vagrant-subutai'


module VagrantSubutai
  class Cleanup < Vagrant.plugin(2, :provisioner)
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
    def provision
    end

    # This is the method called when destroying a machine that allows
    # for any state related to the machine created by the provisioner
    # to be cleaned up.
    def cleanup
      # cleanup virtual disks
      disks = SubutaiConfig.get(:_DISK_PATHES)
      unless disks.nil?
        disks.keys.each do |key|
           if File.exist?(disks[key])
             begin
               File.delete(disks[key])
               puts " ==> Deleted file: #{disks[key]}"
             rescue Errno::EACCES
               puts " ==> (Permission denied) Failed delete file: #{disks[key]}"
             end
           end
        end
      end

      # cleanup generated files
      if File.exist?(SubutaiConfig::GENERATED_FILE)
        begin
          File.delete SubutaiConfig::GENERATED_FILE
          puts " ==> Deleted file: #{SubutaiConfig::GENERATED_FILE}"
        rescue Errno::EACCES
          puts " ==> (Permission denied) Failed delete file: #{SubutaiConfig::GENERATED_FILE}"
        end
      end
    end
  end
end