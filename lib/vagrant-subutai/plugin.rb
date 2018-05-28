module VagrantSubutai
    module Subutai
        class Plugin < Vagrant.plugin(2)
            name 'subutai'

            description <<-DESC
              Vagrant Subutai CLI - executes Subutai scripts in target hosts
            DESC

            command(:subutai) do
                require_relative 'command'
                Command
            end

            provisioner "blueprint" do
               require_relative "provisioner"
               Provisioner
            end

            provisioner "registration" do
               require_relative "registration"
               Registration
            end

            provisioner "create_disk" do
              require_relative "create_disk"
              CreateDisk
            end

            provisioner "cleanup" do
              require_relative "cleanup"
              Cleanup
            end

            config 'subutai_console' do
               require_relative 'config'
               Config
            end
        end
    end
end