
# Preseed configuration questions for Ubuntu

def populate_ps_questions(options)

  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  install_ip1 = "none"
  install_ip2 = "none"
  install_ip3 = "none"
  install_ip4 = "none"
  install_ip5 = "none"

  if options['packages'] == options['empty']
    pkg_list = [
      "nfs-common", "openssh-server", "setserial", "net-tools", "ansible", "jq", "ipmitool", "screen", "ruby-build", "git", "cryptsetup", "curl"
    ]
    if options['service'].match(/18_04/)
      pkg_list.append("linux-generic-hwe-18.04")
    end
  else
    pkg_list = options['packages'].to_s.split(/\,| /)
  end

  if options['ip'].to_s.match(/,/)
    full_ip     = options['ip']
    options['ip']  = full_ip.split(/,/)[0]
    if full_ip[1]
      install_ip1 = full_ip.split(/,/)[1]
      if not install_ip1
        install_ip1 = "none"
      end
    end
    if full_ip[2]
      install_ip2 = full_ip.split(/,/)[2]
      if not install_ip2
        install_ip2 = "none"
      end
    end
    if full_ip[3]
      install_ip3 = full_ip.split(/,/)[3]
      if not install_ip3
        install_ip3 = "none"
      end
    end
    if full_ip[4]
      install_ip4 = full_ip.split(/,/)[4]
      if not install_ip4
        install_ip4 = "none"
      end
    end
    if full_ip[5]
      install_ip5 = full_ip.split(/,/)[5]
      if not install_ip5
        install_ip5 = "none"
      end
    end
  end

  if options['service'].to_s != "purity"

    name = "headless_mode"
    config = qs.new( 
      type      = "",
      question  = "Headless mode",
      ask       = "yes",
      parameter = "",
      value     = options['headless'].to_s.downcase,
      valid     = "",
      eval      = "no"
      )

    options['q_struct'][name] = config
    options['q_order'].push(name)

    if options['service'].match(/ubuntu_20/)
      language = options['language']
      if language.match(/en_/)
        language = "en"
      end
    else
      language = options['language']
    end

    name = "language"
    config = qs.new(
      type      = "string",
      question  = "Language",
      ask       = "yes",
      parameter = "debian-installer/language",
      value     = language,
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "country"
    config = qs.new(
      type      = "string",
      question  = "Country",
      ask       = "yes",
      parameter = "debian-installer/country",
      value     = options['country'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "locale"
    config = qs.new(
      type      = "string",
      question  = "Locale",
      ask       = "yes",
      parameter = "debian-installer/locale",
      value     = options['locale'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "console"
    config = qs.new(
      type      = "boolean",
      question  = "Enable keymap detection",
      ask       = "no",
      parameter = "console-setup/ask_detect",
      value     = "false",
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)
  
    name = "layout"
    config = qs.new(
      type      = "string",
      question  = "Keyboard layout",
      ask       = "no",
      parameter = "keyboard-configuration/layoutcode",
      value     = options['keyboard'].downcase,
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "disable_autoconfig"
    config = qs.new(
      type      = "boolean",
      question  = "Disable network autoconfig",
      ask       = "yes",
      parameter = "netcfg/disable_autoconfig",
      value     = options['disableautoconf'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)
  
    if options['vm'].to_s.match(/vbox/) && options['type'].to_s.match(/packer/)
      disable_dhcp = "false"
    else
      if options['service'].to_s.match(/live/) || options['vm'].to_s.match(/mp|multipass/)
        if options['ip'] == options['empty']
          disable_dhcp = "false"
        else
          disable_dhcp = "true"
        end
      else
        disable_dhcp = "true"
      end
    end

    name = "disable_dhcp"
    config = qs.new(
      type      = "boolean",
      question  = "Disable DHCP",
      ask       = "yes",
      parameter = "netcfg/disable_dhcp",
      value     = disable_dhcp,
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  name = "admin_fullname"
  config = qs.new(
    type      = "string",
    question  = "User full name",
    ask       = "yes",
    parameter = "passwd/user-fullname",
    value     = options['adminname'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_username"
  config = qs.new(
    type      = "string",
    question  = "Username",
    ask       = "yes",
    parameter = "passwd/username",
    value     = options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_shell"
  config = qs.new(
    type      = "string",
    question  = "Shell",
    ask       = "yes",
    parameter = "passwd/shell",
    value     = options['adminshell'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_sudo"
  config = qs.new(
    type      = "string",
    question  = "Sudo",
    ask       = "yes",
    parameter = "passwd/sudo",
    value     = options['adminsudo'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_password"
  config = qs.new(
    type      = "",
    question  = "User password",
    ask       = "yes",
    parameter = "",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_crypt"
  config = qs.new(
    type      = "password",
    question  = "User Password Crypt",
    ask       = "yes",
    parameter = "passwd/user-password-crypted",
    value     = get_password_crypt(options['adminpassword']),
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_groups"
  config = qs.new(
    type      = "string",
    question  = "User groups",
    ask       = "yes",
    parameter = "passwd/user-default-groups",
    value     = "wheel",
    valid     = "",
    eval      = ""
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if !options['method'] == "ci"

    name = "admin_home_encrypt"
    config = qs.new(
      type      = "boolean",
      question  = "Encrypt user home directory",
      ask       = "yes",
      parameter = "user-setup/encrypt-home",
      value     = "false",
      valid     = "",
      eval      = ""
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)
  
  end

  name = "locale"
  config = qs.new(
    type      = "string",
    question  = "Locale",
    ask       = "yes",
    parameter = "debian-installer/locale",
    value     = options['locale'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if options['vmnic'] == options['empty']
    if options['nic'] != options['empty']
      nic_name = options['nic']
    else
      nic_name = get_nic_name_from_install_service(options)
    end
  else
    if options['vmnic'] != options['empty']
      nic_name = options['vmnic'].to_s
    else
      if options['nic'] != options['empty']
        nic_name = options['nic']
      else
        nic_name = options['vmnic'].to_s
      end
    end
  end

  name = "interface"
  config = qs.new(
    type      = "select",
    question  = "Network interface",
    ask       = "yes",
    parameter = "netcfg/choose_interface",
    value     = nic_name,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  options['q_struct']['nic'] = options['q_struct']['interface']
  options['q_order'].push(name)


  if options['dnsmasq'] == true
    nameserver = options['vmgateway'].to_s+","+options['nameserver'].to_s
  else
    nameserver = options['nameserver'].to_s
  end

  name = "nameserver"
  config = qs.new(
    type      = "string",
    question  = "Nameservers",
    ask       = "yes",
    parameter = "netcfg/get_nameservers",
    value     = nameserver,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if options['q_struct']['disable_dhcp'].value.match(/true/)

    name = "ip"
    config = qs.new(
      type      = "string",
      question  = "IP address",
      ask       = "yes",
      parameter = "netcfg/get_ipaddress",
      value     = options['ip'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "netmask"
    config = qs.new(
      type      = "string",
      question  = "Netmask",
      ask       = "yes",
      parameter = "netcfg/get_netmask",
      value     = options['netmask'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  if options['service'].to_s.match(/live/) || options['vm'].to_s.match(/mp|multipass/)

    name = "cidr"
    config = qs.new(
      type      = "string",
      question  = "CIDR",
      ask       = "yes",
      parameter = "netcfg/get_cidr",
      value     = options['cidr'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end 

  if options['gateway'].to_s.match(/[0-9]/) and options['vm'].to_s == options['empty'].to_s
    gateway = options['gateway']
  else
    if options['vmgateway'].to_s.split(/\./)[2] == options['ip'].to_s.split(/\./)[2]
      gateway = options['vmgateway']
    else
      if options['gateway'].to_s.split(/\./)[2] == options['ip'].to_s.split(/\./)[2]
        gateway = options['gateway']
      else
        if options['vmgateway'].to_s.match(/[0-9]/)
          gateway = options['vmgateway']
        else
          if options['type'].to_s.match(/packer/)
            gateway = options['ip'].split(/\./)[0..2].join(".")+"."+options['gatewaynode']
          else
            if options['server'] == options['empty']
              gateway = options['hostip']
            else
              gateway = options['server']
            end
          end
        end
      end
    end
  end

  if gateway.to_s.split(/\./)[2] != options['ip'].to_s.split(/\./)[2]
    gateway = %x[netstat -rn |grep "^0" |awk '{print $2}'].chomp
  end

  name = "gateway"
  config = qs.new(
    type      = "string",
    question  = "Gateway",
    ask       = "yes",
    parameter = "netcfg/get_gateway",
    value     = gateway,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if options['q_struct']['disable_dhcp'].value.match(/true/)

    broadcast = options['ip'].split(/\./)[0..2].join(".")+".255"

    name = "broadcast"
    config = qs.new(
      type      = "",
      question  = "Broadcast",
      ask       = "yes",
      parameter = "",
      value     = broadcast,
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)
  
    network_address = options['ip'].split(/\./)[0..2].join(".")+".0"

    name = "network_address"
    config = qs.new(
      type      = "",
      question  = "Network Address",
      ask       = "yes",
      parameter = "",
      value     = network_address,
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  if options['dhcp'] == true
    static = "false"
  else
    static = "true"
  end

  name = "static"
  config = qs.new(
    type      = "boolean",
    question  = "Confirm Static",
    ask       = "yes",
    parameter = "netcfg/confirm_static",
    value     = static,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "hostname"
  config = qs.new(
    type      = "string",
    question  = "Hostname",
    ask       = "yes",
    parameter = "netcfg/get_hostname",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  #if options['service'].to_s.match(/ubuntu/)
  #  if options['service'].to_s.match(/18_04/) and options['vm'].to_s.match(/vbox/)
  #    options['vmnic'] = "eth0"
  #  else
  #    if options['vm'].to_s.match(/kvm/)
  #      options['vmnic'] = "ens3"
  #    else
  #      if options['service'].to_s.match(/16_10/)
  #        if options['vm'].to_s.match(/fusion/)
  #          options['vmnic'] = "ens33"
  #        else
  #          options['vmnic'] = "enp0s3"
  #        end
  #      end
  #    end
  #  end
  #end

#  name = "nic"
#  config = qs.new(
#    type      = "",
#    question  = "NIC",
#    ask       = "yes",
#    parameter = "",
#    value     = nic_name,
#    valid     = "",
#    eval      = "no"
#    )
#  options['q_struct'][name] = config
#  options['q_order'].push(name)

  client_domain = options['domainname'].to_s

  name = "domain"
  config = qs.new(
    type      = "string",
    question  = "Domainname",
    ask       = "yes",
    parameter = "netcfg/get_domain",
    value     = client_domain,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "timezone"
  config = qs.new(
    type      = "string",
    question  = "Timezone",
    ask       = "yes",
    parameter = "time/zone",
    value     = options['timezone'].to_s,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "timeserver"
  config = qs.new(
    type      = "string",
    question  = "Timeserer",
    ask       = "yes",
    parameter = "clock-setup/ntp-server",
    value     = options['timeserver'].to_s,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if options['service'].to_s.match(/purity/)

    if install_ip1.match(/[0-9]/)

      name = "eth1_ip"
      config = qs.new(
        type      = "string",
        question  = "IP address for eth1",
        ask       = "yes",
        parameter = "",
        value     = install_ip1,
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

      name = "eth1_service"
      config = qs.new(
        type      = "string",
        question  = "Service for eth1",
        ask       = "yes",
        parameter = "",
        value     = "management",
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

    end
    
    if install_ip2.match(/[0-9]/)

      name = "eth2_ip"
      config = qs.new(
        type      = "string",
        question  = "IP address for eth2",
        ask       = "yes",
        parameter = "",
        value     = install_ip2,
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

      name = "eth2_service"
      config = qs.new(
        type      = "string",
        question  = "Service for eth2",
        ask       = "yes",
        parameter = "",
        value     = "replication",
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

    end

    if install_ip3.match(/[0-9]/)

      name = "eth3_ip"
      config = qs.new(
        type      = "string",
        question  = "IP address for eth3",
        ask       = "yes",
        parameter = "",
        value     = install_ip3,
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

      name = "eth3_service"
      config = qs.new(
        type      = "string",
        question  = "Service for eth3",
        ask       = "yes",
        parameter = "",
        value     = "replication",
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

    end

    if install_ip4.match(/[0-9]/)

      name = "eth4_ip"
      config = qs.new(
        type      = "string",
        question  = "IP address for eth4",
        ask       = "yes",
        parameter = "",
        value     = install_ip4,
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name) 

      name = "eth4_service"
      config = qs.new(
        type      = "string",
        question  = "Service for eth4",
        ask       = "yes",
        parameter = "",
        value     = "iscsi",
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

    end
    
    if install_ip5.match(/[0-9]/)

      name = "eth5_ip"
      config = qs.new(
        type      = "string",
        question  = "IP address for eth5",
        ask       = "yes",
        parameter = "",
        value     = install_ip5,
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name) 

      name = "eth5_service"
      config = qs.new(
        type      = "string",
        question  = "Service for eth5",
        ask       = "yes",
        parameter = "",
        value     = "iscsi",
        valid     = "",
        eval      = "no"
      )
      options['q_struct'][name] = config
      options['q_order'].push(name)

    end

    return options
  end

  if !options['method'].to_s.match(/ci/)

    name = "firmware"
    config = qs.new(
      type      = "boolean",
      question  = "Prompt for firmware",
      ask       = "no",
      parameter = "hw-detect/load_firmware",
      value     = "false",
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "clock"
    config = qs.new(
      type      = "string",
      question  = "Hardware clock set to UTC",
      ask       = "yes",
      parameter = "clock-setup/utc",
      value     = "false",
      valid     = "false,true",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)
  
  end

#  name = "use_mirror"
#  config = qs.new(
#    type      = "boolean",
#    question  = "Use Mirror",
#    ask       = "no",
#    parameter = "apt-setup/use_mirror",
#    value     = options['usemirror'].to_s,
#    valid     = "",
#    eval      = "no"
#    )
#  options['q_struct'][name] = config
#  options['q_order'].push(name)

  name = "mirror_country"
  config = qs.new(
    type      = "string",
    question  = "Mirror country",
    ask       = "no",
    parameter = "mirror/country",
    value     = "manual",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "mirror_hostname"
  config = qs.new(
    type      = "string",
    question  = "Mirror hostname",
    ask       = "no",
    parameter = "mirror/http/hostname",
    #value     = mirror_hostname,
    value     = options['mirror'].to_s,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "mirror_directory"
  config = qs.new(
    type      = "string",
    question  = "Mirror directory",
    ask       = "no",
    parameter = "mirror/http/directory",
    #value     = "/"+options['service'],
    value     = options['mirrordir'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  #name = "mirror_url"
  #config = qs.new(
  #  type      = "string",
  #  question  = "Mirror URL",
  #  ask       = "no",
  #  parameter = "mirror/http/directory",
  #  #value     = "/"+options['service'],
  #  value     = options['mirrorurl'],
  #  valid     = "",
  #  eval      = "no"
  #  )
  #options['q_struct'][name] = config
  #options['q_order'].push(name)

  if !options['method'].to_s.match(/ci/)

    name = "mirror_proxy"
    config = qs.new(
      type      = "string",
      question  = "Mirror country",
      ask       = "no",
      parameter = "mirror/http/proxy",
      value     = "",
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "updates"
    config = qs.new(
      type      = "select",
      question  = "Update policy",
      ask       = "yes",
      parameter = "pkgsel/update-policy",
      value     = "none",
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  if options['software'].to_s.match(/[a-z]/)
    software = options['software']
  else
    software = "openssh-server"
  end

  name = "software"
  config = qs.new(
    type      = "multiselect",
    question  = "Software",
    ask       = "yes",
    parameter = "tasksel/first",
    value     = software,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if !options['method'].to_s.match(/ci/)

    name = "additional_packages"
    config = qs.new(
      type      = "string",
      question  = "Additional packages",
      ask       = "yes",
      parameter = "pkgsel/include",
      vaalue     = pkg_list.join(" "),
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  name = "exit"
  config = qs.new(
    type      = "boolean",
    question  = "Exit installer",
    ask       = "yes",
    parameter = "debian-installer/exit/halt",
    value     = "false",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "basicfilesystem_choose_label"
  config = qs.new(
    type      = "string",
    question  = "Basic Filesystem Chose Label",
    ask       = "no",
    parameter = "partman-basicfilesystems/choose_label",
    value     = "gpt",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "basicfilesystem_default_label"
  config = qs.new(
    type      = "string",
    question  = "Basic Filesystem Default Label",
    ask       = "no",
    parameter = "partman-basicfilesystems/default_label",
    value     = "gpt",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_choose_label"
  config = qs.new(
    type      = "string",
    question  = "Partition Chose Label",
    ask       = "no",
    parameter = "partman-partitioning/choose_label",
    value     = "gpt",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_default_label"
  config = qs.new(
    type      = "string",
    question  = "Partition Default Label",
    ask       = "no",
    parameter = "partman-partitioning/default_label",
    value     = "gpt",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "choose_label"
  config = qs.new(
    type      = "string",
    question  = "Partition Chose Label",
    ask       = "no",
    parameter = "partman/choose_label",
    value     = "gpt",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "default_label"
  config = qs.new(
    type      = "string",
    question  = "Partition Default Label",
    ask       = "no",
    parameter = "partman/default_label",
    value     = "gpt",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_disk"
  config = qs.new(
    type      = "string",
    question  = "Parition disk",
    ask       = "yes",
    parameter = "partman-auto/disk",
    value     = options['rootdisk'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_method"
  config = qs.new(
    type      = "string",
    question  = "Parition method",
    ask       = "yes",
    parameter = "partman-auto/method",
    value     = "lvm",
    valid     = "regular,lvm,crypto",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "remove_existing_lvm"
  config = qs.new(
    type      = "boolean",
    question  = "Remove existing LVM devices",
    ask       = "yes",
    parameter = "partman-lvm/device_remove_lvm",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "remove_existing_md"
  config = qs.new(
    type      = "boolean",
    question  = "Remove existing MD devices",
    ask       = "yes",
    parameter = "partman-md/device_remove_md",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_write"
  config = qs.new(
    type      = "boolean",
    question  = "Write parition",
    ask       = "yes",
    parameter = "partman-lvm/confirm",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_overwrite"
  config = qs.new(
    type      = "boolean",
    question  = "Overwrite existing parition",
    ask       = "yes",
    parameter = "partman-lvm/confirm_nooverwrite",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name) 

  name = "partition_size"
  config = qs.new(
    type      = "string",
    question  = "Partition size",
    ask       = "yes",
    parameter = "partman-auto-lvm/guided_size",
    value     = "max",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name) 

  name = "filesystem_type"
  config = qs.new(
    type      = "string",
    question  = "Write partition label",
    ask       = "yes",
    parameter = "partman/default_filesystem",
    value     = "ext4",
    valid     = "ext3,ext4,xfs",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "volume_name"
  config = qs.new(
    type      = "string",
    question  = "Volume name",
    ask       = "yes",
    parameter = "partman-auto-lvm/new_vg_name",
    value     = options['vgname'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if options['splitvols'] == true

    name = "filesystem_layout"
    config = qs.new(
      type      = "select",
      question  = "Filesystem recipe",
      ask       = "yes",
      parameter = "partman-auto/choose_recipe",
      value     = "boot-root",
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "filesystem_recipe"
    config = qs.new(
      type      = "string",
      question  = "Filesystem layout",
      ask       = "yes",
      parameter = "partman-auto/expert_recipe",
      value     = "\\\n"+
                  "boot-root :: \\\n"+
                  "#{options['bootsize']} 10 #{options['bootsize']} #{options['bootfs']} \\\n"+
                  "$primary{ } \\\n"+
                  "$bootable{ } \\\n"+
                  "$defaultignore{ } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['bootfs']} } \\\n"+
                  "mountpoint{ /boot } \\\n"+
                  ".\\\n"+
                  "#{options['swapsize']} 20 #{options['swapsize']} #{options['swapfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "format{ } \\\n"+
                  "lv_name{ swap } \\\n"+
                  "method{ swap } \\\n"+
                  ".\\\n"+
                  "#{options['rootsize']} 30 #{options['rootsize']} #{options['rootfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ root } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['rootfs']} } \\\n"+
                  "mountpoint{ / } \\\n"+
                  ".\\\n"+
                  "#{options['tmpsize']} 40 #{options['tmpsize']} #{options['tmpfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ tmp } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['tmpfs']} } \\\n"+
                  "mountpoint{ /tmp } \\\n"+
                  ".\\\n"+
                  "#{options['varsize']} 50 #{options['varsize']} #{options['varfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ var } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['varfs']} } \\\n"+
                  "mountpoint{ /var } \\\n"+
                  ".\\\n"+
                  "#{options['logsize']} 60 #{options['logsize']} #{options['logfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ log } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['logfs']} } \\\n"+
                  "mountpoint{ /var/log } \\\n"+
                  ".\\\n"+
                  "#{options['usrsize']} 70 #{options['usrsize']} #{options['usrfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ usr } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['usrfs']} } \\\n"+
                  "mountpoint{ /usr } \\\n"+
                  ".\\\n"+
                  "#{options['localsize']} 80 #{options['localsize']} #{options['localfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ local } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['localfs']} } \\\n"+
                  "mountpoint{ /usr/local } \\\n"+
                  ".\\\n"+
                  "#{options['homesize']} 90 #{options['homesize']} #{options['homefs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ home } \\\n"+
                  "method{ format } \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['homefs']} } \\\n"+
                  "mountpoint{ /home } \\\n"+
                  ".\\\n"+
                  "#{options['scratchsize']} 95 -1 #{options['scratchfs']} \\\n"+
                  "$defaultignore{ } \\\n"+
                  "$lvmok{ } \\\n"+
                  "in_vg { #{options['vgname']} } \\\n"+
                  "lv_name{ scratch } \\\n"+
                  "method{ format }  \\\n"+
                  "format{ } \\\n"+
                  "use_filesystem{ } \\\n"+
                  "filesystem{ #{options['scratchfs']} } \\\n"+
                  "mountpoint{ /scratch } \\\n"+
                  ".",
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)
  
  else

    name = "filesystem_layout"
    config = qs.new(
      type      = "select",
      question  = "Filesystem layout",
      ask       = "yes",
      parameter = "partman-auto/choose_recipe",
      value     = "atomic",
      valid     = "string,atomic,home,multi",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end

  name = "partition_label"
  config = qs.new(
    type      = "boolean",
    question  = "Write partition label",
    ask       = "no",
    parameter = "partman-partitioning/confirm_write_new_label",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_finish"
  config = qs.new(
    type      = "select",
    question  = "Finish partition",
    ask       = "no",
    parameter = "partman/choose_partition",
    value     = "finish",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_confirm"
  config = qs.new(
    type      = "boolean",
    question  = "Confirm partition",
    ask       = "no",
    parameter = "partman/confirm",
    value     = "true",
    valid     = "true,faule",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "partition_nooverwrite"
  config = qs.new(
    type      = "boolean",
    question  = "Don't overwrite partition",
    ask       = "no",
    parameter = "partman/confirm_nooverwrite",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "kernel_image"
  config = qs.new(
    type      = "string",
    question  = "Kernel image",
    ask       = "yes",
    parameter = "base-installer/kernel/image",
    value     = "linux-generic",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "additional_packages"
  config = qs.new(
    type      = "string",
    question  = "Additional packages",
    ask       = "yes",
    parameter = "pkgsel/include",
    value     = pkg_list.join(" "),
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "root_login"
  config = qs.new(
    type      = "boolean",
    question  = "Root login",
    ask       = "yes",
    parameter = "passwd/root-login",
    value     = "false",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "make_user"
  config = qs.new(
    type      = "boolean",
    question  = "Create user",
    ask       = "yes",
    parameter = "passwd/make-user",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "root_password"
  config = qs.new(
    type      = "",
    question  = "Root password",
    ask       = "yes",
    parameter = "",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "root_crypt"
  config = qs.new(
    type      = "password",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "passwd/root-password-crypted",
    value     = get_password_crypt(options['rootpassword']),
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "install_grub_mbr"
  config = qs.new(
    type      = "boolean",
    question  = "Install grub",
    ask       = "yes",
    parameter = "grub-installer/only_debian",
    value     = "true",
    valid     = "",
    eval      = ""
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "install_grub_bootdev"
  config = qs.new(
    type      = "string",
    question  = "Install grub to device",
    ask       = "yes",
    parameter = "grub-installer/bootdev",
    value     = options['rootdisk'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "reboot_note"
  config = qs.new(
    type      = "note",
    question  = "Install grub",
    ask       = "no",
    parameter = "finish-install/reboot_in_progress",
    value     = "",
    valid     = "",
    eval      = ""
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  if options['type'].to_s.match(/packer/)
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      if options['host-os-uname'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        script_url = "http://"+options['hostip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_post.sh"
      else
        script_url = "http://"+gateway+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_post.sh"
      end
    else
      if options['host-os-uname'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        script_url = "http://"+options['hostip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_post.sh"
      else
        script_url = "http://"+options['hostonlyip'].to_s+":"+options['httpport'].to_s+"/"+options['vm'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_post.sh"
      end
    end
  else
    if options['server'] == options['empty']
      script_url = "http://"+options['hostip'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_post.sh"
    else
      script_url = "http://"+options['server'].to_s+"/"+options['name'].to_s+"/"+options['name'].to_s+"_post.sh"
    end
  end

#  if not options['type'].to_s.match(/packer/)

    name = "late_command"
    config = qs.new(
      type      = "string",
      question  = "Post install commands",
      ask       = "yes",
      parameter = "preseed/late_command",
      value     = "in-target wget -O /tmp/post_install.sh #{script_url} ; in-target chmod 700 /tmp/post_install.sh ; in-target sh /tmp/post_install.sh",
      valid     = "",
      eval      = ""
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

#  end
  
  return options
end
