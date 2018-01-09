module SubutaiCli
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
        end
    end
end