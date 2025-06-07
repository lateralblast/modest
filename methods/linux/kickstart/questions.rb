# frozen_string_literal: true

# Questions for ks

# Construct ks language line

def get_ks_language(values)
  "--default=#{values['answers']['install_language'].value} #{values['answers']['install_language'].value}"
end

# Construct ks xconfig line

def get_ks_xconfig(values)
  "--card #{values['answers']['videocard'].value} --videoram #{values['answers']['videoram'].value} --hsync #{values['answers']['hsync'].value} --vsync #{values['answers']['vsync'].value} --resolution #{values['answers']['resolution'].value} --depth #{values['answers']['depth'].value}"
end

# Construct ks network line

def get_ks_network(values)
  if values['answers']['bootproto'].value == 'dhcp'
    result = "--device=#{values['answers']['nic'].value} --bootproto=#{values['answers']['bootproto'].value}"
  elsif values['service'].to_s.match(/fedora_20/)
    result = "--bootproto=#{values['answers']['bootproto'].value} --ip=#{values['answers']['ip'].value} --netmask=#{values['answers']['netmask'].value} --gateway #{values['answers']['gateway'].value} --nameserver=#{values['answers']['nameserver'].value} --hostname=#{values['answers']['hostname'].value}"
  elsif values['service'].to_s.match(/rhel_5/)
    result = "--device #{values['answers']['nic'].value} --bootproto #{values['answers']['bootproto'].value} --ip #{values['answers']['ip'].value}"
  else
    result = "--device=#{values['answers']['nic'].value} --bootproto=#{values['answers']['bootproto'].value} --ip=#{values['answers']['ip'].value} --netmask=#{values['answers']['netmask'].value} --gateway=#{values['answers']['gateway'].value} --nameserver=#{values['answers']['nameserver'].value} --hostname=#{values['answers']['hostname'].value}"
  end
  result += ' --onboot=on' if values['answers']['install_service'].value.match(/oel/)
  result
end

# Set network

def set_ks_network(values)
  if values['answers']['bootproto'].value == 'dhcp6'
    values['answers']['ip'].ask = 'no'
    values['answers']['ip'].type = ''
    values['answers']['hostname'].ask = 'no'
    values['answers']['hostname'].type = ''
  end
  values
end

# Construct ks password line

def get_ks_root_password(values)
  "--iscrypted #{values['answers']['root_crypt'].value}"
end

# Construct admin ks password line

def get_ks_admin_password(values)
  "--name = #{values['answers']['admin_username'].value} --groups=#{values['answers']['admin_group'].value} --homedir=#{values['answers']['admin_home'].value} --password=#{values['answers']['admin_crypt'].value} --iscrypted --shell=#{values['answers']['admin_shell'].value} --uid=#{values['answers']['admin_uid'].value}"
end

# Construct ks bootloader line

def get_ks_bootloader(values)
  "--location=#{values['answers']['bootstrap'].value}"
end

# Construct ks clear partition line

def get_ks_clearpart(values)
  "--all --drives=#{values['answers']['bootdevice'].value} --initlabel"
end

# Construct ks services line

def get_ks_services(values)
  "--enabled=#{values['answers']['enabled_services'].value} --disabled=#{values['answers']['disabled_services'].value}"
end

# Construct ks boot partition line

def get_ks_bootpart(values)
  "/boot --fstype #{values['answers']['bootfs'].value} --size=#{values['answers']['bootsize'].value} --ondisk=#{values['answers']['bootdevice'].value}"
end

# Construct ks root partition line

def get_ks_swappart(values)
  "swap --size=#{values['answers']['swapmax'].value}"
end

# Construct ks root partition line

def get_ks_rootpart(values)
  "/ --fstype #{values['answers']['rootfs'].value} --size=1 --grow --asprimary"
end

# Construct ks volume partition line

def get_ks_volpart(values)
  "#{values['answers']['volname'].value} --size=#{values['answers']['volsize'].value} --grow --ondisk=#{values['answers']['bootdevice'].value}"
end

# Construct ks volume group line

def get_ks_volgroup(values)
  "#{values['answers']['volgroupname'].value} --pesize=#{values['answers']['pesize'].value} #{values['answers']['volname'].value}"
end

# Construct ks log swap line

def get_ks_logswap(values)
  "swap --fstype swap --name=#{values['answers']['swapvol'].value} --vgname=#{values['answers']['volgroupname'].value} --size=#{values['answers']['swapmin'].value} --grow --maxsize=#{values['answers']['swapmax'].value}"
