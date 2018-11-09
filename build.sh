#!/bin/bash

rm *.gem
gem build vagrant-subutai.gemspec
mv vagrant-subutai-*.gem vagrant-subutai.gem

gem uninstall vagrant-subutai
gem install ./vagrant-subutai.gem

vagrant plugin uninstall vagrant-subutai
vagrant plugin install ./vagrant-subutai.gem
