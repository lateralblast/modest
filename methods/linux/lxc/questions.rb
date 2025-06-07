# frozen_string_literal: true

# LXC quextions

def populate_lxc_client_questions(values)
  lx = Struct.new(:question, :ask, :value, :valid, :eval)

  name   = 'root_password'
  config = lx.new(
    'Root password',
    'yes',
    values['rootpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_crypt'
  config = lx.new(
    'Root Password Crypt',
    'yes',
    'get_root_password_crypt(values)',
    '',
    'get_root_password_crypt(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_fullname'
  config = lx.new(
    'User full name',
    'yes',
    values['adminname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_username'
  config = lx.new(
    'Username',
    'yes',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_uid'
  config = lx.new(
    'User UID',
    'yes',
    values['adminuid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_group'
  config = lx.new(
    'User Group',
    'yes',
    values['admingroup'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_gid'
  config = lx.new(
    'User GID',
    'yes',
    values['admingid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_home'
  config = lx.new(
    'User Home Directory',
    'yes',
    values['adminhome'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_shell'
  config = lx.new(
    'User Shell',
    'yes',
    values['adminshell'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_password'
  config = lx.new(
    'User password',
    'yes',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_crypt'
  config = lx.new(
    'User Password Crypt',
    'yes',
    'get_admin_password_crypt(values)',
    '',
    'get_admin_password_crypt(values)'
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

  name   = 'nameserver'
  config = lx.new(
    'Nameservers',
    'yes',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip'
  config = lx.new(
    'IP address',
    'yes',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'netmask'
  config = lx.new(
    'Netmask',
    'yes',
    values['netmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = "#{values['ip'].split(/\./)[0..2].join('.')}.#{values['gatewaynode']}"

  name   = 'gateway'
  config = lx.new(
    'Gateway',
    'yes',
    gateway,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = "#{values['ip'].split(/\./)[0..2].join('.')}.255"

  name   = 'broadcast'
  config = lx.new(
    'Broadcast',
    'yes',
    broadcast,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = "#{values['ip'].split(/\./)[0..2].join('.')}.0"

  name   = 'network_address'
  config = lx.new(
    'Network Address',
    'yes',
    network_address,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end

# LXC server populate_lxc_client_questions

def populate_lxc_server_questions(values)
  lx = Struct.new(:question, :ask, :value, :valid, :eval)

  name   = 'nameserver'
  config = lx.new(
    'Nameservers',
    'yes',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip'
  config = lx.new(
    'IP address',
    'yes',
    values['hostip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'netmask'
  config = lx.new(
    'Netmask',
    'yes',
    values['netmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = "#{values['hostip'].split(/\./)[0..2].join('.')}.#{values['gatewaynode']}"

  name   = 'gateway'
  config = lx.new(
    'Gateway',
    'yes',
    gateway,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = "#{values['hostip'].split(/\./)[0..2].join('.')}.255"

  name   = 'broadcast'
  config = lx.new(
    'Broadcast',
    'yes',
    broadcast,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = "#{values['hostip'].split(/\./)[0..2].join('.')}.0"

  name   = 'network_address'
  config = lx.new(
    'Network Address',
    'yes',
    network_address,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end
