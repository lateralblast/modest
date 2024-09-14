
# Questions for cloud-init

# Populate ci questions

def populate_ci_questions(values)

  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  name   = "hostname"
  config = qs.new(
    type      = "",
    question  = "Hostname",
    ask       = "yes",
    parameter = "",
    value     = values['hostname'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "groups"
  config = qs.new(
    type      = "",
    question  = "Admin Group",
    ask       = "yes",
    parameter = "",
    value     = values['admingroup'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "adminuser"
  config = qs.new(
    type      = "",
    question  = "Admin User",
    ask       = "yes",
    parameter = "",
    value     = values['adminuser'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "shell"
  config = qs.new(
    type      = "",
    question  = "Admin Shell",
    ask       = "yes",
    parameter = "",
    value     = values['adminshell'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "password"
  config = qs.new(
    type      = "",
    question  = "Admin Password",
    ask       = "yes",
    parameter = "",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  if values['q_struct']['adminpassword'].value == values['adminpassword']
    admin_crypt = values['admincrypt']
  else
    admin_crypt = get_password_crypt(values['q_struct']['adminpassword'].value)
  end

  name   = "passwd"
  config = qs.new(
    type      = "",
    question  = "Admin Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = admin_crypt,
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "ssh-authorized-keys"
  config = qs.new(
    type      = "",
    question  = "Admin SSH key",
    ask       = "yes",
    parameter = "",
    value     = values['sshkey'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "sudo"
  config = qs.new(
    type      = "",
    question  = "Admin sudoers",
    ask       = "yes",
    parameter = "",
    value     = values['sudoers'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name = "graphics"
  config = qs.new(
    type      = "",
    question  = "Graphics mode",
    ask       = "yes",
    parameter = "",
    value     = values['headless'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)


  name = "vmnic"
  config = qs.new(
    type      = "",
    question  = "Ethernet",
    ask       = "yes",
    parameter = "",
    value     = values['vmnic'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  if values['dhcp'] == false

    name = "ip"
    config = qs.new(
      type      = "",
      question  = "IP Address",
      ask       = "yes",
      parameter = "",
      value     = values['ip'],
      valid     = "",
      eval      = "no"
      )
    values['q_struct'][name] = config
    values['q_order'].push(name)

    name = "cidr"
    config = qs.new(
      type      = "",
      question  = "CIDR",
      ask       = "yes",
      parameter = "",
      value     = values['cidr'],
      valid     = "",
      eval      = "no"
      )
    values['q_struct'][name] = config
    values['q_order'].push(name)

    name = "nameserver"
    config = qs.new(
      type      = "",
      question  = "Nameserver",
      ask       = "yes",
      parameter = "",
      value     = values['nameserver'],
      valid     = "",
      eval      = "no"
      )
    values['q_struct'][name] = config
    values['q_order'].push(name)


    name = "vmgateway"
    config = qs.new(
      type      = "",
      question  = "Gatewayr",
      ask       = "yes",
      parameter = "",
      value     = values['vmgateway'],
      valid     = "",
      eval      = "no"
      )
    values['q_struct'][name] = config
    values['q_order'].push(name)

  end

  name = "graphics"
  config = qs.new(
    type      = "",
    question  = "Graphics mode",
    ask       = "yes",
    parameter = "",
    value     = values['headless'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "memory"
  config = qs.new(
    type      = "",
    question  = "Memory",
    ask       = "yes",
    parameter = "",
    value     = values['memory'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  name   = "vcpu"
  config = qs.new(
    type      = "output",
    question  = "Number of vCPUs",
    ask       = "yes",
    parameter = "",
    value     = values['vcpu'],
    valid     = "",
    eval      = "no"
    )
  values['q_struct'][name] = config
  values['q_order'].push(name)

  return values
end
