# LXC quextions

def populate_lxc_client_questions(values)
  lx = Struct.new(:question, :ask, :value, :valid, :eval)

  name   = "root_password"
  config = lx.new(
    question  = "Root password",
    ask       = "yes",
    value     = values['rootpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_crypt"
  config = lx.new(
    question  = "Root Password Crypt",
    ask       = "yes",
    value     = "get_root_password_crypt(values)",
    valid     = "",
    eval      = "get_root_password_crypt(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_fullname"
  config = lx.new(
    question  = "User full name",
    ask       = "yes",
    value     = values['adminname'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_username"
  config = lx.new(
    question  = "Username",
    ask       = "yes",
    value     = values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_uid"
  config = lx.new(
    question  = "User UID",
    ask       = "yes",
    value     = values['adminuid'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_group"
  config = lx.new(
    question  = "User Group",
    ask       = "yes",
    value     = values['admingroup'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_gid"
  config = lx.new(
    question  = "User GID",
    ask       = "yes",
    value     = values['admingid'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_home"
  config = lx.new(
    question  = "User Home Directory",
    ask       = "yes",
    value     = values['adminhome'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_shell"
  config = lx.new(
    question  = "User Shell",
    ask       = "yes",
    value     = values['adminshell'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_password"
  config = lx.new(
    question  = "User password",
    ask       = "yes",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_crypt"
  config = lx.new(
    question  = "User Password Crypt",
    ask       = "yes",
    value     = "get_admin_password_crypt(values)",
    valid     = "",
    eval      = "get_admin_password_crypt(values)"
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

  name   = "nameserver"
  config = lx.new(
    question  = "Nameservers",
    ask       = "yes",
    value     = values['nameserver'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ip"
  config = lx.new(
    question  = "IP address",
    ask       = "yes",
    value     = values['ip'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "netmask"
  config = lx.new(
    question  = "Netmask",
    ask       = "yes",
    value     = values['netmask'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = values['ip'].split(/\./)[0..2].join(".")+"."+values['gatewaynode']

  name   = "gateway"
  config = lx.new(
    question  = "Gateway",
    ask       = "yes",
    value     = gateway,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = values['ip'].split(/\./)[0..2].join(".")+".255"

  name   = "broadcast"
  config = lx.new(
    question  = "Broadcast",
    ask       = "yes",
    value     = broadcast,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = values['ip'].split(/\./)[0..2].join(".")+".0"

  name   = "network_address"
  config = lx.new(
    question  = "Network Address",
    ask       = "yes",
    value     = network_address,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end

# LXC server populate_lxc_client_questions

def populate_lxc_server_questions(values)
  lx = Struct.new(:question, :ask, :value, :valid, :eval)

  name   = "nameserver"
  config = lx.new(
    question  = "Nameservers",
    ask       = "yes",
    value     = values['nameserver'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ip"
  config = lx.new(
    question  = "IP address",
    ask       = "yes",
    value     = values['hostip'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "netmask"
  config = lx.new(
    question  = "Netmask",
    ask       = "yes",
    value     = values['netmask'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = values['hostip'].split(/\./)[0..2].join(".")+"."+values['gatewaynode']

  name   = "gateway"
  config = lx.new(
    question  = "Gateway",
    ask       = "yes",
    value     = gateway,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = values['hostip'].split(/\./)[0..2].join(".")+".255"

  name   = "broadcast"
  config = lx.new(
    question  = "Broadcast",
    ask       = "yes",
    value     = broadcast,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = values['hostip'].split(/\./)[0..2].join(".")+".0"

  name   = "network_address"
  config = lx.new(
    question  = "Network Address",
    ask       = "yes",
    value     = network_address,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end
