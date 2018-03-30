#!/bin/bash

rm vagrant-subutai-1.1.4.gem
gem build vagrant-subutai.gemspec

gem uninstall vagrant-subutai
gem install ./vagrant-subutai-1.1.4.gem

vagrant plugin uninstall vagrant-subutai
vagrant plugin install ./vagrant-subutai-1.1.4.gem
