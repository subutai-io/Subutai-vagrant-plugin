require 'net/https'
require 'uri'
require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Rest
    class Bazaar

      def self.login(email, password)
        uri = URI.parse(url + Configs::Bazaar::V1::LOGIN)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({'email' => email, 'password' => password})

        https.request(request)
      end

      # Check is Peer Os registered to Bazaar
      def self.registered(fingerprint)
        uri = URI.parse(url + Configs::Bazaar::V1::PEER.gsub('{FINGERPRINT}', fingerprint))
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri)
        https.request(request)
      end

      # Creates Environment
      def self.environment(token, params)
        uri = URI.parse(url + Configs::Bazaar::V1::ENVIRONMENTS)

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 21600 # 6 hours

        request = Net::HTTP::Post.new(uri.request_uri, {'Cookie' => token,  'Content-Type' => 'application/json'})
        request.body = params.to_json

        https.request(request)
      end

      # List of environments
      def self.list(cookies)
        uri = URI.parse(url + Configs::Bazaar::V1::ENVIRONMENTS)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri, {'Cookie' => cookies})
        https.request(request)
      end

      def self.url
        env = SubutaiConfig.get(:SUBUTAI_ENV)
        env = env.to_s

        if env == VagrantSubutai::Configs::Environment::PROD
          return VagrantSubutai::Configs::Bazaar::BASE_PROD
        elsif env == VagrantSubutai::Configs::Environment::MASTER
          return VagrantSubutai::Configs::Bazaar::BASE_MASTER
        elsif env == VagrantSubutai::Configs::Environment::DEV
          return VagrantSubutai::Configs::Bazaar::BASE_DEV
        end
      end
    end
  end
end