# Puppet manifest
#
# Required modules:
# willdurand/nodejs
# puppetlabs/mongodb
#

# defaults for Exec
Exec {
    path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin", "/usr/local/node/node-default/bin/"],
    user => "root",
}

exec { "apt-get update":
    command => "apt-get update",
    user => "root",
}

package { "build-essential":
    ensure => "installed",
    require => Exec['apt-get update'],
}

package { "openjdk-7-jdk":
    ensure => "installed",
    require => Exec['apt-get update'],
    install_options => ['--no-install-recommends'],
}

package { "maven":
    ensure => "installed",
    install_options => ['--no-install-recommends'],
    require => [ Exec['apt-get update'], Package["openjdk-7-jdk"] ],
}

package { "git":
    ensure => "installed",
    require => Exec['apt-get update'],
}


class { 'mongodb::globals':
    manage_package_repo => true
}

class { "mongodb":
    init => "upstart",
}

class { 'mongodb::client': }

class { "nodejs":
    version => "stable",
    make_install => false,
}

exec { "npm-install":
    cwd => "/openhim-bench",
    timeout => 0,
    command => "npm install",
    require => [ Class["nodejs"], Package["build-essential"] ],
}

exec { "install-grunt":
	command => "npm install -g grunt-cli",
	timeout => 0,
	unless => "npm list -g grunt-cli",
	require => Class["nodejs"],
}

exec { "install-coffee":
    command => "npm install -g coffee-script",
    timeout => 0,
    unless => "npm list -g coffee-script",
    require => Exec["install-grunt"],
}

file { "/usr/lib/jvm/java-7-openjdk-i386/jre/lib/security/jssecacerts":
    source => "/vagrant/jssecacerts",
    require => Package["openjdk-7-jdk"],
}
