
# Questions for cloud-init

# Populate ci questions

def populate_ci_questions(values)

  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  name   = "hostname"
  config = qs.new (
    type      = "",
    question  = "Hostname",
    ask       = "yes",
    parameter = "",
    value     = values['hostname'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "groups"
  config = qs.new (
    type      = "",
    question  = "Admin Group",
    ask       = "yes",
    parameter = "",
    value     = values['admingroup'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "adminuser"
  config = qs.new (
    type      = "",
    question  = "Admin User",
    ask       = "yes",
    parameter = "",
    value     = values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "shell"
  config = qs.new (
    type      = "",
    question  = "Admin Shell",
    ask       = "yes",
    parameter = "",
    value     = values['adminshell'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "password"
  config = qs.new (
    type      = "",
    question  = "Admin Password",
    ask       = "yes",
    parameter = "",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['admincrypt'] == values['empty']
    values['admincrypt'] = get_password_crypt(values['adminpassword'])
  end

  name   = "passwd"
  config = qs.new (
    type      = "",
    question  = "Admin Password Crypt",
    ask       = "yes",
    parameter = "",
    value     = values['admincrypt'],
    valid     = "",
    eval      = "get_password_crypt(values['adminpassword'])"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ssh-authorized-keys"
  config = qs.new (
    type      = "",
    question  = "Admin SSH key",
    ask       = "yes",
    parameter = "",
    value     = values['sshkey'],
    valid     = "",
    eval      = "no"
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

  name   = "lock_passwd"
  config = qs.new (
    type      = "",
    question  = "Lock Password",
    ask       = "yes",
    parameter = "",
    value     = values['lockpassword'].to_s,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['growpart'] == true

    name   = "growpartdevice"
    config = qs.new (
      type      = "",
      question  = "Grow partition on device",
      ask       = "yes",
      parameter = "",
      value     = values['growpartdevice'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "growpartmode"
    config = qs.new (
      type      = "",
      question  = "Grow partition mode",
      ask       = "yes",
      parameter = "",
      value     = values['growpartmode'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "powerstate"
  config = qs.new (
    type      = "",
    question  = "Power state",
    ask       = "yes",
    parameter = "",
    value     = values['powerstate'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "vmnic"
  config = qs.new (
    type      = "",
    question  = "Ethernet",
    ask       = "yes",
    parameter = "",
    value     = values['vmnic'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['dhcp'] == false

    name   = "ip"
    config = qs.new (
      type      = "",
      question  = "IP Address",
      ask       = "yes",
      parameter = "",
      value     = values['ip'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "cidr"
    config = qs.new (
      type      = "",
      question  = "CIDR",
      ask       = "yes",
      parameter = "",
      value     = values['cidr'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "nameserver"
    config = qs.new (
      type      = "",
      question  = "Nameserver",
      ask       = "yes",
      parameter = "",
      value     = values['nameserver'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)


    name   = "vmgateway"
    config = qs.new (
      type      = "",
      question  = "Gatewayr",
      ask       = "yes",
      parameter = "",
      value     = values['vmgateway'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "graphics"
  config = qs.new (
    type      = "",
    question  = "Graphics mode",
    ask       = "yes",
    parameter = "",
    value     = values['headless'].to_s,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "memory"
  config = qs.new (
    type      = "",
    question  = "Memory",
    ask       = "yes",
    parameter = "",
    value     = values['memory'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "vcpu"
  config = qs.new (
    type      = "output",
    question  = "Number of vCPUs",
    ask       = "yes",
    parameter = "",
    value     = values['vcpu'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "cpu"
  config = qs.new (
    type      = "",
    question  = "CPU family",
    ask       = "yes",
    parameter = "",
    value     = values['cputype'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "diskformat"
  config = qs.new (
    type      = "",
    question  = "Disk format",
    ask       = "yes",
    parameter = "",
    value     = values['diskformat'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end
