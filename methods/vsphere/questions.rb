
# Questions for ks

# Construct ks network line

def get_vs_network(values)
  if values['answers']['bootproto'].value.match(/dhcp/)
    result = "--netdevice "+values['answers']['nic'].value+" --bootproto "+values['answers']['bootproto'].value
  else
    values['ip'] = values['answers']['ip'].value
    values['name'] = values['answers']['hostname'].value
    gateway = get_ipv4_default_route(values)
    result = "--device="+values['answers']['nic'].value+" --bootproto="+values['answers']['bootproto'].value+" --ip="+values['ip']+" --netmask="+values['netmask']+" --gateway="+gateway+" --nameserver="+values['nameserver']+" --hostname="+values['name']+" --addvmportgroup=0"
  end
  return result
end

# Set network

def set_vs_network(values)
  if values['answers']['bootproto'].value.match(/dhcp/)
    values['answers']['ip'].ask = "no"
    values['answers']['ip'].type = ""
    values['answers']['hostname'].ask = "no"
    values['answers']['hostname'].type = ""
  end
  return values
end

# Construct ks password line

def get_vs_password(values)
  result = "--iscrypted "+values['answers']['root_crypt'].value.to_s
  return result
end

# Get install url

def get_vs_install_url(values)
  install_url = "http://"+values['hostip']+"/"+values['service']
  return install_url
end

# Get kickstart header

def get_vs_header(values)
  version = get_version()
  version = version.join(" ")
  header  = "# kickstart file for "+values['name']+" "+version
  return header
end

# Populate ks questions

def populate_vs_questions(values)
  vs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  name   = "headless_mode"
  config = vs.new(
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

  name   = "ks_header"
  config = vs.new(
    type      = "output",
    question  = "VSphere file header comment",
    ask       = "yes",
    parameter = "",
    value     = get_vs_header(values),
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

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
  values['answers'][name] = config
  values['order'].push(name)

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
  values['answers'][name] = config
  values['order'].push(name)

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
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bootproto"
  config = vs.new(
    type      = "",
    question  = "Boot Protocol",
    ask       = "yes",
    parameter = "",
    value     = "static",
    valid     = "static,dhcp",
    eval      = "values = set_vs_network(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "hostname"
  config = vs.new(
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
  config = vs.new(
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

  name   = "network"
  config = vs.new(
    type      = "output",
    question  = "Network Configuration",
    ask       = "yes",
    parameter = "network",
    value     = "get_vs_network(values)",
    valid     = "",
    eval      = "get_vs_network(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "datastore"
  config = vs.new(
    type      = "",
    question  = "Local datastore name",
    ask       = "yes",
    parameter = "",
    value     = values['datastore'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "vm_network_name"
  config = vs.new(
    type      = "",
    question  = "VM network name",
    ask       = "yes",
    parameter = "",
    value     = values['servernetwork'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "vm_network_vlanid"
  config = vs.new(
    type      = "",
    question  = "VM network VLAN ID",
    ask       = "yes",
    parameter = "",
    value     = values['vlanid'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "vm_network_vswitch"
  config = vs.new(
    type      = "",
    question  = "VM network vSwitch",
    ask       = "yes",
    parameter = "",
    value     = values['vswitch'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_password"
  config = vs.new(
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
  config = vs.new(
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
  config = vs.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_vs_password(values)",
    valid     = "",
    eval      = "get_vs_password(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

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
  values['answers'][name] = config
  values['order'].push(name)
  return values
end
