# Preseed configuration questions for Windows

def populate_pe_questions(values)

  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)
  if values['label'].to_s.match(/20[1,2][0-9]/)
    if values['vm'].to_s.match(/fusion/)
      network_name = "Ethernet0"
    else
      network_name = "Ethernet"
    end
  else
    network_name = "Local Area Connection"
  end

  # values['answers'] = {}
  # values['order']  = []

  name   = "headless_mode"
  config = qs.new (
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

  name   = "values['label']"
  config = qs.new (
    type      = "string",
    question  = "Installation Label",
    ask       = "yes",
    parameter = "",
    value     = values['label'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "cpu_arch"
  config = qs.new (
    type      = "string",
    question  = "CPU Architecture",
    ask       = "yes",
    parameter = "",
    value     = values['arch'].gsub(/x86_64/,"amd64"),
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "boot_disk_size"
  config = qs.new (
    type      = "string",
    question  = "Boot disk size",
    ask       = "yes",
    parameter = "",
    value     = values['size'].gsub(/G/,""),
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "language"
  config = qs.new (
    type      = "string",
    question  = "Language",
    ask       = "yes",
    parameter = "",
    value     = values['locale'].gsub(/_/,"-"),
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "locale"
  config = qs.new (
    type      = "string",
    question  = "Locale",
    ask       = "yes",
    parameter = "",
    value     = values['locale'].gsub(/_/,"-"),
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "organisation"
  config = qs.new (
    type      = "string",
    question  = "Organisation",
    ask       = "yes",
    parameter = "",
    value     = values['organisation'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "timezone"
  config = qs.new (
    type      = "string",
    question  = "Time Zone",
    ask       = "yes",
    parameter = "",
    value     = values['timezone'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_username"
  config = qs.new (
    type      = "string",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_fullname"
  config = qs.new (
    type      = "string",
    question  = "Admin Fullname",
    ask       = "yes",
    parameter = "",
    value     = values['adminname'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_password"
  config = qs.new (
    type      = "string",
    question  = "Admin Password",
    ask       = "yes",
    parameter = "",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "license_key"
  config = qs.new (
    type      = "string",
    question  = "License Key",
    ask       = "yes",
    parameter = "",
    value     = values['license'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "search_domain"
  config = qs.new (
    type      = "string",
    question  = "Search Domain",
    ask       = "yes",
    parameter = "",
    value     = values['domainname'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "install_shell"
  config = qs.new (
    type      = "string",
    question  = "Install Shell",
    ask       = "yes",
    parameter = "",
    value     = values['winshell'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "network_type"
  config = qs.new (
    type      = "string",
    question  = "Network Type",
    ask       = "yes",
    parameter = "",
    value     = values['vmnetwork'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['vmnetwork'] = values['answers']['network_type'].value

  if values['vmnetwork'].to_s.match(/hostonly|bridged/)

    name   = "network_name"
    config = qs.new (
      type      = "string",
      question  = "Network Name",
      ask       = "yes",
      parameter = "",
      value     = network_name,
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "ip_address"
    config = qs.new (
      type      = "string",
      question  = "IP Address",
      ask       = "yes",
      parameter = "",
      value     = values['ip'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "gateway_address"
    config = qs.new (
      type      = "string",
      question  = "Gateway Address",
      ask       = "yes",
      parameter = "",
      value     = values['vmgateway'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "network_cidr"
    config = qs.new (
      type      = "string",
      question  = "Network CIDR",
      ask       = "yes",
      parameter = "",
      value     = values['cidr'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "nameserver_ip"
    config = qs.new (
      type      = "string",
      question  = "Nameserver IP Address",
      ask       = "yes",
      parameter = "",
      value     = values['nameserver'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end
  return
end
