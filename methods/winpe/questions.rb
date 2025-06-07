# frozen_string_literal: true

# Preseed configuration questions for Windows

def populate_pe_questions(values)
  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  values['ip'] = single_install_ip(values)
  network_name = if values['label'].to_s.match(/20[1,2][0-9]/)
                   if values['vm'].to_s.match(/fusion/)
                     'Ethernet0'
                   else
                     'Ethernet'
                   end
                 else
                   'Local Area Connection'
                 end

  # values['answers'] = {}
  # values['order']  = []

  name   = 'headless_mode'
  config = qs.new(
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

  name   = "values['label']"
  config = qs.new(
    'string',
    'Installation Label',
    'yes',
    '',
    values['label'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'cpu_arch'
  config = qs.new(
    'string',
    'CPU Architecture',
    'yes',
    '',
    values['arch'].gsub(/x86_64/, 'amd64'),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'boot_disk_size'
  config = qs.new(
    'string',
    'Boot disk size',
    'yes',
    '',
    values['size'].gsub(/G/, ''),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'language'
  config = qs.new(
    'string',
    'Language',
    'yes',
    '',
    values['locale'].gsub(/_/, '-'),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'locale'
  config = qs.new(
    'string',
    'Locale',
    'yes',
    '',
    values['locale'].gsub(/_/, '-'),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'organisation'
  config = qs.new(
    'string',
    'Organisation',
    'yes',
    '',
    values['organisation'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'timezone'
  config = qs.new(
    'string',
    'Time Zone',
    'yes',
    '',
    values['timezone'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_username'
  config = qs.new(
    'string',
    'Admin Username',
    'yes',
    '',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_fullname'
  config = qs.new(
    'string',
    'Admin Fullname',
    'yes',
    '',
    values['adminname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_password'
  config = qs.new(
    'string',
    'Admin Password',
    'yes',
    '',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'license_key'
  config = qs.new(
    'string',
    'License Key',
    'yes',
    '',
    values['license'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'search_domain'
  config = qs.new(
    'string',
    'Search Domain',
    'yes',
    '',
    values['domainname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'install_shell'
  config = qs.new(
    'string',
    'Install Shell',
    'yes',
    '',
    values['winshell'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'network_type'
  config = qs.new(
    'string',
    'Network Type',
    'yes',
    '',
    values['vmnetwork'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['vmnetwork'] = values['answers']['network_type'].value

  if values['vmnetwork'].to_s.match(/hostonly|bridged/)

    name   = 'network_name'
    config = qs.new(
      'string',
      'Network Name',
      'yes',
      '',
      network_name,
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'ip_address'
    config = qs.new(
      'string',
      'IP Address',
      'yes',
      '',
      values['ip'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'gateway_address'
    config = qs.new(
      'string',
      'Gateway Address',
      'yes',
      '',
      values['vmgateway'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'network_cidr'
    config = qs.new(
      'string',
      'Network CIDR',
      'yes',
      '',
      values['cidr'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'nameserver_ip'
    config = qs.new(
      'string',
      'Nameserver IP Address',
      'yes',
      '',
      values['nameserver'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end
  nil
end
