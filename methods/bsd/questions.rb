# frozen_string_literal: true

# Questions for *BSD and other (e.g. CoreOS)

# Populate CoreOS questions

def populate_coreos_questions(values)
  # values['answers'] = {}
  # values['order']  = []

  values['ip'] = single_install_ip(values)

  name   = 'hostname'
  config = Ks.new(
    '',
    'Hostname',
    'yes',
    '',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'nic'
  config = Ks.new(
    '',
    'Primary Network Interface',
    'yes',
    '',
    values['vmnet'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip'
  config = Ks.new(
    '',
    'IP',
    'yes',
    '',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'netmask'
  config = Ks.new(
    '',
    'Netmask',
    'yes',
    '',
    values['netmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'nameserver'
  config = Ks.new(
    '',
    'Nameserver(s)',
    'yes',
    '',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = "#{values['ip'].split(/\./)[0..2].join('.')}.#{values['gatewaynode']}"

  name   = 'gateway'
  config = Ks.new(
    '',
    'Gateway',
    'yes',
    '',
    gateway,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  broadcast = "#{values['ip'].split(/\./)[0..2].join('.')}.255"

  name   = 'broadcast'
  config = Ks.new(
    '',
    'Broadcast',
    'yes',
    '',
    broadcast,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  network_address = "#{values['ip'].split(/\./)[0..2].join('.')}.0"

  name   = 'network_address'
  config = Ks.new(
    '',
    'Network Address',
    'yes',
    '',
    network_address,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_password'
  config = Ks.new(
    '',
    'Root Password',
    'yes',
    '',
    values['rootpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_crypt'
  config = Ks.new(
    '',
    'Root Password Crypt',
    'yes',
    '',
    'get_root_password_crypt(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rootpw'
  config = Ks.new(
    'output',
    'Root Password Configuration',
    'yes',
    'rootpw',
    'get_ks_root_password(values)',
    '',
    'get_ks_root_password(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_user'
  config = Ks.new(
    '',
    'Admin Username',
    'yes',
    '',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_uid'
  config = Ks.new(
    '',
    'Admin User ID',
    'yes',
    '',
    values['adminuid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_shell'
  config = Ks.new(
    '',
    'Admin User Shell',
    '',
    values['adminshell'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_home'
  config = Ks.new(
    '',
    'Admin User Home Directory',
    'yes',
    '',
    "/home/#{values['adminuser']}",
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_group'
  config = Ks.new(
    '',
    'Admin User Group',
    'yes',
    '',
    values['admingroup'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_gid'
  config = Ks.new(
    '',
    'Admin Group ID',
    'yes',
    '',
    values['admingid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_password'
  config = Ks.new(
    '',
    'Admin User Password',
    'yes',
    '',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'admin_crypt'
  config = Ks.new(
    '',
    'Admin User Password Crypt',
    'yes',
    '',
    'get_admin_password_crypt(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)
end
