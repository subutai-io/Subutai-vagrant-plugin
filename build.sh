#!/bin/bash

rm subutai_cli-1.0.0.gem
gem build subutai_cli.gemspec
gem uninstall subutai_cli
gem install ./subutai_cli-1.0.0.gem
vagrant plugin uninstall subutai_cli
vagrant plugin install ./subutai_cli-1.0.0.gem