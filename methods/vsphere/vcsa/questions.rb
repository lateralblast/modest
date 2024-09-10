
# Code for VC

# Configuration questions for VCSA

def populate_vcsa_questions(options)

  # options['q_struct'] = {}
  # options['q_order']  = []

  options['ip'] = single_install_ip(options)

  name = "headless_mode"
  config = Js.new(
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

  name = "esx.hostname"
  config = Ks.new(
    type      = "string",
    question  = "ESX Server Hostname",
    ask       = "yes",
    parameter = "esx.hostname",
    value     = options['server'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "esx.datastore"
  config = Ks.new(
    type      = "string",
    question  = "Datastore",
    ask       = "yes",
    parameter = "esx.datastore",
    value     = options['datastore'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "esx.username"
  config = Ks.new(
    type      = "string",
    question  = "ESX Username",
    ask       = "yes",
    parameter = "esx.username",
    value     = options['serveradmin'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "esx.password"
  config = Ks.new(
    type      = "string",
    question  = "ESX Password",
    ask       = "no",
    parameter = "esx.password",
    value     = options['serverpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "deployment.option"
  config = Ks.new(
    type      = "string",
    question  = "Deployment Option",
    ask       = "no",
    parameter = "deployment.option",
    value     = options['size'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "deployment.network"
  config = Ks.new(
    type      = "string",
    question  = "Deployment Network",
    ask       = "yes",
    parameter = "deployment.network",
    value     = options['servernetmask'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "appliance.name"
  config = Ks.new(
    type      = "string",
    question  = "Appliance Name",
    ask       = "yes",
    parameter = "appliance.name",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "appliance.thin.disk.mode"
  config = Ks.new(
    type      = "boolean",
    question  = "Appliance Disk Mode",
    ask       = "yes",
    parameter = "appliance.thin.disk.mode",
    value     = "true",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "root.password"
  config = Ks.new(
    type      = "string",
    question  = "Root Password",
    ask       = "yes",
    parameter = "root.password",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ssh.enable"
  config = Ks.new(
    type      = "boolean",
    question  = "SSH Enable",
    ask       = "yes",
    parameter = "ssh.enable",
    value     = options['sshenadble'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ntp.servers"
  config = Ks.new(
    type      = "string",
    question  = "NTP Servers",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = options['timeserver'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "password"
  config = Ks.new(
    type      = "string",
    question  = "SSO password",
    ask       = "yes",
    parameter = "password",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "domain-name"
  config = Ks.new(
    type      = "string",
    question  = "NTP Servers",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = options['domainname'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "site-name"
  config = Ks.new(
    type      = "string",
    question  = "Site Name",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = options['domainname'].split(/\./)[0],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ip.family"
  config = Ks.new(
    type      = "string",
    question  = "IP Family",
    ask       = "yes",
    parameter = "ip.family",
    value     = options['ipfamily'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "mode"
  config = Ks.new(
    type      = "string",
    question  = "IP Configuration",
    ask       = "yes",
    parameter = "mode",
    value     = "static",
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "ip"
  config = Ks.new(
    type      = "string",
    question  = "IP Address",
    ask       = "yes",
    parameter = "ip",
    value     = options['ip'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "prefix"
  config = Ks.new(
    type      = "string",
    question  = "Subnet Mask",
    ask       = "yes",
    parameter = "prefix",
    value     = options['netmask'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  gateway = options['ip'].split(/\./)[0..2].join(".")+"."+options['gatewaynode']

  name = "gateway"
  config = Ks.new(
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

  name = "dns.servers"
  config = Ks.new(
    type      = "string",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "dns.servers",
    value     = options['nameserver'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "system.name"
  config = Ks.new(
    type      = "string",
    question  = "Hostname",
    ask       = "yes",
    parameter = "system.name",
    value     = options['ip'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  return
end
