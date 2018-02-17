require_relative '../vagrant-subutai'
require 'json'

module VagrantSubutai
  class RhController

    def all(url, token)
      response = Rest::SubutaiConsole.requests(url, token)
      rhs = []

      case response
        when Net::HTTPOK
          json = JSON.parse(response.body)

          json.each do |data|
            rh = Models::Rh.new
            rh.id = data['id']
            rh.hostname = data['hostname']
            rh.status = data['status']
            rh.is_connected = data['isConnected']
            rh.is_management = data['isManagement']
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