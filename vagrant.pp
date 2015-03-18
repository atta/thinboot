node default {
    contain stdlib

    # LVM
    physical_volume { '/dev/sdb': ensure => present, }
    volume_group { 'data':
        ensure           => present,
        physical_volumes => '/dev/sdb',
    }
    logical_volume { 'client':
        ensure       => present,
        volume_group => 'data',
        size         => '10G',
    }

    # LAN
    class { 'l23network': }
    l23network::l2::bridge { 'san1': } ->
    l23network::l3::ifconfig {"eth0": ipaddr=>'dhcp'} ->
    l23network::l3::ifconfig {"eth1": ipaddr=>'none'} ->
    l23network::l2::port { 'eth1': bridge => 'san1', } ->
    l23network::l3::ifconfig {"san1":  
        ipaddr => ['192.168.33.11/24', '192.168.33.12/24', '192.168.33.13/24', '192.168.33.14/24'],
    }

    # NAT
    exec { '/vagrant/files/tools/nathelper.sh -i eth0 -m':
        cwd     => '/tmp',
        path    => ['/usr/bin', '/usr/sbin']
    }

    # DNS DHCP TFTP
    file { '/var/lib/tftpboot':
        ensure => 'directory',
    }
    file {'/var/lib/tftpboot/ipxe.pxe':
        mode    => 644,
        owner   => root,
        group   => root,
        source  => 'puppet:///modules/thinboot/ipxe/ipxe.pxe',
        require => File['/var/lib/tftpboot'],
    }
    file {'/var/lib/tftpboot/preseed.cfg':
        mode    => 644,
        owner   => root,
        group   => root,
        source  => 'puppet:///modules/thinboot/preseed/preseed.cfg',
        require => File['/var/lib/tftpboot'],
    }
    class { 'dnsmasq':
        interface         => 'san1',
        listen_address    => '192.168.33.11',
        no_dhcp_interface => '10.0.2.15',
        domain            => 'int.lan',
        enable_tftp       => true,
        tftp_root         => '/var/lib/tftpboot',
        dhcp_boot         => 'ipxe.pxe',
        require           => File['/var/lib/tftpboot'],
    }
    dnsmasq::dhcp { 'dhcp': 
        dhcp_start => '192.168.33.100',
        dhcp_end   => '192.168.33.200',
        netmask    => '255.255.255.0',
        lease_time => '24h'
    }
 
    # iSCSI
    package {'tgt':
        ensure => 'installed'
    }
    file {'/etc/tgt/conf.d/thinclient.target.conf':
        mode    => 644,
        owner   => root,
        group   => root,
        source  => 'puppet:///modules/thinboot/tgt/thinclient.target.conf',
        require => Package['tgt'],
        notify => Service['tgt'],
    }
    service { 'tgt':
        ensure  => 'running',
        enable  => 'true',
        hasrestart => 'true',
        require => Package['tgt'],
    }
}

