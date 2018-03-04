require 'net/https'
require 'uri'
require_relative '../../vagrant-subutai'
require 'mime/types'
require 'json'

module VagrantSubutai
  module Rest
    class SubutaiConsole
      # Subutai Console credentials username, password
      # Subutai Console url
      # login methods gets token
      def self.token(url, username, password)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::TOKEN)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data('username' => username, 'password' => password)

        https.request(request)
      end

      # Subutai Hub credentials email, password
      # specify your peer_name
      # peer_scope acceptable only like this "Public" : "Private"
      def self.register(token, url, email, password, peer_name, peer_scope)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::REGISTER_HUB + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'email' => email, 'password' => password, 'peerName' => peer_name, 'peerScope' => peer_scope})

        https.request(request)
      end

      # Approves Resource Host
      def self.approve(token, url, id)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::APPROVE + "/#{id}/approve?sptoken?=" + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Post.new(uri.request_uri)

        https.request(request)
      end

      # Gets Finger print Subutai Console
      def self.fingerprint(url)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::FINGERPRINT)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri)

        response = https.request(request)

        case response
          when Net::HTTPOK
            response.body
          else
            raise "Try again! #{response.body}"
        end
      end

      # Get Subutai Console RH requests
      # method GET
      def self.requests(url, token)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::REQUESTS + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri)

        https.request(request)
      end

      # Creates Environment
      # method POST
      def self.environment(url, token, params)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::ENVIRONMENT + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 21600 # 6 hours

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'topology' => params})

        https.request(request)
      end

      # Gets Peer Os resources (disk, ram and cpu)
      # method GET
      def self.resource(url, token)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::RESOURCES + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri)

        https.request(request)
      end

      # List Environments
      # method GET
      def self.environments(url, token)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::ENVIRONMENTS + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri)

        https.request(request)
      end

      # Sends command to Subutai Console
      # method POST
      def self.command(cmd, hostId, path, timeOut, url, token)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::COMMAND + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 21600 # 6 hours

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'command' => cmd, 'hostId' => hostId, 'path' => path, 'timeOut' => timeOut})

        https.request(request)
      end

      # Gives logs of Blueprint Environment builds
      # method GET
      def self.log(url, token, tracker_id)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::LOG + "#{tracker_id}?sptoken=#{token}")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 21600 # 6 hours

        request = Net::HTTP::Get.new(uri.request_uri)

        https.request(request)
      end

      # Add domain to Environment
      def self.domain(url, token, env_id, domain)
        uri = URI.parse("#{url}#{Configs::SubutaiConsoleAPI::V1::DOMAIN}#{env_id}/domains?sptoken=#{token}")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form([['file', ''], ['hostName', domain], ['strategy', 'NONE']], 'multipart/form-data')

        https.request(request)
      end
    end
  end
end