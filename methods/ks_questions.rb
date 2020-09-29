
# Questions for ks

# Construct ks language line

def get_ks_language(options)
  result = "--default="+$q_struct['install_language'].value+" "+$q_struct['install_language'].value
  return result
end

# Construct ks xconfig line

def get_ks_xconfig(options)
  result = "--card "+$q_struct['videocard'].value+" --videoram "+$q_struct['videoram'].value+" --hsync "+$q_struct['hsync'].value+" --vsync "+$q_struct['vsync'].value+" --resolution "+$q_struct['resolution'].value+" --depth "+$q_struct['depth'].value
  return result
end

# Construct ks network line

def get_ks_network(options)
  if $q_struct['bootproto'].value == "dhcp"
    result = "--device="+$q_struct['nic'].value+" --bootproto="+$q_struct['bootproto'].value
  else
    if options['service'].to_s.match(/fedora_20/)
      result = "--bootproto="+$q_struct['bootproto'].value+" --ip="+$q_struct['ip'].value+" --netmask="+$q_struct['netmask'].value+" --gateway "+$q_struct['gateway'].value+" --nameserver="+$q_struct['nameserver'].value+" --hostname="+$q_struct['hostname'].value
    else
      if options['service'].to_s.match(/rhel_5/)
        result = "--device "+$q_struct['nic'].value+" --bootproto "+$q_struct['bootproto'].value+" --ip "+$q_struct['ip'].value
      else
        result = "--device="+$q_struct['nic'].value+" --bootproto="+$q_struct['bootproto'].value+" --ip="+$q_struct['ip'].value+" --netmask="+$q_struct['netmask'].value+" --gateway="+$q_struct['gateway'].value+" --nameserver="+$q_struct['nameserver'].value+" --hostname="+$q_struct['hostname'].value
      end
    end
  end
  if $q_struct['install_service'].value.match(/oel/)
    result = result+" --onboot=on"
  end
  return result
end

# Set network

def set_ks_network(options)
  if $q_struct['bootproto'].value == "dhcp6"
    $q_struct['ip'].ask = "no"
    $q_struct['ip'].type = ""
    $q_struct['hostname'].ask = "no"
    $q_struct['hostname'].type = ""
  end
  return options
end

# Construct ks password line

def get_ks_root_password(options)
  result = "--iscrypted "+$q_struct['root_crypt'].value.to_s
  return result
end

# Construct admin ks password line

def get_ks_admin_password(options)
  result = "--name = "+$q_struct['admin_username'].value+" --groups="+$q_struct['admin_group'].value+" --homedir="+$q_struct['admin_home'].value+" --password="+$q_struct['admin_crypt'].value.to_s+" --iscrypted --shell="+$q_struct['admin_shell'].value+" --uid="+$q_struct['admin_uid'].value
  return result
end

# Construct ks bootloader line

def get_ks_bootloader(options)
  result = "--location="+$q_struct['bootstrap'].value
  return result
end

# Construct ks clear partition line

def get_ks_clearpart(options)
  result = "--all --drives="+$q_struct['bootdevice'].value+" --initlabel"
  return result
end

# Construct ks services line

def get_ks_services(options)
  result = "--enabled="+$q_struct['enabled_services'].value+" --disabled="+$q_struct['disabled_services'].value
  return result
end

# Construct ks boot partition line

def get_ks_bootpart(options)
  result = "/boot --fstype "+$q_struct['bootfs'].value+" --size="+$q_struct['bootsize'].value+" --ondisk="+$q_struct['bootdevice'].value
  return result
end

# Construct ks root partition line

def get_ks_swappart(options)
  result = "swap --size="+$q_struct['swapmax'].value
  return result
end

# Construct ks root partition line

def get_ks_rootpart(options)
  result = "/ --fstype "+$q_struct['rootfs'].value+" --size=1 --grow --asprimary"
  return result
end

# Construct ks volume partition line

def get_ks_volpart(options)
  result = $q_struct['volname'].value+" --size="+$q_struct['volsize'].value+" --grow --ondisk="+$q_struct['bootdevice'].value
  return result
end

# Construct ks volume group line

def get_ks_volgroup(options)
  result = $q_struct['volgroupname'].value+" --pesize="+$q_struct['pesize'].value+" "+$q_struct['volname'].value
  return result
end

# Construct ks log swap line

def get_ks_logswap(options)
  result = "swap --fstype swap --name="+$q_struct['swapvol'].value+" --vgname="+$q_struct['volgroupname'].value+" --size="+$q_struct['swapmin'].value+" --grow --maxsize="+$q_struct['swapmax'].value
  return result
end

# Construct ks log root line

