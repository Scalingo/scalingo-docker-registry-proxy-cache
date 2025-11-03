#!/bin/bash

curl -s https://bashunit.typeddevs.com/install.sh | bash

./lib/bashunit /vagrant/tests
