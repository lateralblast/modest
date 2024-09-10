# LXC quextions

def populate_lxc_client_questions(options)
  lx = Struct.new(:question, :ask, :value, :valid, :eval)

  name = "root_password"
  config = lx.new(
    question  = "Root password",
    ask       = "yes",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "root_crypt"
  config = lx.new(
    question  = "Root Password Crypt",
    ask       = "yes",
    value     = "get_root_password_crypt()",
    valid     = "",
    eval      = "get_root_password_crypt()"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_fullname"
  config = lx.new(
    question  = "User full name",
    ask       = "yes",
    value     = options['adminname'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_username"
  config = lx.new(
    question  = "Username",
    ask       = "yes",
    value     = options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_uid"
  config = lx.new(
    question  = "User UID",
    ask       = "yes",
    value     = options['adminuid'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_group"
  config = lx.new(
    question  = "User Group",
    ask       = "yes",
    value     = options['admingroup'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_gid"
  config = lx.new(
    question  = "User GID",
    ask       = "yes",
    value     = options['admingid'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_home"
  config = lx.new(
    question  = "User Home Directory",
    ask       = "yes",
    value     = options['adminhome'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_shell"
  config = lx.new(
    question  = "User Shell",
    ask       = "yes",
    value     = options['adminshell'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_password"
  config = lx.new(
    question  = "User password",
    ask       = "yes",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_crypt"
  config = lx.new(
    question  = "User Password Crypt",
    ask       = "yes",
    value     = "get_admin_password_crypt()",
    valid     = "",
    eval      = "get_admin_password_crypt()"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

name = "nameserver"
  config = lx.new(
    question  = "Nameservers",
    ask       = "yes",
    value     = options['nameserver'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ip"
  config = lx.new(
    question  = "IP address",
    ask       = "yes",
    value     = options['ip'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "netmask"
  config = lx.new(
    question  = "Netmask",
    ask       = "yes",
    value     = options['netmask'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  gateway = options['ip'].split(/\./)[0..2].join(".")+"."+options['gatewaynode']

  name = "gateway"
  config = lx.new(
    question  = "Gateway",
    ask       = "yes",
    value     = gateway,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  broadcast = options['ip'].split(/\./)[0..2].join(".")+".255"

  name = "broadcast"
  config = lx.new(
    question  = "Broadcast",
    ask       = "yes",
    value     = broadcast,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  network_address = options['ip'].split(/\./)[0..2].join(".")+".0"

  name = "network_address"
  config = lx.new(
    question  = "Network Address",
    ask       = "yes",
    value     = network_address,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  return options
end

# LXC server populate_lxc_client_questions

def populate_lxc_server_questions(options)
  lx = Struct.new(:question, :ask, :value, :valid, :eval)

  name = "nameserver"
  config = lx.new(
    question  = "Nameservers",
    ask       = "yes",
    value     = options['nameserver'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ip"
  config = lx.new(
    question  = "IP address",
    ask       = "yes",
    value     = options['hostip'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "netmask"
  config = lx.new(
    question  = "Netmask",
    ask       = "yes",
    value     = options['netmask'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  gateway = options['hostip'].split(/\./)[0..2].join(".")+"."+options['gatewaynode']

  name = "gateway"
  config = lx.new(
    question  = "Gateway",
    ask       = "yes",
    value     = gateway,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  broadcast = options['hostip'].split(/\./)[0..2].join(".")+".255"

  name = "broadcast"
  config = lx.new(
    question  = "Broadcast",
    ask       = "yes",
    value     = broadcast,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  network_address = options['hostip'].split(/\./)[0..2].join(".")+".0"

  name = "network_address"
  config = lx.new(
    question  = "Network Address",
    ask       = "yes",
    value     = network_address,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  return options
end
