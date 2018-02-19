require 'net/https'
require 'uri'
require_relative '../../vagrant-subutai'

module VagrantSubutai
  module Rest
    class SubutaiConsole
      # Subutai Console credentials username, password
      # Subutai Console url
      # login methods gets token
      def self.token(url, username, password)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::TOKEN)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data('username' => username, 'password' => password)

        # returns response
        return http.request(request)
      end

      # Subutai Hub credentials email, password
      # specify your peer_name
      # peer_scope acceptable only like this "Public" : "Private"
      def self.register(token, url, email, password, peer_name, peer_scope)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::REGISTER_HUB + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'email' => email, 'password' => password, 'peerName' => peer_name, 'peerScope' => peer_scope})

        # returns response
        return https.request(request)
      end

      # Approves Resource Host
      def self.approve(token, url, id)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::APPROVE + "/#{id}/approve?sptoken?=" + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)

        return https.request(request)
      end

      # Gets Finger print Subutai Console
      def self.fingerprint(url)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::FINGERPRINT)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
      def self.requests(url, token)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::REQUESTS + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.request_uri)

        return https.request(request)
      end

      # Creates Environment
      def self.environment(url, token)
        uri = URI.parse(url + Configs::SubutaiConsoleAPI::V1::ENVIRONMENT + token)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'email' => email, 'password' => password, 'peerName' => peer_name, 'peerScope' => peer_scope})

        # returns response
        return https.request(request)
      end
    end
  end
end