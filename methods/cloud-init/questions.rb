# frozen_string_literal: true

# Questions for cloud-init

# Populate ci questions

def populate_ci_questions(values)
  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  name   = 'hostname'
  config = qs.new(
    '',
    'Hostname',
    'yes',
    '',
    values['hostname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'groups'
  config = qs.new(
    '',
    'Admin Group',
    'yes',
    '',
    values['admingroup'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'adminuser'
  config = qs.new(
    '',
    'Admin User',
    'yes',
    '',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'shell'
  config = qs.new(
    '',
    'Admin Shell',
    'yes',
    '',
    values['adminshell'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'password'
  config = qs.new(
    '',
    'Admin Password',
    'yes',
    '',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['admincrypt'] = get_password_crypt(values['adminpassword']) if values['admincrypt'] == values['empty']

  name   = 'passwd'
  config = qs.new(
    '',
    'Admin Password Crypt',
    'yes',
    '',
    values['admincrypt'],
    '',
    "get_password_crypt(values['adminpassword'])"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ssh-authorized-keys'
  config = qs.new(
    '',
    'Admin SSH key',
    'yes',
    '',
    values['sshkey'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'sudoers'
  config = qs.new(
    '',
    'Admin sudoers',
    'yes',
    '',
    values['sudoers'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'lock_passwd'
  config = qs.new(
    '',
    'Lock Password',
    'yes',
    '',
    values['lockpassword'].to_s,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['growpart'] == true

    name   = 'growpartdevice'
    config = qs.new(
      '',
      'Grow partition on device',
      'yes',
      '',
      values['growpartdevice'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'growpartmode'
    config = qs.new(
      '',
      'Grow partition mode',
      'yes',
      '',
      values['growpartmode'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'powerstate'
  config = qs.new(
    '',
    'Power state',
    'yes',
    '',
    values['powerstate'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vmnic'
  config = qs.new(
    '',
    'Ethernet',
    'yes',
    '',
    values['vmnic'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dhcp'
  config = qs.new(
    '',
    'DHCP',
    'yes',
    '',
    values['dhcp'].to_s,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip'
  config = qs.new(
    '',
    'IP Address',
    'yes',
    '',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'cidr'
  config = qs.new(
    '',
    'CIDR',
    'yes',
    '',
    values['cidr'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'nameserver'
  config = qs.new(
    '',
    'Nameserver',
    'yes',
    '',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vmgateway'
  config = qs.new(
    '',
    'Gatewayr',
    'yes',
    '',
    values['vmgateway'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'graphics'
  config = qs.new(
    '',
    'Graphics mode',
    'yes',
    '',
    values['headless'].to_s,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'memory'
  config = qs.new(
    '',
    'Memory',
    'yes',
    '',
    values['memory'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vcpu'
  config = qs.new(
    'output',
    'Number of vCPUs',
    'yes',
    '',
    values['vcpu'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'cpu'
  config = qs.new(
    '',
    'CPU family',
    'yes',
    '',
    values['cputype'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'diskformat'
  config = qs.new(
    '',
    'Disk format',
    'yes',
    '',
    values['diskformat'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end
