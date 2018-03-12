require_relative '../vagrant-subutai'

module VagrantSubutai
  class Config < Vagrant.plugin('2', :config)
    attr_accessor :url

    def initialize
      super
      @url = UNSET_VALUE
    end

    def finalize!
      @url = '' if @url == UNSET_VALUE
    end
  end
end

