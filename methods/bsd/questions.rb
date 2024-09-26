# Questions for *BSD and other (e.g. CoreOS)

# Populate CoreOS questions

def populate_coreos_questions(values)

  # values['answers'] = {}
  # values['order']  = []

  values['ip'] = single_install_ip(values)

  name   = "hostname"
  config = Ks.new (
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

  name   = "nic"
  config = Ks.new (
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = values['vmnet'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ip"
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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

  gateway = values['ip'].split(/\./)[0..2].join(".")+"."+values['gatewaynode']

  name   = "gateway"
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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

  name   = "root_password"
  config = Ks.new (
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
  config = Ks.new (
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_root_password_crypt()",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rootpw"
  config = Ks.new (
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_ks_root_password()",
    valid     = "",
    eval      = "get_ks_root_password()"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_user"
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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
  config = Ks.new (
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

  name = "admin_crypt"
  config = Ks.new (
    type      = "",
    question  = "Admin User Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_admin_password_crypt()",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

end

def create_coreos_client_config()
end
