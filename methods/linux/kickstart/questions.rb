
# Questions for ks

# Construct ks language line

def get_ks_language(values)
  result = "--default="+values['answers']['install_language'].value+" "+values['answers']['install_language'].value
  return result
end

# Construct ks xconfig line

def get_ks_xconfig(values)
  result = "--card "+values['answers']['videocard'].value+" --videoram "+values['answers']['videoram'].value+" --hsync "+values['answers']['hsync'].value+" --vsync "+values['answers']['vsync'].value+" --resolution "+values['answers']['resolution'].value+" --depth "+values['answers']['depth'].value
  return result
end

# Construct ks network line

def get_ks_network(values)
  if values['answers']['bootproto'].value == "dhcp"
    result = "--device="+values['answers']['nic'].value+" --bootproto="+values['answers']['bootproto'].value
  else
    if values['service'].to_s.match(/fedora_20/)
      result = "--bootproto="+values['answers']['bootproto'].value+" --ip="+values['answers']['ip'].value+" --netmask="+values['answers']['netmask'].value+" --gateway "+values['answers']['gateway'].value+" --nameserver="+values['answers']['nameserver'].value+" --hostname="+values['answers']['hostname'].value
    else
      if values['service'].to_s.match(/rhel_5/)
        result = "--device "+values['answers']['nic'].value+" --bootproto "+values['answers']['bootproto'].value+" --ip "+values['answers']['ip'].value
      else
        result = "--device="+values['answers']['nic'].value+" --bootproto="+values['answers']['bootproto'].value+" --ip="+values['answers']['ip'].value+" --netmask="+values['answers']['netmask'].value+" --gateway="+values['answers']['gateway'].value+" --nameserver="+values['answers']['nameserver'].value+" --hostname="+values['answers']['hostname'].value
      end
    end
  end
  if values['answers']['install_service'].value.match(/oel/)
    result = result+" --onboot=on"
  end
  return result
end

# Set network

def set_ks_network(values)
  if values['answers']['bootproto'].value == "dhcp6"
    values['answers']['ip'].ask = "no"
    values['answers']['ip'].type = ""
    values['answers']['hostname'].ask = "no"
    values['answers']['hostname'].type = ""
  end
  return values
end

# Construct ks password line

def get_ks_root_password(values)
  result = "--iscrypted "+values['answers']['root_crypt'].value.to_s
  return result
end

# Construct admin ks password line

def get_ks_admin_password(values)
  result = "--name = "+values['answers']['admin_username'].value+" --groups="+values['answers']['admin_group'].value+" --homedir="+values['answers']['admin_home'].value+" --password="+values['answers']['admin_crypt'].value.to_s+" --iscrypted --shell="+values['answers']['admin_shell'].value+" --uid="+values['answers']['admin_uid'].value
  return result
end

# Construct ks bootloader line

def get_ks_bootloader(values)
  result = "--location="+values['answers']['bootstrap'].value
  return result
end

# Construct ks clear partition line

def get_ks_clearpart(values)
  result = "--all --drives="+values['answers']['bootdevice'].value+" --initlabel"
  return result
end

# Construct ks services line

def get_ks_services(values)
  result = "--enabled="+values['answers']['enabled_services'].value+" --disabled="+values['answers']['disabled_services'].value
  return result
end

# Construct ks boot partition line

def get_ks_bootpart(values)
  result = "/boot --fstype "+values['answers']['bootfs'].value+" --size="+values['answers']['bootsize'].value+" --ondisk="+values['answers']['bootdevice'].value
  return result
end

# Construct ks root partition line

def get_ks_swappart(values)
  result = "swap --size="+values['answers']['swapmax'].value
  return result
end

# Construct ks root partition line

def get_ks_rootpart(values)
  result = "/ --fstype "+values['answers']['rootfs'].value+" --size=1 --grow --asprimary"
  return result
end

# Construct ks volume partition line

def get_ks_volpart(values)
  result = values['answers']['volname'].value+" --size="+values['answers']['volsize'].value+" --grow --ondisk="+values['answers']['bootdevice'].value
  return result
end

# Construct ks volume group line

def get_ks_volgroup(values)
  result = values['answers']['volgroupname'].value+" --pesize="+values['answers']['pesize'].value+" "+values['answers']['volname'].value
  return result