end

# Construct ks log root line

def get_ks_logroot(values)
  "/ --fstype #{values['answers']['rootfs'].value} --name=#{values['answers']['rootvol'].value} --vgname=#{values['answers']['volgroupname'].value} --size=#{values['answers']['rootsize'].value} --grow"
end

# Get install url

def get_ks_install_url(values)
  if values['type'].to_s.match(/packer/)
    "--url=http://#{values['hostip']}:#{values['httpport']}/#{values['service']}"
  else
    "--url=http://#{values['hostip']}/#{values['service']}"
  end
end

# Get kickstart header

def get_ks_header(values)
  version = get_version(values)
  version = version.join(' ')
  "# kickstart file for #{values['name']} #{version}"
end

# Populate ks questions

def populate_ks_questions(values)
  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  disk_dev = if values['vm'].to_s.match(/kvm/)
               'vda'
             else
               values['rootdisk'].split(%r{/})[2]
             end

  name   = 'headless_mode'
  config = qs.new(
    '',
    'Headless mode',
    'yes',
    '',
    values['headless'].to_s.downcase,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'install_service'
  config = qs.new(
    '',
    'Service Name',
    'yes',
    '',
    values['service'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['service'].to_s.match(/rhel_5/)

    name   = "values['key']"
    config = qs.new(
      '',
      'Installation Key',
      'no',
      'key',
      '--skip',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'ks_header'
  config = qs.new(
    'output',
    'Kickstart file header comment',
    'yes',
    '',
    get_ks_header(values),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'firewall'

  config = if values['service'].to_s.match(/rhel_5/)

             qs.new(
               'output',
               'Firewall',
               'yes',
               'firewall',
               '--enabled --ssh --service=ssh',
               '',
               'no'
             )

           else

             qs.new(
               'output',
               'Firewall',
               'yes',
               'firewall',
               '--enabled --ssh',
               '',
               'no'
             )

           end

  values['answers'][name] = config
  values['order'].push(name)

  name   = 'console'
  config = qs.new(
    'output',
    'Console type',
    'yes',
    '',
    'text',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  unless values['service'].to_s.match(/[el,centos,rocky,alma]_9/)

    name   = "values['type']"
    config = qs.new(
      'output',
      'Install type',
      'yes',
      '',
      'install',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "values['method']"
  config = qs.new(
    'output',
    'Install Medium',
    'yes',
    '',
    'cdrom',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  unless values['type'].to_s.match(/packer/)
    name   = 'url'
    config = qs.new(
      'output',
      'Install Medium',
      'yes',
      'url',
      get_ks_install_url(values),
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)
  end

  name   = 'install_language'
  config = qs.new(
    'output',
    'Install Language',
    'yes',
    'lang',
    'en_US.UTF-8',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  unless values['service'].to_s.match(/fedora|[centos,sl,el,rocky,alma]_[6,7,8,9]/)

    name   = 'support_language'
    config = qs.new(
      'output',
      'Support Language',
      'yes',
      'langsupport',
      get_ks_language(values),
      '',
      'get_ks_language(values)'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'keyboard'
  config = qs.new(
    'output',
    'Keyboard',
    'yes',
    'keyboard',
    'us',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'videocard'
  config = qs.new(
    '',
    'Video Card',
    'yes',
    '',
    'VMWare',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'videoram'
  config = qs.new(
    '',
    'Video RAM',
    'yes',
    '',
    '16384',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'hsync'
  config = qs.new(
    '',
    'Horizontal Sync',
    'yes',
    '',
    '31.5-37.9',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vsync'
  config = qs.new(
    '',
    'Vertical Sync',
    'yes',
    '',
    '50-70',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'resolution'
  config = qs.new(
    '',
    'Resolution',
    'yes',
    '',
    '800x600',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'depth'
  config = qs.new(
    '',
    'Bit Depth',
    'yes',
    '',
    '16',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'xconfig'
  config = qs.new(
    '',
    'Xconfig',
    'yes',
    'xconfig',
    get_ks_xconfig(values),
    '',
    'get_ks_xconfig(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  nic_name = get_nic_name_from_install_service(values)

  name   = 'nic'
  config = qs.new(
    '',
    'Primary Network Interface',
    'yes',
    '',
    nic_name,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootproto'
  config = qs.new(
    '',
    'Boot Protocol',
    'yes',
    '',
    'static',
    'static,dhcp',
    'values = set_ks_network(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'hostname'
  config = qs.new(
    '',
    'Hostname',
    'yes',
    '',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip'
  config = qs.new(
    '',
    'IP',
    'yes',
    '',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'netmask'
  config = qs.new(
    '',
    'Netmask',
    'yes',
    '',
    values['netmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'nameserver'
  config = qs.new(
    '',
    'Nameserver(s)',
    'yes',
    '',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = if values['gateway'].to_s.match(/[0-9]/) && (values['vm'].to_s == values['empty'].to_s)
              values['gateway']
            elsif values['vmgateway'].to_s.split(/\./)[2] == values['ip'].to_s.split(/\./)[2]
              values['vmgateway']
            elsif values['gateway'].to_s.split(/\./)[2] == values['ip'].to_s.split(/\./)[2]
              values['gateway']
            elsif values['vmgateway'].to_s.match(/[0-9]/)
              values['vmgateway']
            elsif values['type'].to_s.match(/packer/)
              "#{values['ip'].split(/\./)[0..2].join('.')}.#{values['gatewaynode']}"
            elsif values['server'] == values['empty']
              values['hostip']
            else
              values['server']
            end

  gateway = `netstat -rn |grep "^0" |awk '{print $2}'`.chomp if gateway.to_s.split(/\./)[2] != values['ip'].to_s.split(/\./)[2]

  name   = 'gateway'
  config = qs.new(
    '',
    'Gateway',
    'yes',
    '',
    gateway,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = "#{values['ip'].split(/\./)[0..2].join('.')}.255"

  name   = 'broadcast'
  config = qs.new(
    '',
    'Broadcast',
    'yes',
    '',
    broadcast,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = "#{values['ip'].split(/\./)[0..2].join('.')}.0"

  name   = 'network_address'
  config = qs.new(
    '',
    'Network Address',
    'yes',
    '',
    network_address,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'network'
  config = qs.new(
    'output',
    'Network Configuration',
    'yes',
    'network',
    'get_ks_network(values)',
    '',
    'get_ks_network(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_password'
  config = qs.new(
    '',
    'Root Password',
    'yes',
    '',
    values['rootpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_crypt'
  config = qs.new(
    '',
    'Root Password Crypt',
    'yes',
    '',
    'get_root_password_crypt(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rootpw'
  config = qs.new(
    'output',
    'Root Password Configuration',
    'yes',
    'rootpw',
    'get_ks_root_password(values)',
    '',
    'get_ks_root_password(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'sudoers'
  config = qs.new(
    '',
    'Admin sudoers',
    'yes',
    '',
    values['sudoers'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  enabled_services = if values['service'].to_s.match(/[centos,el,rocky,alma]_[8,9]/)
                       ''
                     else
                       'ntp'
                     end

  name   = 'enabled_services'
  config = qs.new(
    '',
    'Enabled Services',
    'yes',
    '',
    enabled_services,
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'disabled_services'
  config = qs.new(
    '',
    'Disabled Services',
    'yes',
    '',
    '',
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  unless values['service'].to_s.match(/fedora|[centos,el,rocky,alma]_[8,9]/)

    name   = 'services'
    config = qs.new(
      'output',
      'Services',
      'yes',
      'services',
      'get_ks_services(values)',
      '',
      ''
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'admin_username'
  config = qs.new(
    '',
    'Admin Username',
    'yes',
    '',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_uid'
  config = qs.new(
    '',
    'Admin User ID',
    'yes',
    '',
    values['adminuid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_shell'
  config = qs.new(
    '',
    'Admin User Shell',
    '',
    values['adminshell'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_home'
  config = qs.new(
    '',
    'Admin User Home Directory',
    'yes',
    '',
    "/home/#{values['adminuser']}",
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_group'
  config = qs.new(
    '',
    'Admin User Group',
    'yes',
    '',
    values['admingroup'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_gid'
  config = qs.new(
    '',
    'Admin Group ID',
    'yes',
    '',
    values['admingid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_password'
  config = qs.new(
    '',
    'Admin User Password',
    'yes',
    '',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_crypt'
  config = qs.new(
    '',
    'Admin User Password Crypt',
    'yes',
    '',
    'get_admin_password_crypt(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'selinux'
  config = qs.new(
    'output',
    'SELinux Configuration',
    'yes',
    'selinux',
    '--disabled',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['service'].to_s.match(/[centos,rhel,rocky,alma]_9/)
    name   = 'authselect'
    config = qs.new(
      'output',
      'Authentication Configuration',
      'yes',
      'authselect',
      'select minimal',
      '',
      'no'
    )
  else
    name   = 'authconfig'
    config = qs.new(
      'output',
      'Authentication Configuration',
      'yes',
      'authconfig',
      '--enableshadow --enablemd5',
      '',
      'no'
    )
  end
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'timezone'
  config = qs.new(
    'output',
    'Timezone',
    'yes',
    'timezone',
    values['timezone'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootstrap'
  config = qs.new(
    '',
    'Bootstrap',
    'yes',
    '',
    'mbr',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootloader'
  config = qs.new(
    'output',
    'Bootloader',
    'yes',
    'bootloader',
    get_ks_bootloader(values),
    '',
    'get_ks_bootloader(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'zerombr'

  config = if values['service'].to_s.match(/fedora|[centos,el,sl,rocky,alma]_[7,8,9]/)

             qs.new(
               'output',
               'Zero MBR',
               'no',
               'zerombr',
               '',
               '',
               ''
             )

           else

             qs.new(
               'output',
               'Zero MBR',
               'no',
               'zerombr',
               'yes',
               '',
               ''
             )

           end

  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootdevice'
  config = qs.new(
    '',
    'Boot Device',
    'yes',
    '',
    disk_dev,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'clearpart'
  config = qs.new(
    'output',
    'Clear Parition',
    'yes',
    'clearpart',
    get_ks_clearpart(values),
    '',
    'get_ks_clearpart(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootfs'
  config = qs.new(
    '',
    'Boot Filesystem',
    'no',
    '',
    'ext3',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootsize'
  config = qs.new(
    '',
    'Boot Size',
    'yes',
    '',
    values['bootsize'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootpart'
  config = qs.new(
    'output',
    'Boot Parition',
    'yes',
    'part',
    get_ks_bootpart(values),
    '',
    'get_ks_bootpart(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'volname'
  config = qs.new(
    '',
    'Physical Volume Name',
    'yes',
    '',
    'pv.2',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'volsize'
  config = qs.new(
    '',
    'Physical Volume Size',
    'yes',
    '',
    '1',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'volpart'
  config = qs.new(
    'output',
    'Physical Volume Configuration',
    'yes',
    'part',
    get_ks_volpart(values),
    '',
    'get_ks_volpart(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'volgroupname'
  config = qs.new(
    '',
    'Volume Group Name',
    'yes',
    '',
    'VolGroup00',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'pesize'
  config = qs.new(
    '',
    'Physical Extent Size',
    'yes',
    '',
    '32768',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'volgroup'
  config = qs.new(
    'output',
    'Volume Group Configuration',
    'yes',
    'volgroup',
    get_ks_volgroup(values),
    '',
    'get_ks_volgroup(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'swapmin'
  config = qs.new(
    '',
    'Minimum Swap Size',
    'yes',
    '',
    '512',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'swapmax'
  config = qs.new(
    '',
    'Maximum Swap Size',
    'yes',
    '',
    '1024',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'swapvol'
  config = qs.new(
    '',
    'Swap Volume Name',
    'yes',
    '',
    'LogVol01',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'logswap'
  config = qs.new(
    'output',
    'Swap Logical Volume Configuration',
    'yes',
    'logvol',
    get_ks_logswap(values),
    '',
    'get_ks_logswap(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rootfs'
  config = qs.new(
    '',
    'Root Filesystem',
    'yes',
    '',
    'ext3',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rootvol'
  config = qs.new(
    '',
    'Root Volume Name',
    'yes',
    '',
    'LogVol00',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rootsize'
  config = qs.new(
    '',
    'Root Size',
    'yes',
    '',
    values['rootsize'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'logroot'
  config = qs.new(
    'output',
    'Root Logical Volume Configuration',
    'yes',
    'logvol',
    get_ks_logroot(values),
    '',
    'get_ks_logroot(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  reboot_line = if values['reboot'] == true
                  'reboot'
                else
                  '#reboot'
                end

  name   = 'finish'
  config = qs.new(
    'output',
    'Finish Command',
    'yes',
    '',
    reboot_line,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end
