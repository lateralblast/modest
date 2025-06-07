# frozen_string_literal: true

# Code for VC

# Configuration questions for VCSA

def populate_vcsa_questions(values)
  # values['answers'] = {}
  # values['order']  = []

  values['ip'] = single_install_ip(values)

  name   = 'headless_mode'
  config = Js.new(
    '',
    'Headless mode',
    'yes',
    '',
    values['headless'].to_s.downcase,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'esx.hostname'
  config = Ks.new(
    'string',
    'ESX Server Hostname',
    'yes',
    'esx.hostname',
    values['server'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'esx.datastore'
  config = Ks.new(
    'string',
    'Datastore',
    'yes',
    'esx.datastore',
    values['datastore'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'esx.username'
  config = Ks.new(
    'string',
    'ESX Username',
    'yes',
    'esx.username',
    values['serveradmin'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'esx.password'
  config = Ks.new(
    'string',
    'ESX Password',
    'no',
    'esx.password',
    values['serverpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'deployment.option'
  config = Ks.new(
    'string',
    'Deployment Option',
    'no',
    'deployment.option',
    values['size'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'deployment.network'
  config = Ks.new(
    'string',
    'Deployment Network',
    'yes',
    'deployment.network',
    values['servernetmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'appliance.name'
  config = Ks.new(
    'string',
    'Appliance Name',
    'yes',
    'appliance.name',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'appliance.thin.disk.mode'
  config = Ks.new(
    'boolean',
    'Appliance Disk Mode',
    'yes',
    'appliance.thin.disk.mode',
    'true',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root.password'
  config = Ks.new(
    'string',
    'Root Password',
    'yes',
    'root.password',
    values['rootpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ssh.enable'
  config = Ks.new(
    'boolean',
    'SSH Enable',
    'yes',
    'ssh.enable',
    values['sshenadble'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ntp.servers'
  config = Ks.new(
    'string',
    'NTP Servers',
    'yes',
    'ntp.servers',
    values['timeserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'password'
  config = Ks.new(
    'string',
    'SSO password',
    'yes',
    'password',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'domain-name'
  config = Ks.new(
    'string',
    'NTP Servers',
    'yes',
    'ntp.servers',
    values['domainname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'site-name'
  config = Ks.new(
    'string',
    'Site Name',
    'yes',
    'ntp.servers',
    values['domainname'].split(/\./)[0],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip.family'
  config = Ks.new(
    'string',
    'IP Family',
    'yes',
    'ip.family',
    values['ipfamily'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'mode'
  config = Ks.new(
    'string',
    'IP Configuration',
    'yes',
    'mode',
    'static',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ip'
  config = Ks.new(
    'string',
    'IP Address',
    'yes',
    'ip',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'prefix'
  config = Ks.new(
    'string',
    'Subnet Mask',
    'yes',
    'prefix',
    values['netmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  gateway = "#{values['ip'].split(/\./)[0..2].join('.')}.#{values['gatewaynode']}"

  name   = 'gateway'
  config = Ks.new(
    'string',
    'Gateway',
    'yes',
    'netcfg/get_gateway',
    gateway,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dns.servers'
  config = Ks.new(
    'string',
    'Nameserver(s)',
    'yes',
    'dns.servers',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system.name'
  config = Ks.new(
    'string',
    'Hostname',
    'yes',
    'system.name',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  nil
end
