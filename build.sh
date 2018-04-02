#!/bin/bash

rm *.gem
gem build vagrant-subutai.gemspec

gem uninstall vagrant-subutai
gem install ./vagrant-subutai-*.gem

vagrant plugin uninstall vagrant-subutai
vagrant plugin install ./vagrant-subutai-*.gem
