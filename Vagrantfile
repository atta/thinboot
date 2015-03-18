# -*- mode: ruby -*-
# vi: set ft=ruby :

module_name= "thinboot"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vm.define "server" do |server|
    hostname = "server"
    server.vm.box = "puppetlabs/ubuntu-14.04-64-puppet"
    server.vm.hostname = hostname
 

    # Disable automatic box update checking. If you disable this, then
    # boxes will only be checked for updates when the user runs
    # `vagrant box outdated`. This is not recommended.
    # server.vm.box_check_update = false

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine. In the example below,
    # accessing "localhost:8080" will access port 80 on the guest machine.
    # server.vm.network "forwarded_port", guest: 80, host: 8080

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    server.vm.network :private_network, ip: "192.168.33.10", auto_config: false

    # Create a public network, which generally matched to bridged network.
    # Bridged networks make the machine appear as another physical device on
    # your network.
    # server.vm.network "public_network"

    # Share an additional folder to the guest VM. The first argument is
    # the path on the host to the actual folder. The second argument is
    # the path on the guest to mount the folder. And the optional third
    # argument is a set of non-required options.
    # server.vm.synced_folder "../data", "/vagrant_data"

    server.vm.synced_folder "./dist", "/etc/puppet/modules"
    server.vm.synced_folder "./data", "/etc/puppet/modules/#{module_name}/data"
    server.vm.synced_folder "./files", "/etc/puppet/modules/#{module_name}/files"
    server.vm.synced_folder "./lib", "/etc/puppet/modules/#{module_name}/lib"
    server.vm.synced_folder "./templates", "/etc/puppet/modules/#{module_name}/templates"
    server.vm.synced_folder "./manifests", "/etc/puppet/modules/#{module_name}/manifests"

    # Provider-specific server.ration so you can fine-tune various
    # backing providers for Vagrant. These expose provider-specific options.
    # Example for VirtualBox:
    #
    server.vm.provider "virtualbox" do |vb|
      # Display the VirtualBox GUI when booting the machine
      # vb.gui = true
    
      # Customize the amount of memory on the VM:
      vb.memory = "1024"
      vb.customize ["modifyvm", :id, "--rtcuseutc", "off"]
      vb.customize ["modifyvm", :id, "--chipset", "piix3"]
      unless File.exist?("#{hostname}.vdi")
        vb.customize ['createhd', '--filename', "#{hostname}.vdi", '--size', 20 * 1025]
        vb.customize ["storagectl", :id, "--name", "SATA Controller 1", "--add", "sata", "--controller", "IntelAHCI", "--portcount", "4", "--hostiocache", "on"]
        vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller 1', '--port', 0, '--device', 0, '--type', 'hdd', '--medium', "#{hostname}.vdi"]
      end
    end
    #
    # View the documentation for the provider you are using for more
    # information on available options.

    # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
    # such as FTP and Heroku are also available. See the documentation at
    # https://docs.vagrantup.com/v2/push/atlas.html for more information.
    # server.push.define "atlas" do |push|
    #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
    # end

    # Enable provisioning with a shell script. Additional provisioners such as
    # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
    # documentation for more information about their specific syntax and use.
    server.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -f -y git
      sudo gem list -i r10k || gem install r10k --no-rdoc --no-ri
      cd /vagrant && r10k -v info puppetfile install 2>&1
    SHELL

    server.vm.provision :puppet do |puppet|
      initialize_puppet_enviroment(puppet)
      puppet.facter = {
        :context    => "dev",
        :l3_default_route => "10.0.2.2"
      }
    end
  end

  config.vm.define "client" do |client|
    client.vm.box = "steigr/pxe"
    client.vm.network :private_network, :adapter=>1, ip: "192.168.33.100", auto_config: false
    client.vm.provider "virtualbox" do |vb|
      # Display the VirtualBox GUI when booting the machine
      vb.gui = true
    
      # Customize the amount of memory on the VM:
      vb.memory = "1024"
      vb.customize ["modifyvm", :id, "--rtcuseutc", "off"]
      vb.customize ["modifyvm", :id, "--chipset", "piix3"]
    end
  end
end

def initialize_puppet_enviroment(puppet)
  puppet.manifests_path = "."
  puppet.manifest_file  = "vagrant.pp"
  puppet.options        = ["--verbose", "--hiera_config=/vagrant/hiera.yaml", "--modulepath=/etc/puppet/modules:/vagrant/modules"]
end
