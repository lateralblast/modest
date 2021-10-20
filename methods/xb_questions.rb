# Questions for *BSD and other (e.g. CoreOS)

# Populate CoreOS questions

def populate_coreos_questions(options)

  # options['q_struct'] = {}
  # options['q_order']  = []

  options['ip'] = single_install_ip(options)

  name = "hostname"
  config = Ks.new(
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

  name = "nic"
  config = Ks.new(
    type      = "",
    question  = "Primary Network Interface",
    ask       = "yes",
    parameter = "",
    value     = options['vmnet'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ip"
  config = Ks.new(
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

  name = "netmask"
  config = Ks.new(
    type      = "",
    question  = "Netmask",
    ask       = "yes",
    parameter = "",
    value     = options['netmask'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "nameserver"
  config = Ks.new(
    type      = "",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "",
    value     = options['nameserver'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  gateway = options['ip'].split(/\./)[0..2].join(".")+"."+options['gatewaynode']

  name = "gateway"
  config = Ks.new(
    type      = "",
    question  = "Gateway",
    ask       = "yes",
    parameter = "",
    value     = gateway,
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  broadcast = options['ip'].split(/\./)[0..2].join(".")+".255"

  name = "broadcast"
  config = Ks.new(
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
  config = Ks.new(
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

  name = "root_password"
  config = Ks.new(
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

  name = "root_crypt"
  config = Ks.new(
    type      = "",
    question  = "Root Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_root_password_crypt()",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "rootpw"
  config = Ks.new(
    type      = "output",
    question  = "Root Password Configuration",
    ask       = "yes",
    parameter = "rootpw",
    value     = "get_ks_root_password()",
    valid     = "",
    eval      = "get_ks_root_password()"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_user"
  config = Ks.new(
    type      = "",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_uid"
  config = Ks.new(
    type      = "",
    question  = "Admin User ID",
    ask       = "yes",
    parameter = "",
    value     = options['adminuid'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_shell"
  config = Ks.new(
    type      = "",
    question  = "Admin User Shell",
    parameter = "",
    value     = options['adminshell'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_home"
  config = Ks.new(
    type      = "",
    question  = "Admin User Home Directory",
    ask       = "yes",
    parameter = "",
    value     = "/home/"+options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_group"
  config = Ks.new(
    type      = "",
    question  = "Admin User Group",
    ask       = "yes",
    parameter = "",
    value     = options['admingroup'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_gid"
  config = Ks.new(
    type      = "",
    question  = "Admin Group ID",
    ask       = "yes",
    parameter = "",
    value     = options['admingid'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_password"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password",
    ask       = "yes",
    parameter = "",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_crypt"
  config = Ks.new(
    type      = "",
    question  = "Admin User Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = "get_admin_password_crypt()",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

end

def create_coreos_client_config()
end
