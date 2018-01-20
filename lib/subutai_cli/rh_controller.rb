require 'subutai_cli'
require_relative 'models/resource_host'
require 'json'

module SubutaiCli
  class RhController

    def all(token)
      json = JSON.parse(SubutaiCli::Rest::SubutaiConsole.requests($SUBUTAI_CONSOLE_URL, token))

      json.each do |data|
        STDOUT.puts data['id']
        STDOUT.puts data['hostname']
        STDOUT.puts data['status']
        STDOUT.puts data['isManagement']
        STDOUT.puts data['isConnected']
      end
    end
  end
end