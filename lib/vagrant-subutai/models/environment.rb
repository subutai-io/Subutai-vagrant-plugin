# Blueprint environment model

module VagrantSubutai
  module Models
    class Environment
      attr_accessor :name,
                    :containers # Model 'Container'
    end
  end
end