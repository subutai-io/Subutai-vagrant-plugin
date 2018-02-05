require_relative '../vagrant-subutai'
require 'json'

module VagrantSubutai
  class RhController

    def all(token)
      response = VagrantSubutai::Rest::SubutaiConsole.requests($SUBUTAI_CONSOLE_URL, token)
      rhs = []

      case response
        when Net::HTTPOK
          json = JSON.parse(response.body)

          json.each do |data|
            rh = VagrantSubutai::Models::Rh.new
            rh.id = data['id']
            rh.hostname = data['hostname']
            rh.status = data['status']
            rh.isConnected = data['isConnected']
            rh.isManagement = data['isManagement']
            rhs << rh
          end
        else
          STDERR.puts "#{response.body}"
          raise 'Can\'t get requests info from Subutai Console'
      end

      rhs
    end
  end
end