class named (
  $chroot           = false,
  $forwarders       = undef,
  $zonestatistics   = undef,
  $recursion        = 'yes',
  $checknames       = undef,
  $ipv4listen       = [ '127.0.0.1', ],
  $ipv4port         = '53',
  $ipv6listen       = [ '::1', ],
  $ipv6port         = '53',
  $allowquery       = [ 'localhost', ],
  $allowquerycache  = undef,
  $allowtransfer    = undef,
  $dnssec           = true,
  $namedconf        = '/etc/named.conf',
  $querylogfile     = undef,
  $rfc1912enabled   = true,
  $rndcenabled      = false,
  $zones            = undef,
) {

  # Check for supported OSes and set packages to install
  if ($::operatingsystem == 'RedHat' and $::operatingsystemmajrelease == '7') {
    if ($chroot == true) {
      $packages = ['bind-chroot', 'bind', 'bind-utils', 'bind-license', 'bind-libs', 'bind-libs-lite', ]
    } else {
      $packages = ['bind', 'bind-utils', 'bind-license', 'bind-libs', 'bind-libs-lite', ]

      package {'bind-chroot':
        ensure  => absent,
      }
    }
  } else {
    fail("This module supports RedHat 7, you are running $::operatingsystem $::operatingsystemmajrelease")
  }

  # Validate input to module
  validate_bool($chroot)
  if $forwarders != undef {
    validate_array($forwarders)
  }
  if $zonestatistics != undef {
    validate_re($zonestatistics, '^yes$', "named::zonestatistics may either be undef or 'yes' and is set to <${zonestatistics}>.")
  }
  validate_re($recursion, '^(yes|no)$', "named::recursion may either be 'yes' or 'no' and is set to <${recursion}>.")
  if $checknames != undef {
    validate_re($checknames, '^(ignore|warn|fail)', "named::checknames may either be 'ignore', 'warn' or 'fail' and is set to <${checknames}>.")
  }
  validate_array($ipv4listen)
  validate_integer($ipv4port)
  validate_array($ipv6listen)
  validate_integer($ipv6port)
  validate_array($allowquery)
  if $allowquerycache != undef {
    validate_array($allowquerycache)
  }
  if $allowtransfer != undef {
    validate_array($allowtransfer)
  }
  validate_bool($dnssec)
  validate_absolute_path($namedconf)
  if $querylogfile != undef {
    validate_absolute_path($querylogfile)
  }
  validate_bool($rfc1912enabled)
  validate_bool($rndcenabled)

  # The code
  package {$packages:
    ensure  => installed,
  }

  if ($chroot == true) {
    service {'named':
      ensure  => stopped,
      enable  => false,
    }
    service {'named-chroot':
      ensure  => running,
      enable  => true,
      subscribe => File[$namedconf],
    }
  } else {
    service {'named':
      ensure  => running,
      enable  => true,
      subscribe => File[$namedconf],
    }
  } 

  file {$namedconf:
    ensure  => present,
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => template('named/named.conf.erb'),
  }

  if $querylogfile != undef {
    file {'/etc/logrotate.d/named-querylog':
      ensure  => present,
      owner   => 'root',
      group   => 'named',
      mode    => '0640',
      content => template('named/named-querylog.erb'),
    }
  } else {
    file {'/etc/logrotate.d/named-querylog':
      ensure  => absent,
    }
  }
}
