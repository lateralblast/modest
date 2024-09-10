
# Questions for ks

# Construct ks network line

def get_vs_network(options)
  if options['q_struct']['bootproto'].value.match(/dhcp/)
    result = "--netdevice "+options['q_struct']['nic'].value+" --bootproto "+options['q_struct']['bootproto'].value
  else
    options['ip'] = options['q_struct']['ip'].value
    options['name'] = options['q_struct']['hostname'].value
    gateway = get_ipv4_default_route(options)
    result = "--device="+options['q_struct']['nic'].value+" --bootproto="+options['q_struct']['bootproto'].value+" --ip="+options['ip']+" --netmask="+options['netmask']+" --gateway="+gateway+" --nameserver="+options['nameserver']+" --hostname="+options['name']+" --addvmportgroup=0"
  end
  return result
end

# Set network

def set_vs_network(options)
  if options['q_struct']['bootproto'].value.match(/dhcp/)
    options['q_struct']['ip'].ask = "no"
    options['q_struct']['ip'].type = ""
    options['q_struct']['hostname'].ask = "no"
    options['q_struct']['hostname'].type = ""
  end
  return options
end

# Construct ks password line

def get_vs_password(options)
  result = "--iscrypted "+options['q_struct']['root_crypt'].value.to_s
  return result
end

# Get install url

def get_vs_install_url(options)
  install_url = "http://"+options['hostip']+"/"+options['service']
  return install_url
end

# Get kickstart header

def get_vs_header(options)
  version = get_version()
  version = version.join(" ")
  header  = "# kickstart file for "+options['name']+" "+version
  return header
end

# Populate ks questions

def populate_vs_questions(options)
  vs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  options['ip'] = single_install_ip(options)

  name = "headless_mode"
  config = vs.new(
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

  name   = "ks_header"
  config = vs.new(
    type      = "output",
    question  = "VSphere file header comment",
    ask       = "yes",
    parameter = "",
    value     = get_vs_header(options),
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "vmaccepteula"
  config = vs.new(
    type      = "output",
    question  = "Accept EULA",
    ask       = "yes",
    parameter = "",
    value     = "vmaccepteula",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "install"
  config = vs.new(
    type      = "output",
    question  = "Install type",
    ask       = "yes",
    parameter = "install",
    value     = "--firstdisk --overwritevmfs",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "nic"
  config = vs.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = "vmnic0",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "bootproto"
  config = vs.new(
    type      = "",
    question  = "Boot Protocol",
    ask       = "yes",
    parameter = "",
    value     = "static",
    valid     = "static,dhcp",
    eval      = "options = set_vs_network(options)"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "hostname"
  config = vs.new(
    type      = "",
    question  = "Hostname",
    ask       = "yes",
    parameter = "",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "ip"
  config = vs.new(
    type      = "",
    question  = "IP",
    ask       = "yes",
    parameter = "",
    value     = options['ip'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "network"
  config = vs.new(
    type      = "output",
    question  = "Network Configuration",
    ask       = "yes",
    parameter = "network",
    value     = "get_vs_network(options)",
    valid     = "",
    eval      = "get_vs_network(options)"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "datastore"
  config = vs.new(
    type      = "",
    question  = "Local datastore name",
    ask       = "yes",
    parameter = "",
    value     = options['datastore'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "vm_network_name"
  config = vs.new(
    type      = "",
    question  = "VM network name",
    ask       = "yes",
    parameter = "",
    value     = options['servernetwork'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "vm_network_vlanid"
  config = vs.new(
    type      = "",
    question  = "VM network VLAN ID",
    ask       = "yes",
    parameter = "",
    value     = options['vlanid'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "vm_network_vswitch"
  config = vs.new(
    type      = "",
    question  = "VM network vSwitch",
    ask       = "yes",
    parameter = "",
    value     = options['vswitch'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "root_password"
  config = vs.new(
    type      = "",
    question  = "Root Password",
    ask       = "yes",
    parameter = "",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "root_crypt"
  config = vs.new(
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_root_password_crypt(options)",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "rootpw"
  config = vs.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_vs_password(options)",
    valid     = "",
    eval      = "get_vs_password(options)"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name   = "finish"
  config = vs.new(
    type      = "output",
    question  = "Finish Command",
    ask       = "yes",
    parameter = "",
    value     = "reboot",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)
  return options
end
