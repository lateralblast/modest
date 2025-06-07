# frozen_string_literal: true

# Questions for ks

# Construct ks network line

def get_vs_network(values)
  if values['answers']['bootproto'].value.match(/dhcp/)
    result = "--netdevice #{values['answers']['nic'].value} --bootproto #{values['answers']['bootproto'].value}"
  else
    values['ip'] = values['answers']['ip'].value
    values['name'] = values['answers']['hostname'].value
    gateway = get_ipv4_default_route(values)
    result = "--device=#{values['answers']['nic'].value} --bootproto=#{values['answers']['bootproto'].value} --ip=#{values['ip']} --netmask=#{values['netmask']} --gateway=#{gateway} --nameserver=#{values['nameserver']} --hostname=#{values['name']} --addvmportgroup=0"
  end
  result
end

# Set network

def set_vs_network(values)
  if values['answers']['bootproto'].value.match(/dhcp/)
    values['answers']['ip'].ask = 'no'
    values['answers']['ip'].type = ''
    values['answers']['hostname'].ask = 'no'
    values['answers']['hostname'].type = ''
  end
  values
end

# Construct ks password line

def get_vs_password(values)
  "--iscrypted #{values['answers']['root_crypt'].value}"
end

# Get install url

def get_vs_install_url(values)
  "http://#{values['hostip']}/#{values['service']}"
end

# Get kickstart header

def get_vs_header(values)
  version = get_version(values)
  version = version.join(' ')
  "# kickstart file for #{values['name']} #{version}"
end

# Populate ks questions

def populate_vs_questions(values)
  vs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)

  name   = 'headless_mode'
  config = vs.new(
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

  name   = 'ks_header'
  config = vs.new(
    'output',
    'VSphere file header comment',
    'yes',
    '',
    get_vs_header(values),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vmaccepteula'
  config = vs.new(
    'output',
    'Accept EULA',
    'yes',
    '',
    'vmaccepteula',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'install'
  config = vs.new(
    'output',
    'Install type',
    'yes',
    'install',
    '--firstdisk --overwritevmfs',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'nic'
  config = vs.new(
    '',
    'Primary Network Interface',
    'yes',
    '',
    'vmnic0',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bootproto'
  config = vs.new(
    '',
    'Boot Protocol',
    'yes',
    '',
    'static',
    'static,dhcp',
    'values = set_vs_network(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'hostname'
  config = vs.new(
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

  name   = 'ip'
  config = vs.new(
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

  name   = 'network'
  config = vs.new(
    'output',
    'Network Configuration',
    'yes',
    'network',
    'get_vs_network(values)',
    '',
    'get_vs_network(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'datastore'
  config = vs.new(
    '',
    'Local datastore name',
    'yes',
    '',
    values['datastore'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vm_network_name'
  config = vs.new(
    '',
    'VM network name',
    'yes',
    '',
    values['servernetwork'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vm_network_vlanid'
  config = vs.new(
    '',
    'VM network VLAN ID',
    'yes',
    '',
    values['vlanid'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'vm_network_vswitch'
  config = vs.new(
    '',
    'VM network vSwitch',
    'yes',
    '',
    values['vswitch'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_password'
  config = vs.new(
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
  config = vs.new(
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
  config = vs.new(
    'output',
    'Root Password Configuration',
    'yes',
    'rootpw',
    'get_vs_password(values)',
    '',
    'get_vs_password(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'finish'
  config = vs.new(
    'output',
    'Finish Command',
    'yes',
    '',
    'reboot',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)
  values
end
