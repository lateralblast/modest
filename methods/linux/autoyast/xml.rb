# frozen_string_literal: true

# Do Autoyast XML

# Populate hosts

def populate_ay_hosts(values)
  hosts = []
  hosts.push('127.0.0.1,localhost')
  hosts.push("#{values['ip']},#{values['name']},#{values['name']}.#{values['domainname']}")
  hosts.push('::1,localhost ipv6-localhost ipv6-loopback')
  hosts.push('fe00::0,ipv6-localnet')
  hosts.push('ff00::0,ipv6-mcastprefix')
  hosts.push('ff02::1,ipv6-allnodes')
  hosts.push('ff02::2,ipv6-allrouters')
  hosts.push('ff02::3,ipv6-allhosts')
  hosts
end

# Populate inetd information

def populate_ay_inetd(values)
  inetd = Struct.new(:enabled, :iid, :protocol, :script, :server, :service)

  service = 'chargen'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'chargen-udp'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'udp',
    service,
    '',
    service = 'chargen'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'cups-lpd'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '/usr/lib64/cups/daemon/cups-lpd',
    service = 'printer'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'cvs'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '/usr/bin/cvs',
    service = 'cvspserver'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'daytime'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'daytime-udp'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'udp',
    service,
    '',
    service = 'daytime'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'discard'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'discard-udp'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'udp',
    service,
    '',
    service = 'discard'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'echo'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'echo-udp'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'udp',
    service,
    '',
    service = 'echo-udp'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'netstat'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    "/bin/#{service}",
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'rsync'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    "/usr/sbin/#{service}d",
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'servers'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'services'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'swat'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    "/usr/sbin/#{service}",
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'systat'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '/bin/ps',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'time'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'tcp',
    service,
    '',
    service = service
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  service = 'time-udp'
  config  = inetd.new(
    'false',
    "1:/etc/xinetd.d/#{service}",
    'udp',
    service,
    '',
    service = 'time'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config
  config = inetd.new(
    'false',
    '1:/etc/xinetd.d/vnc',
    'tcp',
    'vnc',
    '/usr/bin/Xvnc',
    service = 'vnc1'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config
  config = inetd.new(
    'false',
    '16:/etc/xinetd.d/vnc',
    'tcp',
    'vnc',
    '/usr/bin/Xvnc',
    service = 'vnc2'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config
  config = inetd.new(
    'false',
    '31:/etc/xinetd.d/vnc3',
    'tcp',
    'vnc',
    '/usr/bin/Xvnc',
    service = 'vnc3'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config
  config = inetd.new(
    'false',
    '46:/etc/xinetd.d/vnc',
    'tcp',
    'vnc',
    '/usr/bin/vnc_inetd_httpd',
    service = 'vnchttpd1'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config
  config = inetd.new(
    'false',
    '61:/etc/xinetd.d/vnchttpd2',
    'tcp',
    'vnc',
    '/usr/bin/vnc_inetd_httpd',
    service = 'vnchttpd2'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config
  config = inetd.new(
    'false',
    '76:/etc/xinetd.d/vnchttpd3',
    'tcp',
    'vnc',
    '/usr/bin/vnc_inetd_httpd',
    service = 'vnchttpd3'
  )
  values['i_order'].push(service)
  values['i_struct'][service] = config

  nil
end

# Populate Group information

def populate_ay_groups(values)
  Struct.new(:gid, :group_password, :groupname, :userlist)

  group  = 'users'
  config = group.new(
    '100',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'floppy'
  config = group.new(
    '19',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'bin'
  config = group.new(
    '1',
    'x',
    group,
    'daemon'
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'xok'
  config = group.new(
    '41',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'nobody'
  config = group.new(
    '65535',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'modem'
  config = group.new(
    '43',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'lp'
  config = group.new(
    '7',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'tty'
  config = group.new(
    '5',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'postfix'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '51',
               'x',
               group,
               ''
             )

           else

             group.new(
               '51',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'uuid'
  config = group.new(
    '104',
    '!',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'gdm'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '485',
               'x',
               group,
               ''
             )

           else

             group.new(
               '111',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'nogroup'
  config = group.new(
    '65534',
    'x',
    group,
    'nobody'
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'maildrop'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '59',
               'x',
               group,
               ''
             )

           else

             group.new(
               '59',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'messagebus'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '499',
               'x',
               group,
               ''
             )

           else

             group.new(
               '101',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'video'
  config = group.new(
    '33',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'sys'
  config = group.new(
    '3',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'shadow'
  config = group.new(
    '15',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'console'
  config = group.new(
    '21',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'cdrom'
  config = group.new(
    '20',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'haldaemon'
  config = group.new(
    '102',
    '!',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'trusted'
  config = group.new(
    '42',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'puppet'
  config = group.new(
    '105',
    '!',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'dialout'
  config = group.new(
    '16',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

    group  = 'polkitd'
    config = group.new(
      '496',
      'x',
      group,
      ''
    )

  else

    group  = 'polkituser'
    config = group.new(
      '106',
      '!',
      group,
      ''
    )

  end
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'pulse'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '489',
               'x',
               group,
               ''
             )

           else

             group.new(
               '100',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'wheel'
  config = group.new(
    '10',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'www'
  config = group.new(
    '8',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'games'
  config = group.new(
    '40',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'disk'
  config = group.new(
    '6',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'audio'
  config = group.new(
    '17',
    'x',
    group,
    'pulse'
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'suse-ncc'
  config = group.new(
    '110',
    '!',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'ftp'
  config = group.new(
    '49',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'at'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '25',
               'x',
               group,
               ''
             )

           else

             group.new(
               '25',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'tape'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '497',
               'x',
               group,
               ''
             )

           else

             group.new(
               '103',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'kmem'
  config = group.new(
    '9',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'public'
  config = group.new(
    '32',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'root'
  config = group.new(
    '0',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'mail'
  config = group.new(
    '12',
    'x',
    group,
    'postfix'
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'daemon'
  config = group.new(
    '2',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'ntp'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '492',
               'x',
               group,
               ''
             )

           else

             group.new(
               '107',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

    group  = 'scard'
    config = group.new(
      '487',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'lock'
    config = group.new(
      '54',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'winbind'
    config = group.new(
      '486',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'vnc'
    config = group.new(
      '491',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'rtkit'
    config = group.new(
      '490',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'systemd-journal'
    config = group.new(
      '493',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'nscd'
    config = group.new(
      '495',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

    group  = 'brlapi'
    config = group.new(
      '494',
      'x',
      group,
      ''
    )
    values['g_order'].push(group)
    values['g_struct'][group] = config

  end

  group  = 'uucp'
  config = group.new(
    '14',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'pulse-access'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '488',
               'x',
               group,
               ''
             )

           else

             group.new(
               '109',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'ntadmin'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '71',
               'x',
               group,
               ''
             )

           else

             group.new(
               '72',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'man'
  config = group.new(
    '62',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'utmp'
  config = group.new(
    '22',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group  = 'news'
  config = group.new(
    '13',
    'x',
    group,
    ''
  )
  values['g_order'].push(group)
  values['g_struct'][group] = config

  group = 'sshd'

  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             group.new(
               '498',
               'x',
               group,
               ''
             )

           else

             group.new(
               '65',
               '!',
               group,
               ''
             )

           end

  values['g_order'].push(group)
  values['g_struct'][group] = config

  values
end

# Populate list of packages to add

def populate_ay_add_packages(values)
  add_packages = []
  case values['service'].to_s
  when /sles_15/
    add_packages.push('openssh')
    add_packages.push('sudo')
    add_packages.push('wget')
  when /sles_12_[1-9]/
    unless values['service'].to_s.match(/sles_12_3/)
      add_packages.push('at-spi-32bit')
      add_packages.push('gdbm-32bit')
      add_packages.push('libcanberra-gtk-32bit')
      add_packages.push('libcanberra-gtk0-32bit')
      add_packages.push('libdb-4_5-32bit')
      add_packages.push('libgstreamer-0_10-0-32bit')
      add_packages.push('libproxy0-config-gnome')
      add_packages.push('libpython2_6-1_0-32bit')
      add_packages.push('librsvg-32bit')
    end
    add_packages.push('cyrus-sasl-32bit')
    add_packages.push('dbus-1-32bit')
    add_packages.push('dbus-1-glib-32bit')
    add_packages.push('libFLAC8-32bit')
    add_packages.push('libbonobo-32bit')
    add_packages.push('libbz2-1-32bit')
    add_packages.push('libcanberra0-32bit')
    add_packages.push('libcroco-0_6-3-32bit')
    add_packages.push('libgsf-1-114-32bit')
    add_packages.push('libgthread-2_0-0-32bit')
    add_packages.push('libidl-32bit')
    add_packages.push('libldap-2_4-2-32bit')
    add_packages.push('libltdl7-32bit')
    add_packages.push('libogg0-32bit')
    add_packages.push('libpulse0-32bit')
    add_packages.push('libsndfile-32bit')
    add_packages.push('libtalloc2-32bit')
    add_packages.push('libtdb1-32bit')
    add_packages.push('libvorbis-32bit')
    add_packages.push('libxml2-32bit')
    add_packages.push('orbit2-32bit')
    add_packages.push('samba-client-32bit')
    add_packages.push('sles-manuals_en')
    add_packages.push('tcpd-32bit')
    add_packages.push('xorg-x11-driver-video-radeonhd')
    add_packages.push('yast2-trans-en_US')
  else
    add_packages.push('syslinux')
    add_packages.push('snapper')
    add_packages.push('sles-release')
    add_packages.push('perl-Bootloader-YAML')
    add_packages.push('kexec-tools')
    add_packages.push('grub2')
    add_packages.push('glibc')
    add_packages.push('e2fsprogs')
    add_packages.push('btrfsprogs')
  end
  add_packages
end

# Populate list of packages to remove

def populate_ay_remove_packages(values)
  remove_packages = []
  remove_packages.push('cups-autoconfig')
  remove_packages.push('cups-drivers')
  remove_packages.push('emacs-nox')
  remove_packages.push('filters')
  remove_packages.push('gutenprint')
  remove_packages.push('libqt4-sql-sqlite')
  remove_packages.push('lprng')
  remove_packages.push('manufacturer-PPDs')
  remove_packages.push('pcmciautils')
  remove_packages.push('portmap')
  remove_packages.push('postfix') if values['service'].to_s.match(/sles_12_0/)
  remove_packages.push('rsyslog')
  remove_packages.push('sendmail')
  remove_packages.push('susehelp_de')
  remove_packages.push('yast2-control-center-qt')
  remove_packages
end

# Populate patterns

def populate_ay_patterns(values)
  patterns = []
  if values['service'].to_s.match(/sles_15/)
    patterns.push('base')
  else
    patterns.push('Minimal')
    patterns.push('base')
    if !values['service'].to_s.match(/sles_12_[1-9]/)
      patterns.push('Basis-Devel')
      unless values['service'].to_s.match(/sles_12/)
        patterns.push('gnome')
        patterns.push('print_server')
      end
    else
      patterns.push('apparmor')
      patterns.push('documentation')
      patterns.push('gnome-basic')
      patterns.push('32bit')
      patterns.push('sles-Minimal-32bit')
      patterns.push('sles-apparmor-32bit')
      patterns.push('sles-base-32bit')
      patterns.push('sles-documentation-32bit')
      patterns.push('sles-x11-32bit')
    end
    patterns.push('x11')
  end
  patterns
end

# Populate users

def populate_ay_users(values)
  Struct.new(:fullname, :gid, :home, :expire, :flag, :inact, :max, :min, :warn, :shell, :uid, :user_password,
             :username)

  user   = values['adminuser']
  config = user.new(
    values['adminname'],
    '100',
    values['adminhome'],
    '',
    '',
    '',
    '99999',
    '0',
    '7',
    values['adminshell'],
    '1000',
    values['answers']['admin_crypt'].value,
    values['adminuser']
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'games'
  config = user.new(
    'Games account',
    '100',
    '/var/games',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '12',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'bin'
  config = user.new(
    'bin',
    '1',
    '/bin',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'nobody'
  config = user.new(
    'nobody',
    '65533',
    '/var/lib/nobody',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '',
    '',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'lp'
  config = user.new(
    'Printing daemon',
    '7',
    '/var/spool/lpd',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '4',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'uuid'
  config = user.new(
    'User for uuid',
    '104',
    '/var/run/uuid',
    '',
    '',
    '',
    '9999',
    '0',
    '7',
    '/bin/false',
    '102',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user = 'postfix'
  config = user.new(
    'Postfix Daemon',
    '51',
    '/var/spool/postfix',
    '',
    '',
    '',
    '99999',
    '0',
    '7',
    '/bin/false',
    '51',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'suse-ncc'
  config = user.new(
    'Novell Customer Center User',
    '110',
    '/var/lib/YaST2/suse-ncc-fakehome',
    '',
    '',
    '',
    '99999',
    '0',
    '7',
    '/bin/bash',
    '106',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'ftp'
  config = user.new(
    'FTP account',
    '49',
    '/srv/ftp',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '40',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user = 'gdm'
  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             user.new(
               'Gnome Display Manager daemon',
               '485',
               '/var/lib/gdm',
               '',
               '',
               '',
               '',
               '',
               '',
               '/bin/false',
               '486',
               '!',
               user
             )

           else

             user.new(
               'Gnome Display Manager daemon',
               '111',
               '/var/lib/gdm',
               '',
               '',
               '',
               '9999',
               '0',
               '7',
               '/bin/bash',
               '107',
               '*',
               user
             )

           end
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'at'
  config = user.new(
    'Batch job daemon',
    '25',
    '/var/spool/atjobs',
    '',
    '',
    '',
    '99999',
    '0',
    '7',
    '/bin/bash',
    '25',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user = 'root'
  config = user.new(
    'root',
    '0',
    '/root',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '0',
    values['answers']['root_crypt'].value,
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'mail'
  config = user.new(
    'Mailer daemon',
    '12',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/false',
    '8',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

    user   = 'openslp'
    config = user.new(
      'openslp daemon',
      '2',
      '/var/lib/empty',
      '',
      '',
      '',
      '',
      '',
      '',
      '/sbin/nologin',
      '494',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'usbmuxd'
    config = user.new(
      'usbmuxd daemon',
      '65534',
      '/var/lib/usbmuxd',
      '',
      '',
      '',
      '',
      '',
      '',
      '/sbin/nologin',
      '493',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'statd'
    config = user.new(
      'NFS statd daemon',
      '65534',
      '/var/lib/nfs',
      '',
      '',
      '',
      '',
      '',
      '',
      '/sbin/nologin',
      '484',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'scard'
    config = user.new(
      'Smart Card Reader',
      '487',
      '/var/run/pcscd',
      '',
      '',
      '',
      '',
      '',
      '',
      '/usr/sbin/nologin',
      '487',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'vnc'
    config = user.new(
      'user for VNC',
      '491',
      '/var/lib/empty',
      '',
      '',
      '',
      '',
      '',
      '',
      '/sbin/nologin',
      '492',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'sshd'
    config = user.new(
      'SSH daemon',
      '498',
      '/var/lib/sshd',
      '',
      '',
      '',
      '',
      '',
      '',
      '/bin/false',
      '498',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'nscd'
    config = user.new(
      'User for nscd',
      '495',
      '/run/nscd',
      '',
      '',
      '',
      '',
      '',
      '',
      '/sbin/nologin',
      '496',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'rtkit'
    config = user.new(
      'RealtimeKit',
      '490',
      '/proc',
      '',
      '',
      '',
      '',
      '',
      '',
      '/bin/false',
      '490',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'ftpsecure'
    config = user.new(
      'Secure FTP User',
      '65534',
      '/var/lib/empty',
      '',
      '',
      '',
      '',
      '',
      '',
      '/bin/false',
      '488',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

    user   = 'rpc'
    config = user.new(
      'user for rpcbind',
      '65534',
      '/var/lib/empty',
      '',
      '',
      '',
      '',
      '',
      '',
      '/bin/false',
      '495',
      '!',
      user
    )
    values['u_struct'][user] = config
    values['u_order'].push(user)

  end

  user   = 'daemon'
  config = user.new(
    'Daemon',
    '2',
    '/sbin',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '2',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'ntp'
  config = user.new(
    'NTP daemon',
    '107',
    '/var/lib/ntp',
    '',
    '',
    '',
    '99999',
    '0',
    '7',
    '/bin/false',
    '74',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'uucp'
  config = user.new(
    'Unix-to-Unix CoPy system',
    '14',
    '/etc/uucp',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '10',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user = 'messagebus'
  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             user.new(
               'User for D-Bus',
               '499',
               '/var/run/dbus',
               '',
               '',
               '',
               '',
               '',
               '',
               '/bin/false',
               '499',
               '!',
               user
             )

           else

             user.new(
               'User for D-Bus',
               '101',
               '/var/run/dbus',
               '',
               '',
               '',
               '',
               '0',
               '7',
               '/bin/false',
               '100',
               '*',
               user
             )

           end
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'haldaemon'
  config = user.new(
    'User for haldaemon',
    '102',
    '/var/run/hald',
    '',
    '',
    '',
    '',
    '0',
    '7',
    '/bin/false',
    '101',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'wwwrun'
  config = user.new(
    'WWW daemon apache',
    '8',
    '/var/lib/wwwrun',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/false',
    '30',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'puppet'
  config = user.new(
    'Puppet daemon',
    '105',
    '/var/lib/puppet',
    '',
    '',
    '',
    '99999',
    '0',
    '7',
    '/bin/false',
    '103',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'man'
  config = user.new(
    'Manual pages viewer',
    '62',
    '/var/cache/man',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/bash',
    '13',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

    user   = 'polkitd'
    config = user.new(
      'User for polkitd',
      '496',
      '/var/lib/polkitd',
      '',
      '',
      '',
      '',
      '',
      '',
      '/sbin/nologin',
      '497',
      '*',
      user
    )

  else

    user   = 'polkituser'
    config = user.new(
      'PolicyKit',
      '106',
      '/var/run/PolicyKit',
      '',
      '',
      '',
      '99999',
      '0',
      '7',
      '/bin/false',
      '104',
      '*',
      user
    )

  end
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user   = 'news'
  config = user.new(
    'News system',
    '13',
    '/etc/news',
    '',
    '',
    '',
    '',
    '',
    '',
    '/bin/false',
    '9',
    '*',
    user
  )
  values['u_struct'][user] = config
  values['u_order'].push(user)

  user = 'pulse'
  config = if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)

             user.new(
               'PulseAudio daemon',
               '489',
               '/var/lib/pulseaudio',
               '',
               '',
               '',
               '',
               '',
               '',
               '/sbin/nologin',
               '489',
               '*',
               user
             )

           else

             user.new(
               'PulseAudio daemon',
               '100',
               '/var/lib/pulseaudio',
               '',
               '',
               '',
               '99999',
               '0',
               '7',
               '/bin/false',
               '105',
               '*',
               user
             )

           end
  values['u_struct'][user] = config
  values['u_order'].push(user)

  values
end

# Populate disabled http modules

def populate_ay_disabled_http_modules(_values)
  disabled_http_modules = []
  disabled_http_modules.push('authz_host')
  disabled_http_modules.push('actions')
  disabled_http_modules.push('alias')
  disabled_http_modules.push('auth_basic')
  disabled_http_modules.push('authn_file')
  disabled_http_modules.push('authz_user')
  disabled_http_modules.push('authz_groupfile')
  disabled_http_modules.push('autoindex')
  disabled_http_modules.push('cgi')
  disabled_http_modules.push('dir')
  disabled_http_modules.push('include')
  disabled_http_modules.push('log_config')
  disabled_http_modules.push('mime')
  disabled_http_modules.push('negotiation')
  disabled_http_modules.push('setenvif')
  disabled_http_modules.push('status')
  disabled_http_modules.push('userdir')
  disabled_http_modules.push('asis')
  disabled_http_modules.push('imagemap')
  disabled_http_modules
end

# Populate enabled http modules

def populate_ay_enabled_http_modules(_values)
  []
end

# Populate services to disable

def populate_ay_disabled_services(_values)
  disabled_services = []
  disabled_services.push('display_manager')
  disabled_services
end

# Populate services to enable

def populate_ay_enabled_services(_values)
  enabled_services = []
  enabled_services.push('btrfsmaintenance-refresh')
  enabled_services.push('cron')
  enabled_services.push('getty@tty1')
  enabled_services.push('haveged')
  enabled_services.push('irqbalance')
  enabled_services.push('iscsi')
  enabled_services.push('nscd')
  enabled_services.push('ntpd')
  enabled_services.push('postfix')
  enabled_services.push('purge-kernels')
  enabled_services.push('rollback')
  enabled_services.push('rsyslog')
  enabled_services.push('smartd')
  enabled_services.push('sshd')
  enabled_services.push('SuSEfirewall2')
  enabled_services.push('SuSEfirewall2_init')
  enabled_services.push('systemd-readahead-collect')
  enabled_services.push('systemd-readahead-replay')
  enabled_services.push('vmtoolsd')
  enabled_services.push('wicked')
  enabled_services.push('wickedd-auto4')
  enabled_services.push('wickedd-dhcp4')
  enabled_services.push('wickedd-dhcp6')
  enabled_services.push('wickedd-nanny')
  enabled_services.push('YaST2-Firstboot')
  enabled_services.push('YaST2-Second-Stage')
  enabled_services
end

# Output client profile file

def output_ay_client_profile(values, output_file)
  values = populate_ay_users(values)
  values = populate_ay_groups(values)
  values = populate_ay_inetd(values)
  gateway = get_ipv4_default_route(values)
  hosts   = populate_ay_hosts(values)
  xml_output = []
  add_packages    = populate_ay_add_packages(values)
  remove_packages = populate_ay_remove_packages(values)
  patterns        = populate_ay_patterns(values)
  disabled_services = populate_ay_disabled_services(values)
  enabled_services  = populate_ay_enabled_services(values)
  disabled_http_modules = populate_ay_disabled_http_modules(values)
  enabled_http_modules  = populate_ay_enabled_http_modules(values)
  xml = Builder::XmlMarkup.new(target: xml_output, indent: 2)
  xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
  xml.declare! :DOCTYPE, :profile
  xml.profile(xmlns: 'http://www.suse.com/1.0/yast2ns', "xmlns:config": 'http://www.suse.com/1.0/configns') do
    xml.tag!('add-on') do
      xml.add_on_products("config:type": 'list') do
        if values['service'].to_s.match(/sles_15/)
          xml.listentry do
            xml.media_url { xml.declare! :"[CDATA[dvd:///?devices=/dev/sr0]]" }
            #            xml.product("base")
            xml.product_dir('/Module-Basesystem')
          end
        end
      end
    end
    xml.tag!('audit-laf') do
      xml.auditd do
        xml.action_mail_acct('root')
        xml.admin_space_left('50')
        xml.admin_space_left_action('SUSPEND')
        xml.disk_error_action('SUSPEND')
        xml.disk_full_action('SUSPEND')
        xml.disp_qos('lossy')
        xml.dispatcher('/sbin/audispd')
        xml.flush('INCREMENTAL')
        xml.freq('20')
        xml.log_file('/var/log/audit/audit.log')
        xml.log_format('RAW')
        xml.log_group('root')
        xml.max_log_file('5')
        xml.max_log_file_action('ROTATE')
        xml.name_format('NONE')
        xml.num_logs('4')
        xml.priority_boost('4')
        xml.space_left('75')
        xml.space_left_action('SYSLOG')
        xml.tcp_client_max_idle('0')
        xml.tcp_listen_queue('5')
        xml.tcp_max_per_addr('1') if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      end
      xml.rules do
        xml.text!("# First rule - delete all\n")
        xml.text!("-D\n")
        xml.text!("# Make this bigger for busy systems\n")
        xml.text!("-b 320\n")
      end
    end
    xml.bootloader do
      xml.device_map("config:type": 'list') do
        unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.device_map_entry do
            xml.firmware('fd0')
            xml.linux('/dev/fd0')
          end
        end
        xml.device_map_entry do
          xml.firmware('hd0')
          xml.linux('/dev/sda')
        end
      end
      xml.global do
        xml.activate('true')
        if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.append('resume=/dev/sda1 splash=silent quiet showopts')
          xml.append_failsafe('single')
        end
        xml.boot_root('true')
        if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.cryptodisk('0', "config:type": 'integer')
          xml.default('SLES 12-SP1')
          xml.distributor
          xml.failsafe_disabled('true')
          xml.generic_mbr('true')
          xml.gfxbackground('/boot/grub2/themes/SLE/background.png')
          xml.gfxmode('auto')
          xml.gfxtheme('/boot/grub2/themes/SLE/theme.txt')
          xml.hiddenmenu('false')
          xml.os_prober('false')
          xml.suse_btrfs('true')
          xml.terminal('gfxterm')
        else
          xml.default('SUSE Linux Enterprise Server')
          xml.generic_mbr('true')
          xml.gfxmenu('/boot/message')
          xml.lines_cache_id('3')
        end
        xml.timeout('8', "config:type": 'integer')
      end
      unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.initrd_modules("config:type": 'list') do
          xml.initrd_module do
            xml.module('mptspi')
          end
          xml.initrd_module do
            xml.module('ahci')
          end
          xml.initrd_module do
            xml.module('ata_piix')
          end
          xml.initrd_module do
            xml.module('ata_generic')
          end
          xml.initrd_module do
            xml.module('vmxnet3')
          end
          xml.initrd_module do
            xml.module('vmw_pvscsi')
          end
          xml.initrd_module do
            xml.module('vmxnet')
          end
        end
      end
      if values['service'].to_s.match(/sles_12|sles_15/)
        xml.loader_type('grub2')
      else
        xml.loader_type('grub')
      end
      unless values['service'].to_s.match(/sles_12|sles_15/)
        xml.sections("config:type": 'list') do
          # xml.section {
          #  xml.append("resume=/dev/sda1 splash=silent showopts")
          #  xml.image("/boot/vmlinuz-3.0.13-0.27-default")
          #  xml.initial("1")
          #  xml.initrd("/boot/initrd-3.0.13-0.27-default")
          #  xml.lines_cache_id("0")
          #  xml.name("SUSE Linux Enterprise Server 11 SP2 - 3.0.13-0.27")
          #  xml.original_name("linux")
          #  xml.root("/dev/sda2")
          #  xml.type("image")
          # }
          # xml.section {
          #  xml.append("showopts ide=nodma apm=off noresume edd=off powersaved=off nohz=off highres=off processor.max_cstate=1 nomodeset x11failsafe")
          #  xml.image("/boot/vmlinuz-3.0.13-0.27-default")
          #  xml.initrd("/boot/initrd-3.0.13-0.27-default")
          #  xml.lines_cache_id("1")
          #  xml.name("Failsafe -- SUSE Linux Enterprise Server 11 SP2 - 3.0.13-0.27")
          #  xml.original_name("failsafe")
          #  xml.root("/dev/sda2")
          #  xml.type("image")
          # }
          # xml.section {
          #  xml.blockoffset("1")
          #  xml.chainloader("/dev/fd0")
          #  xml.lines_cache_id("2")
          #  xml.name("Floppy")
          #  xml.noverifyroot("true")
          #  xml.original_name("floppy")
          #  xml.root
          #  xml.type("other")
          # }
        end
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.ca_mgm do
        xml.CAName('YaST_Default_CA')
        xml.ca_commonName('YaST Default CA (site)')
        xml.country(values['country'])
        xml.importCertificate('false', 'config:type': 'boolean')
        xml.locality
        xml.organisation
        xml.organisationUnit
        xml.password(values['adminpassword'])
        xml.server_commonName(values['name'])
        xml.server_email('postmaster@site')
        xml.state
        xml.takeLocalServerName('true', 'config:type': 'boolean')
      end
    end
    xml.deploy_image do
      xml.image_installation('false', 'config:type': 'boolean')
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.tag!('dhcp-server') do
        xml.allowed_interfaces("config:type": 'list')
        xml.chroot('1')
        xml.other_values
        xml.settings("config:type": 'list') do
          xml.settings_entry do
            xml.children("config:type": 'list')
            xml.directives("config:type": 'list')
            xml.id
            xml.values("config:type": 'list')
            xml.parent_id
            xml.parent_type
            xml.type
          end
        end
        xml.start_service('0')
        xml.use_ldap('0')
      end
      xml.tag!('dns-server') do
        xml.allowed_interfaces("config:type": 'list')
        xml.chroot('1')
        xml.logging("config:type": 'list')
        xml.values("config:type": 'list') do
          xml.option do
            xml.key('forwarders')
            xml.value
          end
        end
        xml.start_service('0')
        xml.use_ldap('0')
        xml.zones("config:type": 'list')
      end
    end
    xml.firewall do
      if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.FW_ALLOW_FW_BROADCAST_DMZ('no')
        xml.FW_ALLOW_FW_BROADCAST_EXT('no')
        xml.FW_ALLOW_FW_BROADCAST_INT('no')
        xml.FW_BOOT_FULL_INIT
        xml.FW_CONFIGURATIONS_DMZ
        xml.FW_CONFIGURATIONS_EXT
        xml.FW_CONFIGURATIONS_INT
      end
      xml.FW_DEV_DMZ
      xml.FW_DEV_EXT
      xml.FW_DEV_INT
      if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.FW_FORWARD_ALWAYS_INOUT_DEV
        xml.FW_FORWARD_MASQ
        xml.FW_IGNORE_FW_BROADCAST_DMZ('no')
        xml.FW_IGNORE_FW_BROADCAST_EXT('yes')
        xml.FW_IGNORE_FW_BROADCAST_INT('no')
        xml.FW_IPSEC_TRUST('no')
        xml.FW_LOAD_MODULES('nf_conntrack_netbios_ns')
        xml.FW_LOG_ACCEPT_ALL('no')
        xml.FW_LOG_ACCEPT_CRIT('yes')
        xml.FW_LOG_DROP_ALL('no')
        xml.FW_LOG_DROP_CRIT('yes')
        xml.FW_MASQUERADE('no')
        xml.FW_PROTECT_FROM_INT('no')
        xml.FW_ROUTE('no')
        xml.FW_SERVICES_ACCEPT_DMZ
        xml.FW_SERVICES_ACCEPT_EXT
        xml.FW_SERVICES_ACCEPT_INT
        xml.FW_SERVICES_ACCEPT_RELATED_DMZ
        xml.FW_SERVICES_ACCEPT_RELATED_EXT
        xml.FW_SERVICES_ACCEPT_RELATED_INT
        xml.FW_SERVICES_DMZ_IP
        xml.FW_SERVICES_DMZ_RPC
        xml.FW_SERVICES_DMZ_TCP
        xml.FW_SERVICES_DMZ_UDP
        xml.FW_SERVICES_EXT_IP
        xml.FW_SERVICES_EXT_RPC
        xml.FW_SERVICES_EXT_TCP
        xml.FW_SERVICES_EXT_UDP
        xml.FW_SERVICES_INT_IP
        xml.FW_SERVICES_INT_RPC
        xml.FW_SERVICES_INT_TCP
        xml.FW_SERVICES_INT_UDP
        xml.FW_STOP_KEEP_ROUTING_STATE('no')
      end
      xml.enable_firewall('false', 'config:type': 'boolean')
      xml.start_firewall('false', 'config:type': 'boolean')
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.tag!('ftp-server') do
        xml.AnonAuthen('1')
        xml.AnonCreatDirs('NO')
        xml.AnonMaxRate('0')
        xml.AnonReadOnly('YES')
        xml.AntiWarez('YES')
        xml.Banner('Welcome message')
        xml.CertFile
        xml.ChrootEnable('NO')
        xml.EnableUpload('NO')
        xml.FTPUser('ftp')
        xml.FtpDirAnon('/srv/ftp')
        xml.FtpDirLocal
        xml.GuestUser
        xml.LocalMaxRate('0')
        xml.MaxClientsNumber('10')
        xml.MaxClientsPerIP('3')
        xml.MaxIdleTime('15')
        xml.PasMaxPort('40500')
        xml.PasMinPort('40000')
        xml.PassiveMode('YES')
        xml.SSL('0')
        xml.SSLEnable('NO')
        xml.SSLv2('NO')
        xml.SSLv3('NO')
        xml.StartDaemon('0')
        xml.StartXinetd('NO')
        xml.TLS('YES')
        xml.Umask
        xml.UmaskAnon
        xml.UmaskLocal
        xml.VerboseLogging('NO')
        xml.VirtualUser('NO')
      end
    end
    xml.general do
      xml.tag!('ask-list', "config:type": 'list')
      xml.mode do
        xml.halt('false', "config:type": 'boolean')
        xml.confirm('false', "config:type": 'boolean')
      end
      unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.mouse do
          xml.id('none')
        end
        xml.proposals("config:type": 'list')
        xml.tag!('signature-handling') do
          xml.accept_file_without_checksum('true', "config:type": 'boolean')
          xml.accept_non_trusted_gpg_key('true', "config:type": 'boolean')
          xml.accept_unknown_gpg_key('true', "config:type": 'boolean')
          xml.accept_unsigned_file('true', "config:type": 'boolean')
          xml.accept_verification_failed('false', "config:type": 'boolean')
          xml.import_gpg_key('true', "config:type": 'boolean')
        end
        xml.storage
      end
    end
    xml.groups("config:type": 'list') do
      values['g_order'].each do |group|
        xml.group do
          xml.encrypted('true', "config:type": 'boolean')
          xml.gid(values['g_struct'][group].gid)
          xml.group_password(values['g_struct'][group].group_password)
          xml.groupname(values['g_struct'][group].groupname)
          if values['g_struct'][group].userlist.match(/[a-z]/)
            xml.userlist(values['g_struct'][group].userlist)
          else
            xml.userlist
          end
        end
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.host do
        xml.hosts("config:type": 'list') do
          hosts.each do |host|
            xml.hosts_entry do
              (host_address, name) = host.split(/,/)
              xml.host_address(host_address)
              xml.names("config:type": 'list') do
                xml.name(name)
              end
            end
          end
        end
      end
      xml.tag!('http-server') do
        xml.Listen("config:type": 'list')
        xml.hosts("config:type": 'list')
        xml.modules("config:type": 'list') do
          disabled_http_modules.each do |name|
            xml.module_entry do
              xml.change('disable')
              xml.default('1')
              xml.name(name)
            end
          end
          enabled_http_modules.each do |name|
            xml.module_entry do
              xml.change('enabled')
              xml.default('1')
              xml.name(name)
            end
          end
        end
      end
      xml.inetd do
        xml.last_created('0', "config:type": 'integer')
        xml.netd_conf("config:type": 'list') do
          values['i_order'].each do |service|
            xml.conf do
              xml.enabled(values['i_struct'][service].enabled, "config:type": 'boolean')
              xml.iid(values['i_struct'][service].iid)
              xml.protocol(values['i_struct'][service].protocol)
              xml.script(values['i_struct'][service].script)
              xml.server(values['i_struct'][service].server)
              xml.service(values['i_struct'][service].service)
            end
          end
        end
      end
      xml.tag!('iscsi-client') do
        xml.initiatorname
        xml.targets("config:type": 'list')
        xml.version('1.0')
      end
    end
    xml.kdump do
      xml.add_crash_kernel('false', "config:type": 'boolean')
      if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.crash_kernel('128M,high')
      else
        xml.crash_kernel('128M-:64M')
      end
      xml.general do
        xml.KDUMPTOOL_FLAGS unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.KDUMP_COMMANDLINE
        xml.KDUMP_COMMANDLINE_APPEND
        xml.KDUMP_CONTINUE_ON_ERROR('false') unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.KDUMP_COPY_KERNEL('yes')
        xml.KDUMP_DUMPFORMAT('compressed')
        if !values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.KDUMP_DUMPLEVEL('0')
        else
          xml.KDUMP_DUMPLEVEL('31')
        end
        xml.KDUMP_FREE_DISK_SIZE('64')
        xml.KDUMP_HOST_KEY unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.KDUMP_IMMEDIATE_REBOOT('yes')
        xml.KDUMP_KEEP_OLD_DUMPS('5')
        xml.KDUMP_KERNELVER
        xml.KDUMP_NETCONFIG('auto') unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.KDUMP_NOTIFICATION_CC
        xml.KDUMP_NOTIFICATION_TO
        unless values['service'].to_s.match(/sles_12_[1-3]|sles_15/)
          xml.KDUMP_POSTSCRIPT
          xml.KDUMP_PRESCRIPT
          xml.KDUMP_REQUIRED_PROGRAMS
        end
        xml.KDUMP_SAVEDIR('file:///var/crash')
        xml.KDUMP_SMTP_PASSWORD
        xml.KDUMP_SMTP_SERVER
        xml.KDUMP_SMTP_USER
        xml.KDUMP_TRANSFER
        xml.KDUMP_VERBOSE('3')
        xml.KEXEC_values
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.kerberos do
        xml.kerberos_client do
          xml.ExpertSettings do
            xml.external('sshd')
            xml.use_shmem('sshd')
          end
          xml.clockskew('300')
          xml.default_domain('site')
          xml.default_realm('SITE')
          xml.forwardable('true', "config:type": 'boolean')
          xml.ignore_unknown('true', "config:type": 'boolean')
          xml.kdc_server
          xml.minimum_uid('1')
          xml.proxiable('false', "config:type": 'boolean')
          xml.renew_lifetime('1d')
          xml.ssh_support('false', "config:type": 'boolean')
          xml.ticket_lifetime('1d')
        end
        xml.pam_login do
          xml.sssd('false', "config:type": 'boolean')
          xml.use_kerberos('false', "config:type": 'boolean')
        end
      end
    end
    xml.keyboard do
      xml.keymap('english-us')
    end
    xml.language do
      xml.language(values['language'])
      if values['service'].to_s.match(/sles_12_[1-3]|sles_15/)
        xml.languages
      else
        xml.languages(values['language'])
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-3]|sles_15/)
      xml.ldap do
        xml.base_config_dn
        xml.bind_dn
        xml.create_ldap('false', "config:type": 'boolean')
        xml.file_server('false', "config:type": 'boolean')
        xml.ldap_domain('dc=example,dc=com')
        xml.ldap_server('127.0.0.1')
        xml.ldap_tls('true', "config:type": 'boolean')
        xml.ldap_v2('false', "config:type": 'boolean')
        xml.login_enabled('true', "config:type": 'boolean')
        xml.member_attribute('member')
        xml.mkhomedir('false', "config:type": 'boolean')
        xml.pam_password('exop')
        xml.sssd('false', "config:type": 'boolean')
        xml.start_autofs('false', "config:type": 'boolean')
        xml.start_ldap('false', "config:type": 'boolean')
      end
    end
    xml.login_settings
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.mail do
        xml.aliases("config:type": 'list') do
          values['u_order'].each do |user|
            xml.alias do
              xml.alias(user)
              xml.comment
              xml.destinations('root')
            end
          end
        end
        xml.connection_type('permanent', "config:type": 'symbol')
        xml.listen_remote('false', "config:type": 'boolean')
        xml.mta('postfix', "config:type": 'symbol')
        xml.postfix_mda('local', "config:type": 'symbol')
        xml.smtp_use_TLS('no')
        xml.use_amavis('false', "config:type": 'boolean')
        xml.use_dkim('false', "config:type": 'boolean')
      end
    end
    xml.networking do
      unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.dhcp_values do
          xml.dhclient_client_id
          xml.dhclient_hostname_option('AUTO')
        end
      end
      xml.dns do
        xml.dhcp_hostname('false', "config:type": 'boolean')
        xml.domain(values['domainname'])
        xml.hostname(values['name'])
        xml.nameservers("config:type": 'list') do
          xml.nameserver(values['nameserver'])
        end
        xml.resolv_conf_policy('auto')
        if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.searchlist("config:type": 'list') do
            xml.search(values['domainname'])
          end
        end
        xml.write_hostname('false', "config:type": 'boolean')
      end
      xml.interfaces("config:type": 'list') do
        xml.interface do
          xml.bootproto('static')
          if values['service'].to_s.match(/sles_11/)
            xml.device('eth1') if values['answers']['nic'].value.match(/eth0/)
          else
            xml.device(values['answers']['nic'].value)
          end
          xml.firewall('no')
          xml.ipaddr(values['ip'])
          xml.netmask(values['netmask'])
          xml.startmode('auto')
          xml.usercontrol('no') unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        end
        xml.interface do
          if !values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
            xml.aliases do
              xml.alias2 do
                xml.IPADDR('127.0.0.2')
                xml.NETMASK('255.0.0.0')
                xml.PREFIXLEN('8')
              end
            end
          else
            xml.bootproto('static')
          end
          xml.broadcast('127.255.255.255')
          xml.device('lo')
          xml.firewall('no')
          xml.ipaddr('127.0.0.1')
          xml.netmask('255.0.0.0')
          xml.network('127.0.0.0')
          xml.prefixlen('8')
          if !values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
            xml.startmode('auto')
          else
            xml.startmode('nfsroot')
          end
          xml.usercontrol('no')
        end
      end
      if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.ipv6('true', "config:type": 'boolean')
        xml.keep_install_network('false', "config:type": 'boolean')
      end
      xml.managed('false', "config:type": 'boolean')
      xml.tag!('net-udev', "config:type": 'list') do
        xml.rule do
          xml.name(values['answers']['nic'].value)
          xml.rule('ATTR{address}')
          xml.value(values['mac'])
        end
      end
      xml.routing do
        if !values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.ip_forward('false', "config:type": 'boolean')
          xml.routes("config:type": 'list') do
            xml.route do
              xml.destination('default')
              xml.device('-')
              xml.gateway(gateway)
              xml.netmask('-')
            end
          end
        else
          xml.ipv4_forward('false', "config:type": 'boolean')
          xml.ipv6_forward('false', "config:type": 'boolean')
        end
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.nfs_server do
        xml.nfs_exports("config:type": 'list')
        xml.start_nfsserver('false', "config:type": 'boolean')
      end
      xml.nis do
        xml.netconfig_policy('auto')
        xml.nis_broadcast('false', "config:type": 'boolean')
        xml.nis_broken_server('false', "config:type": 'boolean')
        xml.nis_domain
        xml.nis_local_only('false', "config:type": 'boolean')
        xml.nis_values
        xml.nis_other_domains("config:type": 'list')
        xml.nis_servers("config:type": 'list')
        xml.slp_domain
        xml.start_autofs('false', "config:type": 'boolean')
        xml.start_nis('false', "config:type": 'boolean')
      end
      xml.nis_server do
        xml.domain
        xml.maps_to_serve("config:type": 'list')
        xml.merge_passwd('false', "config:type": 'boolean')
        xml.mingid('0', "config:type": 'integer')
        xml.minuid('0', "config:type": 'integer')
        xml.nopush('false', "config:type": 'boolean')
        xml.pwd_chfn('false', "config:type": 'boolean')
        xml.pwd_chsh('false', "config:type": 'boolean')
        xml.pwd_srcdir('/etc')
        xml.securenets("config:type": 'list') do
          xml.securenet do
            xml.netmask('255.0.0.0')
            xml.network('127.0.0.0')
          end
        end
        xml.server_type('none')
        xml.slaves("config:type": 'list')
        xml.start_ypbind('false', "config:type": 'boolean')
        xml.start_yppasswdd('false', "config:type": 'boolean')
        xml.start_ypxfrd('false', "config:type": 'boolean')
      end
      values['timezone'] = 'Australia/Melbourne' if values['service'].to_s.match(/sles_12_[1-9]|sles_15/) && values['timezone'].to_s.match(/Victoria/)
      xml.tag!('ntp-client') do
        xml.ntp_policy('auto')
        xml.peers("config:type": 'list') do
          xml.peer do
            xml.address($default_timeserver)
            xml.fudge_oprions(' stratum 10')
            xml.values
            xml.type('__clock')
          end
          xml.peer do
            xml.address('var/lib/ntp/drift/ntp.drift ')
            xml.type('driftfile')
          end
          xml.peer do
            xml.address('/var/log/ntp   ')
            xml.values
            xml.type('logfile')
          end
          xml.peer do
            xml.address('etc/ntp.keys   ')
            xml.questions
            xml.type('keys')
          end
          xml.peer do
            xml.address('1      ')
            xml.values
            xml.type('trustedkey')
          end
          xml.peer do
            xml.address('1      ')
            xml.values
            xml.type('requestkey')
          end
        end
        xml.start_at_boot('false', "config:type": 'boolean')
        xml.start_in_chroot('true', "config:type": 'boolean')
      end
    end
    xml.partitioning("config:type": 'list') do
      xml.drive do
        xml.device('/dev/sda')
        if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
          xml.disklabel('msdos')
          xml.enable_snapshots('true', "config:type": 'boolean')
        end
        xml.initialize('true', "config:type": 'boolean')
        xml.partitions("config:type": 'list') do
          xml.partition do
            xml.create('true', "config:type": 'boolean')
            xml.crypt_fs('false', "config:type": 'boolean')
            xml.filesystem('swap', "config:type": 'symbol')
            xml.format('true', "config:type": 'boolean')
            xml.fstopt('defaults')
            xml.loop_fs('false', "config:type": 'boolean')
            xml.mount('swap')
            if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
              xml.mountby('uuid', "config:type": 'symbol')
            else
              xml.mountby('device', "config:type": 'symbol')
            end
            xml.partition_id('130', "config:type": 'integer')
            xml.partition_nr('1', "config:type": 'integer')
            xml.raid_values unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
            xml.resize('false', "config:type": 'boolean')
            swap_size = Integer(values['answers']['swapmax'].value) * 1000 * 1000
            swap_size = swap_size.to_s
            xml.size(swap_size)
          end
          xml.partition do
            xml.create('true', "config:type": 'boolean')
            xml.crypt_fs('false', "config:type": 'boolean')
            if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
              xml.filesystem('btrfs', "config:type": 'symbol')
              xml.format('true', "config:type": 'boolean')
              xml.fstopt('defaults')
            else
              xml.filesystem('ext3', "config:type": 'symbol')
              xml.format('true', "config:type": 'boolean')
              xml.fstopt('acl,user_xattr')
            end
            xml.loop_fs('false', "config:type": 'boolean')
            xml.mount('/')
            if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
              xml.mountby('uuid', "config:type": 'symbol')
            else
              xml.mountby('device', "config:type": 'symbol')
            end
            xml.partition_id('131', "config:type": 'integer')
            xml.partition_nr('2', "config:type": 'integer')
            xml.raid_values unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
            xml.resize('false', "config:type": 'boolean')
            root_size = Integer(values['answers']['rootsize'].value) * 1000 * 1000 * 10
            root_size = root_size.to_s
            xml.size(root_size)
            if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
              xml.subvolumes("config:type": 'list') do
                xml.listentry('@')
                xml.listentry('boot/grub2/i386-pc')
                xml.listentry('boot/grub2/x86_64-efi')
                xml.listentry('home')
                xml.listentry('opt')
                xml.listentry('srv')
                xml.listentry('tmp')
                xml.listentry('usr/local')
                xml.listentry('var/crash')
                xml.listentry('var/lib/libvirt/images')
                xml.listentry('var/lib/mailman')
                xml.listentry('var/lib/mariadb')
                xml.listentry('var/lib/mysql')
                xml.listentry('var/lib/named')
                xml.listentry('var/lib/pgsql')
                xml.listentry('var/log')
                xml.listentry('var/opt')
                xml.listentry('var/spool')
                xml.listentry('var/tmp')
              end
            end
          end
        end
        xml.pesize
        xml.type('CT_DISK', "config:type": 'symbol')
        xml.use('all')
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.tag!('power-management') do
        xml.global_settings do
          xml.SCHEME
        end
        xml.schemes("config:type": 'list') do
          xml.schema do
            xml.CPUFREQ_GOVERNOR('ondemand')
          end
          xml.schema do
            xml.CPUFREQ_GOVERNOR('performance')
          end
          xml.schema do
            xml.CPUFREQ_GOVERNOR('ondemand')
          end
        end
      end
      xml.printer do
      end
      xml.proxy do
      end
      xml.report do
        xml.errors do
          xml.log('true', "config:type": 'boolean')
          xml.show('false', "config:type": 'boolean')
          xml.timeout('0', "config:type": 'integer')
        end
        xml.messages do
          xml.log('true', "config:type": 'boolean')
          xml.show('true', "config:type": 'boolean')
          xml.timeout('0', "config:type": 'integer')
        end
        xml.warnings do
          xml.log('true', "config:type": 'boolean')
          xml.show('true', "config:type": 'boolean')
          xml.timeout('0', "config:type": 'integer')
        end
        xml.yesno_messages do
          xml.log('true', "config:type": 'boolean')
          xml.show('true', "config:type": 'boolean')
          xml.timeout('0', "config:type": 'integer')
        end
      end
      xml.runlevel do
        xml.default('5')
        disabled_services.each do |name|
          xml.service do
            xml.install_service(name)
            xml.service_status('disabled')
          end
        end
      end
      xml.tag!('samba-server') do
      end
      xml.security do
        xml.console_shutdown('reboot')
        xml.cracklib_dict_path('/usr/lib/cracklib_dict')
        xml.cwd_in_root_path('no')
        xml.cwd_in_user_path('no')
        xml.disable_restart_on_update('no')
        xml.disable_stop_on_removal('no')
        xml.displaymanager_remote_access('no')
        xml.displaymanager_root_login_remote('no')
        xml.displaymanager_shutdown('root')
        xml.displaymanager_xserver_tcp_port_6000_open('no')
        xml.enable_sysrq('176')
        xml.fail_delay('3')
        xml.gid_max('60000')
        xml.gid_min('1000')
        xml.group_encryption('md5')
        xml.ip_forward('no')
        xml.ip_tcp_syncookies('yes')
        xml.ipv6_forward('no')
        xml.lastlog_enab('yes')
        xml.obscure_checks_enab('yes')
        xml.pass_max_days('99999')
        xml.pass_min_days('0')
        xml.pass_min_len('5')
        xml.pass_warn_age('7')
        xml.passwd_encryption('blowfish')
        xml.passwd_remember_history('0')
        xml.passwd_use_cracklib('yes')
        xml.permission_security('easy')
        xml.run_updatedb_as
        xml.runlevel3_extra_services('insecure')
        xml.runlevel3_mandatory_services('insecure')
        xml.runlevel5_extra_services('insecure')
        xml.runlevel5_mandatory_services('insecure')
        xml.smtpd_listen_remote('no')
        xml.syslog_on_no_error('no')
        xml.system_gid_max('499')
        xml.system_gid_min('100')
        xml.system_uid_max('499')
        xml.system_uid_min('100')
        xml.systohc('yes')
        xml.uid_max('60000')
        xml.uid_min('1000')
        xml.useradd_cmd('/usr/sbin/useradd.local')
        xml.userdel_postcmd('/usr/sbin/userdel-post.local')
        xml.userdel_precmd('/usr/sbin/userdel-pre.local')
      end
    end
    if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.tag!('services-manager') do
        xml.default_target('graphical')
        xml.services do
          xml.disable("config:type": 'list')
          xml.enable("config:type": 'list') do
            enabled_services.each do |enabled_service|
              xml.service(enabled_service)
            end
          end
        end
      end
    end
    xml.software do
      if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.image
        xml.instsource
      end
      if values['service'].to_s.match(/sles_15/)
        xml.products("config:type": 'list') do
          xml.product('SLES')
        end
      end
      xml.packages("config:type": 'list') do
        add_packages.each do |package|
          xml.package(package)
        end
      end
      xml.patterns("config:type": 'list') do
        patterns.each do |pattern|
          xml.pattern(pattern)
        end
      end
      unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.tag!('remove-packages', "config:type": 'list') do
          remove_packages.each do |package|
            xml.package(package)
          end
        end
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.sound do
      end
      xml.sshd do
        xml.config do
          xml.AcceptEnv("config:type": 'list') do
            xml.listentry('LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES ')
            xml.listentry('LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT ')
            xml.listentry('LC_IDENTIFICATION LC_ALL')
          end
          xml.PasswordAuthentication("config:type": 'list') do
            xml.listentry('no')
          end
          xml.Protocol("config:type": 'list') do
            xml.listentry('2')
          end
          xml.Subsystem("config:type": 'list') do
            xml.listentry("sftp\t/usr/lib64/ssh/sftp-server")
          end
          xml.UsePAM("config:type": 'list') do
            xml.listentry('yes')
          end
          xml.X11Forwarding("config:type": 'list') do
            xml.listentry('yes')
          end
        end
        xml.status('true', "config:type": 'boolean')
      end
      xml.suse_register do
        xml.do_registration('false', "config:type": 'boolean')
        xml.reg_server
        xml.reg_server_cert
        xml.register_regularly('false', "config:type": 'boolean')
        xml.registration_data
        xml.submit_hwdata('false', "config:type": 'boolean')
        xml.submit_optional('false', "config:type": 'boolean')
      end
    end
    xml.timezone do
      xml.hwclock('UTC')
      xml.timezone(values['answers']['timezone'].value)
    end
    xml.user_defaults do
      xml.expire
      xml.group('100')
      if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
        xml.groups
      else
        xml.groups('video,dialout')
      end
      xml.home('/home')
      xml.inactive('-1')
      xml.no_groups('true', "config:type": 'boolean') if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.shell('/bin/bash')
      xml.skel('/etc/skel')
      xml.umask('022')
    end
    xml.users("config:type": 'list') do
      values['u_order'].each do |user|
        xml.user do
          xml.encrypted('true', "config:type": 'boolean')
          xml.fullname(values['u_struct'][user].fullname)
          xml.gid(values['u_struct'][user].gid)
          xml.home(values['u_struct'][user].home)
          xml.password_settings do
            if values['u_struct'][user].expire.match(/[a-z,0-9]/)
              xml.expire(values['u_struct'][user].expire)
            else
              xml.expire
            end
            if values['u_struct'][user].flag.match(/[a-z,0-9]/)
              xml.flag(values['u_struct'][user].flag)
            else
              xml.flag
            end
            if values['u_struct'][user].inact.match(/[a-z,0-9]/)
              xml.inact(values['u_struct'][user].inact)
            else
              xml.inact
            end
            if values['u_struct'][user].max.match(/[a-z,0-9]/)
              xml.max(values['u_struct'][user].max)
            else
              xml.max
            end
            if values['u_struct'][user].min.match(/[a-z,0-9]/)
              xml.max(values['u_struct'][user].min)
            else
              xml.min
            end
            if values['u_struct'][user].warn.match(/[a-z,0-9]/)
              xml.warn(values['u_struct'][user].warn)
            else
              xml.warn
            end
          end
          xml.shell(values['u_struct'][user].shell)
          xml.uid(values['u_struct'][user].uid)
          xml.user_password(values['u_struct'][user].user_password)
          xml.username(values['u_struct'][user].username)
        end
      end
    end
    unless values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      xml.x11 do
        xml.color_depth('8', "config:type": 'integer')
        xml.display_manager('gdm')
        xml.enable_3d('true', "config:type": 'boolean')
        xml.monitor do
          xml.display do
            xml.max_hsync('60', "config:type": 'integer')
            xml.max_vsync('75', "config:type": 'integer')
            xml.min_hsync('31', "config:type": 'integer')
            xml.min_vsync('50', "config:type": 'integer')
          end
          xml.monitor_device('Unknown')
          xml.monitor_vendor('Unknown')
        end
        xml.resolution('800x600 (SVGA)')
        xml.window_manager
      end
    end
  end
  file = File.open(output_file, 'w')
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Information:\tValidating AutoYast XML configuration for #{values['name']}"
  command = "xmllint #{output_file}"
  execute_command(values, message, command)
  print_contents_of_file(values, '', output_file)
  nil
end
