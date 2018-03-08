require 'net/https'
require 'uri'
require_relative '../../vagrant-subutai'
require 'json'

module VagrantSubutai
  module Rest
    class Bazaar

      def self.variables(subutai_json, peers_id, cookies)
        uri = URI.parse(url + Configs::Bazaar::V1::VARIABLES)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        # TODO with cookies
        # request = Net::HTTP::Put.new(uri.request_uri, {'Cookie' => cookies,  'Content-Type' => 'application/x-www-form-urlencoded'})

        request = Net::HTTP::Put.new(uri.request_uri)
        request.set_form_data({'blueprint' => subutai_json.to_json, 'peers' => [peers_id]})

        https.request(request)
      end

      def self.blueprint(blueprint, variables, peer_id, cookies)
        uri = URI.parse(url + Configs::Bazaar::V1::BLUEPRINT)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Post.new(uri.request_uri, {'Cookie' => cookies,  'Content-Type' => 'application/x-www-form-urlencoded'})
        request.set_form_data({'blueprint' => blueprint.to_json, 'variables'=> variables.to_json, 'peers' => peer_id})

        https.request(request)
      end

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
      def self.environment(cookies, params)
        uri = URI.parse(url + Configs::Bazaar::V1::ENVIRONMENTS)

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 21600 # 6 hours

        request = Net::HTTP::Post.new(uri.request_uri, {'Cookie' => cookies,  'Content-Type' => 'application/json'})
        request.body = params.to_json

        https.request(request)
      end

      # Tracks environment create state logs
      def self.log(cookies, subutai_id)
        uri = URI.parse(url + Configs::Bazaar::V1::LOG.gsub('{SUBUTAI_ID}', subutai_id))

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Get.new(uri.request_uri, {'Cookie' => cookies,  'Content-Type' => 'application/json'})

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

      # Reserve domain
      def self.reserve(cookies, domain)
        uri = URI.parse(url + Configs::Bazaar::V1::DOMAIN_RESERVE.gsub('{DOMAIN}', domain))
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        https.read_timeout = 3600 # an hour

        request = Net::HTTP::Put.new(uri.request_uri, {'Cookie' => cookies})
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