def get_ks_logroot(options)
  result = "/ --fstype "+$q_struct['rootfs'].value+" --name="+$q_struct['rootvol'].value+" --vgname="+$q_struct['volgroupname'].value+" --size="+$q_struct['rootsize'].value+" --grow"
  return result
end

# Get install url

def get_ks_install_url(options)
  if options['type'].to_s.match(/packer/)
    install_url = "--url=http://"+options['hostip']+":"+options['httpport']+"/"+options['service']
  else
    install_url = "--url=http://"+options['hostip']+"/"+options['service']
  end
  return install_url
end

# Get kickstart header

def get_ks_header(options)
  version = get_version()
  version = version.join(" ")
  header  = "# kickstart file for "+options['name']+" "+version
  return header
end

# Populate ks questions

def populate_ks_questions(options)

  options['ip'] = single_install_ip(options)

  if options['vm'].to_s.match(/kvm/)
    disk_dev = "vda"
  else
    disk_dev = options['rootdisk'].split(/\//)[2] 
  end

  # $q_struct = {}
  # $q_order  = []

  name = "headless_mode"
  config = Ks.new(
    type      = "",
    question  = "Headless mode",
    ask       = "yes",
    parameter = "",
    value     = options['headless'].to_s.downcase,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "install_service"
  config = Ks.new(
    type      = "",
    question  = "Service Name",
    ask       = "yes",
    parameter = "",
    value     = options['service'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['service'].to_s.match(/rhel_5/)
    name   = "options['key']"
    config = Ks.new(
      type      = "",
      question  = "Installation Key",
      ask       = "no",
      parameter = "key",
      value     = "--skip",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)
  end

  name   = "ks_header"
  config = Ks.new(
    type      = "output",
    question  = "Kickstart file header comment",
    ask       = "yes",
    parameter = "",
    value     = get_ks_header(options),
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "firewall"
  if options['service'].to_s.match(/rhel_5/)
    config = Ks.new(
      type      = "output",
      question  = "Firewall",
      ask       = "yes",
      parameter = "firewall",
      value     = "--enabled --ssh --service=ssh",
      valid     = "",
      eval      = "no"
      )
  else
    config = Ks.new(
      type      = "output",
      question  = "Firewall",
      ask       = "yes",
      parameter = "firewall",
      value     = "--enabled --ssh",
      valid     = "",
      eval      = "no"
      )
  end
  $q_struct[name] = config
  $q_order.push(name)

  name   = "console"
  config = Ks.new(
    type      = "output",
    question  = "Console type",
    ask       = "yes",
    parameter = "",
    value     = "text",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "options['type']"
  config = Ks.new(
    type      = "output",
    question  = "Install type",
    ask       = "yes",
    parameter = "",
    value     = "install",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "options['method']"
  config = Ks.new(
    type      = "output",
    question  = "Install Medium",
    ask       = "yes",
    parameter = "",
    value     = "cdrom",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if not options['type'].to_s.match(/packer/)
    name   = "url"
    config = Ks.new(
      type      = "output",
      question  = "Install Medium",
      ask       = "yes",
      parameter = "url",
      value     = get_ks_install_url(options),
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)
  end

  name   = "install_language"
  config = Ks.new(
    type      = "output",
    question  = "Install Language",
    ask       = "yes",
    parameter = "lang",
    value     = "en_US.UTF-8",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if not options['service'].to_s.match(/fedora|centos_[6,7,8]|sl_[6,7,8]|el_[6,7,8]/)
    name   = "support_language"
    config = Ks.new(
      type      = "output",
      question  = "Support Language",
      ask       = "yes",
      parameter = "langsupport",
      value     = get_ks_language(options),
      valid     = "",
      eval      = "get_ks_language(options)"
      )
    $q_struct[name] = config
    $q_order.push(name)
  end

  name   = "keyboard"
  config = Ks.new(
    type      = "output",
    question  = "Keyboard",
    ask       = "yes",
    parameter = "keyboard",
    value     = "us",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "videocard"
  config = Ks.new(
    type      = "",
    question  = "Video Card",
    ask       = "yes",
    parameter = "",
    value     = "VMWare",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "videoram"
  config = Ks.new(
    type      = "",
    question  = "Video RAM",
    ask       = "yes",
    parameter = "",
    value     = "16384",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "hsync"
  config = Ks.new(
    type      = "",
    question  = "Horizontal Sync",
    ask       = "yes",
    parameter = "",
    value     = "31.5-37.9",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config

  name   = "vsync"
  config = Ks.new(
    type      = "",
    question  = "Vertical Sync",
    ask       = "yes",
    parameter = "",
    value     = "50-70",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "resolution"
  config = Ks.new(
    type      = "",
    question  = "Resolution",
    ask       = "yes",
    parameter = "",
    value     = "800x600",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "depth"
  config = Ks.new(
    type      = "",
    question  = "Bit Depth",
    ask       = "yes",
    parameter = "",
    value     = "16",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "xconfig"
  config = Ks.new(
    type      = "",
    question  = "Xconfig",
    ask       = "yes",
    parameter = "xconfig",
    value     = get_ks_xconfig(options),
    valid     = "",
    eval      = "get_ks_xconfig(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  nic_name = get_nic_name_from_install_service(options)

  name   = "nic"
  config = Ks.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = nic_name,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootproto"
  config = Ks.new(
    type      = "",
    question  = "Boot Protocol",
    ask       = "yes",
    parameter = "",
    value     = "static",
    valid     = "static,dhcp",
    eval      = "options = set_ks_network(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "hostname"
  config = Ks.new(
    type      = "",
    question  = "Hostname",
    ask       = "yes",
    parameter = "",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "ip"
  config = Ks.new(
    type      = "",
    question  = "IP",
    ask       = "yes",
    parameter = "",
    value     = options['ip'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "netmask"
  config = Ks.new(
    type      = "",
    question  = "Netmask",
    ask       = "yes",
    parameter = "",
    value     = options['netmask'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "nameserver"
  config = Ks.new(
    type      = "",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "",
    value     = options['nameserver'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "gateway"
  config = Ks.new(
    type      = "",
    question  = "Gateway",
    ask       = "yes",
    parameter = "",
    value     = options['vmgateway'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  broadcast = options['ip'].split(/\./)[0..2].join(".")+".255"

  name   = "broadcast"
  config = Ks.new(
    type      = "",
    question  = "Broadcast",
    ask       = "yes",
    parameter = "",
    value     = broadcast,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  network_address = options['ip'].split(/\./)[0..2].join(".")+".0"

  name   = "network_address"
  config = Ks.new(
    type      = "",
    question  = "Network Address",
    ask       = "yes",
    parameter = "",
    value     = network_address,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "network"
  config = Ks.new(
    type      = "output",
    question  = "Network Configuration",
    ask       = "yes",
    parameter = "network",
    value     = "get_ks_network(options)",
    valid     = "",
    eval      = "get_ks_network(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "root_password"
  config = Ks.new(
    type      = "",
    question  = "Root Password",
    ask       = "yes",
    parameter = "",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "root_crypt"
  config = Ks.new(
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_root_password_crypt(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "rootpw"
  config = Ks.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_ks_root_password(options)",
    valid     = "",
    eval      = "get_ks_root_password(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['service'].to_s.match(/el_8|centos_8/)
    enabled_services = ""
  else
    enabled_services = "ntp"
  end 

  name   = "enabled_services"
  config = Ks.new(
    type      = "",
    question  = "Enabled Services",
    ask       = "yes",
    parameter = "",
    value     = enabled_services,
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "disabled_services"
  config = Ks.new(
    type      = "",
    question  = "Disabled Services",
    ask       = "yes",
    parameter = "",
    value     = "",
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  if not options['service'].to_s.match(/fedora|el_8|centos_8/)

    name   = "services"
    config = Ks.new(
      type      = "output",
      question  = "Services",
      ask       = "yes",
      parameter = "services",
      value     = "get_ks_services(options)",
      valid     = "",
      eval      = ""
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  name   = "admin_username"
  config = Ks.new(
    type      = "",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_uid"
  config = Ks.new(
    type      = "",
    question  = "Admin User ID",
    ask       = "yes",
    parameter = "",
    value     = options['adminuid'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_shell"
  config = Ks.new(
    type      = "",
    question  = "Admin User Shell",
    parameter = "",
    value     = options['adminshell'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_home"
  config = Ks.new(
    type      = "",
    question  = "Admin User Home Directory",
    ask       = "yes",
    parameter = "",
    value     = "/home/"+options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_group"
  config = Ks.new(
    type      = "",
    question  = "Admin User Group",
    ask       = "yes",
    parameter = "",
    value     = options['admingroup'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_gid"
  config = Ks.new(
    type      = "",
    question  = "Admin Group ID",
    ask       = "yes",
    parameter = "",
    value     = options['admingid'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_password"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password",
    ask       = "yes",
    parameter = "",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "admin_crypt"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_admin_password_crypt(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "selinux"
  config = Ks.new(
    type      = "output",
    question  = "SELinux Configuration",
    ask       = "yes",
    parameter = "selinux",
    value     = "--disabled",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "authconfig"
  config = Ks.new(
    type      = "output",
    question  = "SELinux Configuration",
    ask       = "yes",
    parameter = "authconfig",
    value     = "--enableshadow --enablemd5",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "timezone"
  config = Ks.new(
    type      = "output",
    question  = "Timezone",
    ask       = "yes",
    parameter = "timezone",
    value     = options['timezone'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootstrap"
  config = Ks.new(
    type      = "",
    question  = "Bootstrap",
    ask       = "yes",
    parameter = "",
    value     = "mbr",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootloader"
  config = Ks.new(
    type      = "output",
    question  = "Bootloader",
    ask       = "yes",
    parameter = "bootloader",
    value     = get_ks_bootloader(options),
    valid     = "",
    eval      = "get_ks_bootloader(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "zerombr"
  if options['service'].to_s.match(/fedora|el_[7,8]|centos_[7,8]|sl_[7,8]/)
    config = Ks.new(
      type      = "output",
      question  = "Zero MBR",
      ask       = "no",
      parameter = "zerombr",
      value     = "",
      valid     = "",
      eval      = ""
      )
  else
    config = Ks.new(
      type      = "output",
      question  = "Zero MBR",
      ask       = "no",
      parameter = "zerombr",
      value     = "yes",
      valid     = "",
      eval      = ""
      )
  end
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootdevice"
  config = Ks.new(
    type      = "",
    question  = "Boot Device",
    ask       = "yes",
    parameter = "",
    value     = disk_dev,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "clearpart"
  config = Ks.new(
    type      = "output",
    question  = "Clear Parition",
    ask       = "yes",
    parameter = "clearpart",
    value     = get_ks_clearpart(options),
    valid     = "",
    eval      = "get_ks_clearpart(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootfs"
  config = Ks.new(
    type      = "",
    question  = "Boot Filesystem",
    ask       = "no",
    parameter = "",
    value     = "ext3",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootsize"
  config = Ks.new(
    type      = "",
    question  = "Boot Size",
    ask       = "yes",
    parameter = "",
    value     = options['bootsize'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "bootpart"
  config = Ks.new(
    type      = "output",
    question  = "Boot Parition",
    ask       = "yes",
    parameter = "part",
    value     = get_ks_bootpart(options),
    valid     = "",
    eval      = "get_ks_bootpart(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "volname"
  config = Ks.new(
    type      = "",
    question  = "Physical Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "pv.2",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "volsize"
  config = Ks.new(
    type      = "",
    question  = "Physical Volume Size",
    ask       = "yes",
    parameter = "",
    value     = "1",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "volpart"
  config = Ks.new(
    type      = "output",
    question  = "Physical Volume Configuration",
    ask       = "yes",
    parameter = "part",
    value     = get_ks_volpart(options),
    valid     = "",
    eval      = "get_ks_volpart(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "volgroupname"
  config = Ks.new(
    type      = "",
    question  = "Volume Group Name",
    ask       = "yes",
    parameter = "",
    value     = "VolGroup00",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "pesize"
  config = Ks.new(
    type      = "",
    question  = "Physical Extent Size",
    ask       = "yes",
    parameter = "",
    value     = "32768",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "volgroup"
  config = Ks.new(
    type      = "output",
    question  = "Volume Group Configuration",
    ask       = "yes",
    parameter = "volgroup",
    value     = get_ks_volgroup(options),
    valid     = "",
    eval      = "get_ks_volgroup(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "swapmin"
  config = Ks.new(
    type      = "",
    question  = "Minimum Swap Size",
    ask       = "yes",
    parameter = "",
    value     = "512",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "swapmax"
  config = Ks.new(
    type      = "",
    question  = "Maximum Swap Size",
    ask       = "yes",
    parameter = "",
    value     = "1024",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "swapvol"
  config = Ks.new(
    type      = "",
    question  = "Swap Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "LogVol01",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "logswap"
  config = Ks.new(
    type      = "output",
    question  = "Swap Logical Volume Configuration",
    ask       = "yes",
    parameter = "logvol",
    value     = get_ks_logswap(options),
    valid     = "",
    eval      = "get_ks_logswap(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "rootfs"
  config = Ks.new(
    type      = "",
    question  = "Root Filesystem",
    ask       = "yes",
    parameter = "",
    value     = "ext3",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "rootvol"
  config = Ks.new(
    type      = "",
    question  = "Root Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "LogVol00",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name   = "rootsize"
  config = Ks.new(
    type      = "",
    question  = "Root Size",
    ask       = "yes",
    parameter = "",
    value     = options['rootsize'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)


  name   = "logroot"
  config = Ks.new(
    type      = "output",
    question  = "Root Logical Volume Configuration",
    ask       = "yes",
    parameter = "logvol",
    value     = get_ks_logroot(options),
    valid     = "",
    eval      = "get_ks_logroot(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['reboot'] == true
    reboot_line = "reboot"
  else
    reboot_line = "#reboot"
  end

  name   = "finish"
  config = Ks.new(
    type      = "output",
    question  = "Finish Command",
    ask       = "yes",
    parameter = "",
    value     = reboot_line,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return options
end
