lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/vagrant-subutai/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-subutai'
  spec.version       = VagrantSubutai::VERSION
  spec.licenses      = ['Apache-2.0']
  spec.authors       = ["Subutai"]
  spec.email         = "info@subutai.io"
  spec.summary       = ["Subutai CLI. Execute subutai commands outside the Vagrant box"]
  spec.description   = "Part of Subutai Tooling"
  spec.homepage      = "https://github.com/subutai-io/vagrant"
  spec.homepage      = "https://subutai.io"
  spec.metadata      = { "source_code_uri" => "https://github.com/subutai-io/vagrant" }

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'probench'
  spec.add_runtime_dependency 'probench'
end
