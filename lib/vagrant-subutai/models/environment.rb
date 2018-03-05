# Blueprint environment model

module VagrantSubutai
  module Models
    class Environment
      attr_accessor :name,               # value for Peer Os
                    :containers,         # Model 'Container'
                    :environment_name,   # value for Bazaar
                    :exchange_ssh_keys,  # value for Bazaar
                    :register_hosts      # value for Bazaar
    end
  end
end