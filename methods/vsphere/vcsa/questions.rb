
# Code for VC

# Configuration questions for VCSA

def populate_vcsa_questions(values)

  # values['answers'] = {}
  # values['order']  = []

  values['ip'] = single_install_ip(values)

  name   = "headless_mode"
  config = Js.new(
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

  name   = "esx.hostname"
  config = Ks.new(
    type      = "string",
    question  = "ESX Server Hostname",
    ask       = "yes",
    parameter = "esx.hostname",
    value     = values['server'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "esx.datastore"
  config = Ks.new(
    type      = "string",
    question  = "Datastore",
    ask       = "yes",
    parameter = "esx.datastore",
    value     = values['datastore'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "esx.username"
  config = Ks.new(
    type      = "string",
    question  = "ESX Username",
    ask       = "yes",
    parameter = "esx.username",
    value     = values['serveradmin'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "esx.password"
  config = Ks.new(
    type      = "string",
    question  = "ESX Password",
    ask       = "no",
    parameter = "esx.password",
    value     = values['serverpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "deployment.option"
  config = Ks.new(
    type      = "string",
    question  = "Deployment Option",
    ask       = "no",
    parameter = "deployment.option",
    value     = values['size'],
    valid     = "",
    eval      = "no"
    )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "deployment.network"
  config = Ks.new(
    type      = "string",
    question  = "Deployment Network",
    ask       = "yes",
    parameter = "deployment.network",
    value     = values['servernetmask'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "appliance.name"
  config = Ks.new(
    type      = "string",
    question  = "Appliance Name",
    ask       = "yes",
    parameter = "appliance.name",
    value     = values['name'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "appliance.thin.disk.mode"
  config = Ks.new(
    type      = "boolean",
    question  = "Appliance Disk Mode",
    ask       = "yes",
    parameter = "appliance.thin.disk.mode",
    value     = "true",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root.password"
  config = Ks.new(
    type      = "string",
    question  = "Root Password",
    ask       = "yes",
    parameter = "root.password",
    value     = values['rootpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ssh.enable"
  config = Ks.new(
    type      = "boolean",
    question  = "SSH Enable",
    ask       = "yes",
    parameter = "ssh.enable",
    value     = values['sshenadble'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ntp.servers"
  config = Ks.new(
    type      = "string",
    question  = "NTP Servers",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = values['timeserver'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "password"
  config = Ks.new(
    type      = "string",
    question  = "SSO password",
    ask       = "yes",
    parameter = "password",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "domain-name"
  config = Ks.new(
    type      = "string",
    question  = "NTP Servers",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = values['domainname'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "site-name"
  config = Ks.new(
    type      = "string",
    question  = "Site Name",
    ask       = "yes",
    parameter = "ntp.servers",
    value     = values['domainname'].split(/\./)[0],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ip.family"
  config = Ks.new(
    type      = "string",
    question  = "IP Family",
    ask       = "yes",
    parameter = "ip.family",
    value     = values['ipfamily'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "mode"
  config = Ks.new(
    type      = "string",
    question  = "IP Configuration",
    ask       = "yes",
    parameter = "mode",
    value     = "static",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ip"
  config = Ks.new(
    type      = "string",
    question  = "IP Address",
    ask       = "yes",
    parameter = "ip",
    value     = values['ip'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "prefix"
  config = Ks.new(
    type      = "string",
    question  = "Subnet Mask",
    ask       = "yes",
    parameter = "prefix",
    value     = values['netmask'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = values['ip'].split(/\./)[0..2].join(".")+"."+values['gatewaynode']

  name   = "gateway"
  config = Ks.new(
    type      = "string",
    question  = "Gateway",
    ask       = "yes",
    parameter = "netcfg/get_gateway",
    value     = gateway,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "dns.servers"
  config = Ks.new(
    type      = "string",
    question  = "Nameserver(s)",
    ask       = "yes",
    parameter = "dns.servers",
    value     = values['nameserver'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system.name"
  config = Ks.new(
    type      = "string",
    question  = "Hostname",
    ask       = "yes",
    parameter = "system.name",
    value     = values['ip'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return
end