end

# Construct ks log swap line

def get_ks_logswap(values)
  result = "swap --fstype swap --name="+values['answers']['swapvol'].value+" --vgname="+values['answers']['volgroupname'].value+" --size="+values['answers']['swapmin'].value+" --grow --maxsize="+values['answers']['swapmax'].value
  return result
end

# Construct ks log root line

def get_ks_logroot(values)
  result = "/ --fstype "+values['answers']['rootfs'].value+" --name="+values['answers']['rootvol'].value+" --vgname="+values['answers']['volgroupname'].value+" --size="+values['answers']['rootsize'].value+" --grow"
  return result
end

# Get install url

def get_ks_install_url(values)
  if values['type'].to_s.match(/packer/)
    install_url = "--url=http://"+values['hostip']+":"+values['httpport']+"/"+values['service']
  else
    install_url = "--url=http://"+values['hostip']+"/"+values['service']
  end
  return install_url
end

# Get kickstart header

def get_ks_header(values)
  version = get_version()
  version = version.join(" ")
  header  = "# kickstart file for "+values['name']+" "+version
  return header
end

# Populate ks questions

def populate_ks_questions(values)

  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  if values['vm'].to_s.match(/kvm/)
    disk_dev = "vda"
  else
    disk_dev = values['rootdisk'].split(/\//)[2] 
  end

  name   = "headless_mode"
  config = qs.new(
    type      = "",
    question  = "Headless mode",
    ask       = "yes",
    parameter = "",
    value     = values['headless'].to_s.downcase,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "install_service"
  config = qs.new(
    type      = "",
    question  = "Service Name",
    ask       = "yes",
    parameter = "",
    value     = values['service'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['service'].to_s.match(/rhel_5/)

    name   = "values['key']"
    config = qs.new(
      type      = "",
      question  = "Installation Key",
      ask       = "no",
      parameter = "key",
      value     = "--skip",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "ks_header"
  config = qs.new(
    type      = "output",
    question  = "Kickstart file header comment",
    ask       = "yes",
    parameter = "",
    value     = get_ks_header(values),
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = "firewall"

  if values['service'].to_s.match(/rhel_5/)

    config = qs.new(
      type      = "output",
      question  = "Firewall",
      ask       = "yes",
      parameter = "firewall",
      value     = "--enabled --ssh --service=ssh",
      valid     = "",
      eval      = "no"
    )

  else

    config = qs.new(
      type      = "output",
      question  = "Firewall",
      ask       = "yes",
      parameter = "firewall",
      value     = "--enabled --ssh",
      valid     = "",
      eval      = "no"
    )

  end

  values['answers'][name] = config
  values['order'].push(name)

  name   = "console"
  config = qs.new(
    type      = "output",
    question  = "Console type",
    ask       = "yes",
    parameter = "",
    value     = "text",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if not values['service'].to_s.match(/[el,centos,rocky,alma]_9/)

    name   = "values['type']"
    config = qs.new(
      type      = "output",
      question  = "Install type",
      ask       = "yes",
      parameter = "",
      value     = "install",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "values['method']"
  config = qs.new(
    type      = "output",
    question  = "Install Medium",
    ask       = "yes",
    parameter = "",
    value     = "cdrom",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if not values['type'].to_s.match(/packer/)
    name   = "url"
    config = qs.new(
      type      = "output",
      question  = "Install Medium",
      ask       = "yes",
      parameter = "url",
      value     = get_ks_install_url(values),
      valid     = "",
      eval      = "no"
      )
    values['answers'][name] = config
    values['order'].push(name)
  end

  name   = "install_language"
  config = qs.new(
    type      = "output",
    question  = "Install Language",
    ask       = "yes",
    parameter = "lang",
    value     = "en_US.UTF-8",
    valid     = "",
    eval      = "no"
    )
  values['answers'][name] = config
  values['order'].push(name)

  if not values['service'].to_s.match(/fedora|[centos,sl,el,rocky,alma]_[6,7,8,9]/)

    name   = "support_language"
    config = qs.new(
      type      = "output",
      question  = "Support Language",
      ask       = "yes",
      parameter = "langsupport",
      value     = get_ks_language(values),
      valid     = "",
      eval      = "get_ks_language(values)"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "keyboard"
  config = qs.new(
    type      = "output",
    question  = "Keyboard",
    ask       = "yes",
    parameter = "keyboard",
    value     = "us",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "videocard"
  config = qs.new(
    type      = "",
    question  = "Video Card",
    ask       = "yes",
    parameter = "",
    value     = "VMWare",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "videoram"
  config = qs.new(
    type      = "",
    question  = "Video RAM",
    ask       = "yes",
    parameter = "",
    value     = "16384",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "hsync"
  config = qs.new(
    type      = "",
    question  = "Horizontal Sync",
    ask       = "yes",
    parameter = "",
    value     = "31.5-37.9",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "vsync"
  config = qs.new(
    type      = "",
    question  = "Vertical Sync",
    ask       = "yes",
    parameter = "",
    value     = "50-70",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "resolution"
  config = qs.new(
    type      = "",
    question  = "Resolution",
    ask       = "yes",
    parameter = "",
    value     = "800x600",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "depth"
  config = qs.new(
    type      = "",
    question  = "Bit Depth",
    ask       = "yes",
    parameter = "",
    value     = "16",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "xconfig"
  config = qs.new(
    type      = "",
    question  = "Xconfig",
    ask       = "yes",
    parameter = "xconfig",
    value     = get_ks_xconfig(values),
    valid     = "",
    eval      = "get_ks_xconfig(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  nic_name = get_nic_name_from_install_service(values)

  name   = "nic"
  config = qs.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = nic_name,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootproto"
  config = qs.new(
    type      = "",
    question  = "Boot Protocol",
    ask       = "yes",
    parameter = "",
    value     = "static",
    valid     = "static,dhcp",
    eval      = "values = set_ks_network(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "hostname"
  config = qs.new(
    type      = "",
    question  = "Hostname",
    ask       = "yes",
    parameter = "",
    value     = values['name'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ip"
  config = qs.new(
    type      = "",
    question  = "IP",
    ask       = "yes",
    parameter = "",
    value     = values['ip'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "netmask"
  config = qs.new(
    type      = "",
    question  = "Netmask",
    ask       = "yes",
    parameter = "",
    value     = values['netmask'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "nameserver"
  config = qs.new(
    type      = "",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "",
    value     = values['nameserver'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['gateway'].to_s.match(/[0-9]/) and values['vm'].to_s == values['empty'].to_s
    gateway = values['gateway']
  else
    if values['vmgateway'].to_s.split(/\./)[2] == values['ip'].to_s.split(/\./)[2]
      gateway = values['vmgateway']
    else
      if values['gateway'].to_s.split(/\./)[2] == values['ip'].to_s.split(/\./)[2]
        gateway = values['gateway']
      else
        if values['vmgateway'].to_s.match(/[0-9]/)
          gateway = values['vmgateway']
        else
          if values['type'].to_s.match(/packer/)
            gateway = values['ip'].split(/\./)[0..2].join(".")+"."+values['gatewaynode']
          else
            if values['server'] == values['empty']
              gateway = values['hostip']
            else
              gateway = values['server']
            end
          end
        end
      end
    end
  end

  if gateway.to_s.split(/\./)[2] != values['ip'].to_s.split(/\./)[2]
    gateway = %x[netstat -rn |grep "^0" |awk '{print $2}'].chomp
  end

  name   = "gateway"
  config = qs.new(
    type      = "",
    question  = "Gateway",
    ask       = "yes",
    parameter = "",
    value     = gateway,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = values['ip'].split(/\./)[0..2].join(".")+".255"

  name   = "broadcast"
  config = qs.new(
    type      = "",
    question  = "Broadcast",
    ask       = "yes",
    parameter = "",
    value     = broadcast,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = values['ip'].split(/\./)[0..2].join(".")+".0"

  name   = "network_address"
  config = qs.new(
    type      = "",
    question  = "Network Address",
    ask       = "yes",
    parameter = "",
    value     = network_address,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "network"
  config = qs.new(
    type      = "output",
    question  = "Network Configuration",
    ask       = "yes",
    parameter = "network",
    value     = "get_ks_network(values)",
    valid     = "",
    eval      = "get_ks_network(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_password"
  config = qs.new(
    type      = "",
    question  = "Root Password",
    ask       = "yes",
    parameter = "",
    value     = values['rootpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_crypt"
  config = qs.new(
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_root_password_crypt(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rootpw"
  config = qs.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_ks_root_password(values)",
    valid     = "",
    eval      = "get_ks_root_password(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "sudoers"
  config = qs.new(
    type      = "",
    question  = "Admin sudoers",
    ask       = "yes",
    parameter = "",
    value     = values['sudoers'],
    valid     = "",
    eval      = "no"
    )
  values['answers'][name] = config
  values['order'].push(name)

  if values['service'].to_s.match(/[centos,el,rocky,alma]_[8,9]/)
    enabled_services = ""
  else
    enabled_services = "ntp"
  end 

  name   = "enabled_services"
  config = qs.new(
    type      = "",
    question  = "Enabled Services",
    ask       = "yes",
    parameter = "",
    value     = enabled_services,
    valid     = "",
    eval      = ""
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "disabled_services"
  config = qs.new(
    type      = "",
    question  = "Disabled Services",
    ask       = "yes",
    parameter = "",
    value     = "",
    valid     = "",
    eval      = ""
  )
  values['answers'][name] = config
  values['order'].push(name)

  if not values['service'].to_s.match(/fedora|[centos,el,rocky,alma]_[8,9]/)

    name   = "services"
    config = qs.new(
      type      = "output",
      question  = "Services",
      ask       = "yes",
      parameter = "services",
      value     = "get_ks_services(values)",
      valid     = "",
      eval      = ""
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "admin_username"
  config = qs.new(
    type      = "",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_uid"
  config = qs.new(
    type      = "",
    question  = "Admin User ID",
    ask       = "yes",
    parameter = "",
    value     = values['adminuid'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_shell"
  config = qs.new(
    type      = "",
    question  = "Admin User Shell",
    parameter = "",
    value     = values['adminshell'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_home"
  config = qs.new(
    type      = "",
    question  = "Admin User Home Directory",
    ask       = "yes",
    parameter = "",
    value     = "/home/"+values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_group"
  config = qs.new(
    type      = "",
    question  = "Admin User Group",
    ask       = "yes",
    parameter = "",
    value     = values['admingroup'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_gid"
  config = qs.new(
    type      = "",
    question  = "Admin Group ID",
    ask       = "yes",
    parameter = "",
    value     = values['admingid'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_password"
  config = qs.new(
    type      = "",
    question  = "Admin User Password",
    ask       = "yes",
    parameter = "",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_crypt"
  config = qs.new(
    type      = "",
    question  = "Admin User Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_admin_password_crypt(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "selinux"
  config = qs.new(
    type      = "output",
    question  = "SELinux Configuration",
    ask       = "yes",
    parameter = "selinux",
    value     = "--disabled",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['service'].to_s.match(/[centos,rhel,rocky,alma]_9/)
    name   = "authselect"
    config = qs.new(
      type      = "output",
      question  = "Authentication Configuration",
      ask       = "yes",
      parameter = "authselect",
      value     = "select minimal",
      valid     = "",
      eval      = "no"
    )
  else
    name   = "authconfig"
    config = qs.new(
      type      = "output",
      question  = "Authentication Configuration",
      ask       = "yes",
      parameter = "authconfig",
      value     = "--enableshadow --enablemd5",
      valid     = "",
      eval      = "no"
    )
  end
  values['answers'][name] = config
  values['order'].push(name)

  name   = "timezone"
  config = qs.new(
    type      = "output",
    question  = "Timezone",
    ask       = "yes",
    parameter = "timezone",
    value     = values['timezone'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootstrap"
  config = qs.new(
    type      = "",
    question  = "Bootstrap",
    ask       = "yes",
    parameter = "",
    value     = "mbr",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootloader"
  config = qs.new(
    type      = "output",
    question  = "Bootloader",
    ask       = "yes",
    parameter = "bootloader",
    value     = get_ks_bootloader(values),
    valid     = "",
    eval      = "get_ks_bootloader(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = "zerombr"

  if values['service'].to_s.match(/fedora|[centos,el,sl,rocky,alma]_[7,8,9]/)

    config = qs.new(
      type      = "output",
      question  = "Zero MBR",
      ask       = "no",
      parameter = "zerombr",
      value     = "",
      valid     = "",
      eval      = ""
    )

  else

    config = qs.new(
      type      = "output",
      question  = "Zero MBR",
      ask       = "no",
      parameter = "zerombr",
      value     = "yes",
      valid     = "",
      eval      = ""
    )

  end

  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootdevice"
  config = qs.new(
    type      = "",
    question  = "Boot Device",
    ask       = "yes",
    parameter = "",
    value     = disk_dev,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "clearpart"
  config = qs.new(
    type      = "output",
    question  = "Clear Parition",
    ask       = "yes",
    parameter = "clearpart",
    value     = get_ks_clearpart(values),
    valid     = "",
    eval      = "get_ks_clearpart(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootfs"
  config = qs.new(
    type      = "",
    question  = "Boot Filesystem",
    ask       = "no",
    parameter = "",
    value     = "ext3",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootsize"
  config = qs.new(
    type      = "",
    question  = "Boot Size",
    ask       = "yes",
    parameter = "",
    value     = values['bootsize'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootpart"
  config = qs.new(
    type      = "output",
    question  = "Boot Parition",
    ask       = "yes",
    parameter = "part",
    value     = get_ks_bootpart(values),
    valid     = "",
    eval      = "get_ks_bootpart(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "volname"
  config = qs.new(
    type      = "",
    question  = "Physical Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "pv.2",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "volsize"
  config = qs.new(
    type      = "",
    question  = "Physical Volume Size",
    ask       = "yes",
    parameter = "",
    value     = "1",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "volpart"
  config = qs.new(
    type      = "output",
    question  = "Physical Volume Configuration",
    ask       = "yes",
    parameter = "part",
    value     = get_ks_volpart(values),
    valid     = "",
    eval      = "get_ks_volpart(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "volgroupname"
  config = qs.new(
    type      = "",
    question  = "Volume Group Name",
    ask       = "yes",
    parameter = "",
    value     = "VolGroup00",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "pesize"
  config = qs.new(
    type      = "",
    question  = "Physical Extent Size",
    ask       = "yes",
    parameter = "",
    value     = "32768",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "volgroup"
  config = qs.new(
    type      = "output",
    question  = "Volume Group Configuration",
    ask       = "yes",
    parameter = "volgroup",
    value     = get_ks_volgroup(values),
    valid     = "",
    eval      = "get_ks_volgroup(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "swapmin"
  config = qs.new(
    type      = "",
    question  = "Minimum Swap Size",
    ask       = "yes",
    parameter = "",
    value     = "512",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "swapmax"
  config = qs.new(
    type      = "",
    question  = "Maximum Swap Size",
    ask       = "yes",
    parameter = "",
    value     = "1024",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "swapvol"
  config = qs.new(
    type      = "",
    question  = "Swap Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "LogVol01",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "logswap"
  config = qs.new(
    type      = "output",
    question  = "Swap Logical Volume Configuration",
    ask       = "yes",
    parameter = "logvol",
    value     = get_ks_logswap(values),
    valid     = "",
    eval      = "get_ks_logswap(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rootfs"
  config = qs.new(
    type      = "",
    question  = "Root Filesystem",
    ask       = "yes",
    parameter = "",
    value     = "ext3",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rootvol"
  config = qs.new(
    type      = "",
    question  = "Root Volume Name",
    ask       = "yes",
    parameter = "",
    value     = "LogVol00",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rootsize"
  config = qs.new(
    type      = "",
    question  = "Root Size",
    ask       = "yes",
    parameter = "",
    value     = values['rootsize'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "logroot"
  config = qs.new(
    type      = "output",
    question  = "Root Logical Volume Configuration",
    ask       = "yes",
    parameter = "logvol",
    value     = get_ks_logroot(values),
    valid     = "",
    eval      = "get_ks_logroot(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['reboot'] == true
    reboot_line = "reboot"
  else
    reboot_line = "#reboot"
  end

  name   = "finish"
  config = qs.new(
    type      = "output",
    question  = "Finish Command",
    ask       = "yes",
    parameter = "",
    value     = reboot_line,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end
