require 'bundler'
begin
  require 'vagrant'
rescue LoadError
  Bundler.require(:default,:development)
end

require 'subutai_cli/command'

module SubutaiCli
  class Plugin < Vagrant.plugin("2")
    name "subutai_cli"
    command "subutai" do
      require_relative "subutai_cli/command"
      Command
    end
  end
end
