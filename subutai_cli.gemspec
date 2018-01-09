lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/subutai_cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'subutai_cli'
  spec.version       = SubutaiCli::VERSION
  spec.authors       = ["Kylych Tynybekov", "Adilet Zholdoshbekov"]
  spec.email         = ["ktynybekov@subutai.io", "azholdoshbekov@optimal-dynamics.com"]
  spec.summary       = ["Subutai CLI. Execute subutai commands outside the Vagrant box"]
  spec.description   = ["Part of Subutai Social Tooling"]
  spec.homepage      = "https://github.com/subutai-io/vagrant"
  spec.license       = "MIT"

  spec.files         = ["lib/subutai_cli.rb", "lib/subutai_cli/command.rb", "lib/subutai_cli/version.rb", "lib/subutai_cli/plugin.rb"]
  spec.require_paths = ['lib']
end
