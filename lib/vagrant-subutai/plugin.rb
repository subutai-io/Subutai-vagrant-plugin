module VagrantSubutai
    module Subutai
        class Plugin < Vagrant.plugin(2)
            name 'Subutai'
            description <<-DESC
              Vagrant Subutai CLI - executes Subutai scripts in target hosts
            DESC

            command(:subutai) do
                require_relative 'command'
                Command
            end

            config 'subutai_console' do
              require_relative 'config'
              Config
            end
        end
    end
end