# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'subutai_cli/version'

Gem::Specification.new do |spec|
  spec.name          = "subutai_cli"
  spec.version       = SubutaiCli::VERSION
  spec.authors       = ["Kylych Tynybekov"]
  spec.email         = ["ktynybekov@subutai.io"]
  spec.summary       = ["Subutai CLI. Execute subutai commands outside the Vagrant box"]
  spec.description   = ["Part of Subutai Social Tooling"]
  spec.homepage      = "https://www.subutai.io"
  spec.license       = "ASK ME"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
