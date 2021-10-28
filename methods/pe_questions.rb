# Preseed configuration questions for Windows

def populate_pe_questions(options)

  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  options['ip'] = single_install_ip(options)
  if options['label'].to_s.match(/20[1,2][0-9]/)
    if options['vm'].to_s.match(/fusion/)
      network_name = "Ethernet0"
    else
      network_name = "Ethernet"
    end
  else
    network_name = "Local Area Connection"
  end

  # options['q_struct'] = {}
  # options['q_order']  = []

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

  name = "options['label']"
  config = qs.new(
    type      = "string",
    question  = "Installation Label",
    ask       = "yes",
    parameter = "",
    value     = options['label'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "cpu_arch"
  config = qs.new(
    type      = "string",
    question  = "CPU Architecture",
    ask       = "yes",
    parameter = "",
    value     = options['arch'].gsub(/x86_64/,"amd64"),
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "boot_disk_size"
  config = qs.new(
    type      = "string",
    question  = "Boot disk size",
    ask       = "yes",
    parameter = "",
    value     = options['size'].gsub(/G/,""),
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "language"
  config = qs.new(
    type      = "string",
    question  = "Language",
    ask       = "yes",
    parameter = "",
    value     = options['locale'].gsub(/_/,"-"),
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
    parameter = "",
    value     = options['locale'].gsub(/_/,"-"),
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "organisation"
  config = qs.new(
    type      = "string",
    question  = "Organisation",
    ask       = "yes",
    parameter = "",
    value     = options['organisation'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "timezone"
  config = qs.new(
    type      = "string",
    question  = "Time Zone",
    ask       = "yes",
    parameter = "",
    value     = options['timezone'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_username"
  config = qs.new(
    type      = "string",
    question  = "Admin Username",
    ask       = "yes",
    parameter = "",
    value     = options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_fullname"
  config = qs.new(
    type      = "string",
    question  = "Admin Fullname",
    ask       = "yes",
    parameter = "",
    value     = options['adminname'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "admin_password"
  config = qs.new(
    type      = "string",
    question  = "Admin Password",
    ask       = "yes",
    parameter = "",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "license_key"
  config = qs.new(
    type      = "string",
    question  = "License Key",
    ask       = "yes",
    parameter = "",
    value     = options['license'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "search_domain"
  config = qs.new(
    type      = "string",
    question  = "Search Domain",
    ask       = "yes",
    parameter = "",
    value     = options['domainname'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "install_shell"
  config = qs.new(
    type      = "string",
    question  = "Install Shell",
    ask       = "yes",
    parameter = "",
    value     = options['winshell'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  name = "network_type"
  config = qs.new(
    type      = "string",
    question  = "Network Type",
    ask       = "yes",
    parameter = "",
    value     = options['vmnetwork'],
    valid     = "",
    eval      = "no"
    )
  options['q_struct'][name] = config
  options['q_order'].push(name)

  options['vmnetwork'] = options['q_struct']['network_type'].value

  if options['vmnetwork'].to_s.match(/hostonly|bridged/)

    name = "network_name"
    config = qs.new(
      type      = "string",
      question  = "Network Name",
      ask       = "yes",
      parameter = "",
      value     = network_name,
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "ip_address"
    config = qs.new(
      type      = "string",
      question  = "IP Address",
      ask       = "yes",
      parameter = "",
      value     = options['ip'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "gateway_address"
    config = qs.new(
      type      = "string",
      question  = "Gateway Address",
      ask       = "yes",
      parameter = "",
      value     = options['vmgateway'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "network_cidr"
    config = qs.new(
      type      = "string",
      question  = "Network CIDR",
      ask       = "yes",
      parameter = "",
      value     = options['cidr'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

    name = "nameserver_ip"
    config = qs.new(
      type      = "string",
      question  = "Nameserver IP Address",
      ask       = "yes",
      parameter = "",
      value     = options['nameserver'],
      valid     = "",
      eval      = "no"
      )
    options['q_struct'][name] = config
    options['q_order'].push(name)

  end
  return
end
