require_relative '../vagrant-subutai'
require 'ipaddr'

module VagrantSubutai
  class Registration < Vagrant.plugin(2, :provisioner)
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
      if !SubutaiConfig.get(:BAZAAR_EMAIL).nil? && !SubutaiConfig.get(:BAZAAR_PASSWORD).nil? && !SubutaiConfig.get(:SUBUTAI_PASSWORD).nil?

        unless SubutaiConfig.boolean?(:BAZAAR_NO_AUTO)
          subutai_cli = Commands.new(ARGV, @machine.env)
          ip = subutai_cli.info(Configs::VagrantCommand::ARG_IP_ADDR)

          if ip.nil?
            STDOUT.puts 'We can\'t detect your PeerOS ip address!'
            exit
          end

          url = "https://#{ip}:#{Configs::SubutaiConsoleAPI::PORT}"

          if subutai_cli.is_management_ready?(url, 1)
            unless subutai_cli.registered?(url)
              subutai_cli.register(SubutaiConfig.get(:SUBUTAI_USERNAME), SubutaiConfig.get(:SUBUTAI_PASSWORD), url)
            end
          end
        end
      end

      # Write peer ip address to genereted file if provider Hyper-V
      if SubutaiConfig.boolean?(:SUBUTAI_PEER) && SubutaiConfig.provider == :hyper_v
        subutai_cli = Commands.new(ARGV, @machine.env)
        ip = subutai_cli.info(Configs::VagrantCommand::ARG_IP_ADDR)

        if ip.nil?
          STDOUT.puts 'We can\'t detect your PeerOS ip address!'
          exit
        end

        SubutaiConfig.put(:_IP_HYPERV, ip, true) if is_ip?(ip)
      end
    end

    # This is the method called when destroying a machine that allows
    # for any state related to the machine created by the provisioner
    # to be cleaned up.
    def cleanup
    end

    def is_ip?(ip)
      !!IPAddr.new(ip) rescue false
    end
  end
end