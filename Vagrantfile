Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/focal64'

  config.vm.define 'docker-registry-cache' do |node|
    node.vm.hostname = 'docker-registry-cache'
    node.vm.provision 'shell', inline: '/vagrant/tests/vagrant-deploy.sh'
    node.vm.provision 'shell', inline: '/vagrant/tests/vagrant-tests.sh', run: 'always'
    node.vm.provider 'virtualbox' do |v|
      v.memory = 2048
    end
  end
end
