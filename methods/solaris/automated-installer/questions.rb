# frozen_string_literal: true

# Populate array of structs containing AI manifest questions

def populate_ai_manifest_questions(values)
  qs = Struct.new(:question, :ask, :value, :valid, :eval)

  name   = 'auto_reboot'
  config = qs.new(
    'Reboot after installation',
    'yes',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'headless_mode'
  config = qs.new(
    'Headless mode',
    'yes',
    values['headless'].to_s.downcase,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ai_publisherurl'
  values = get_ai_publisherurl(values)
  config = qs.new(
    'Publisher URL',
    'yes',
    values['publisherurl'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'server_install'
  config = qs.new(
    'Server install',
    'yes',
    "pkg:/group/system/solaris-#{values['size']}-server",
    'pkg:/group/system/solaris-large-server,pkg:/group/system/solaris-small-server',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name     = 'repo_url'
  repo_url = get_ai_repo_url(values)
  config   = qs.new(
    'Solaris repository version',
    'yes',
    repo_url,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end

# Populate array of structs with profile questions

def populate_ai_client_profile_questions(values)
  values['answers'] = {}
  values['order'] = []

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

  name   = 'root_password'
  config = qs.new(
    'Root Password',
    'yes',
    values['rootpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_crypt'
  config = qs.new(
    'Root Password Crypt',
    'yes',
    'get_root_password_crypt(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_type'
  config = qs.new(
    'Root Account Type',
    'yes',
    'role',
    'role,normal',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_expire'
  config = qs.new(
    'Password Expiry Date (0 = next login)',
    'yes',
    '0',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_username'
  config = qs.new(
    'Account login name',
    'yes',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_password'
  config = qs.new(
    'Admin Account Password',
    'yes',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_crypt'
  config = qs.new(
    'Admin Account Password Crypt',
    'yes',
    'get_admin_password_crypt(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_description'
  config = qs.new(
    'Account Description',
    'yes',
    'System Administrator',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_home'
  config = qs.new(
    'Account Home',
    'yes',
    "/export/home/#{values['adminuser']}",
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'admin_shell'
  vaild_shells = get_valid_shells(values)
  config = qs.new(
    'Account Shell',
    'yes',
    '/usr/bin/bash',
    vaild_shells,
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_uid'
  config = qs.new(
    'Account UID',
    'yes',
    '101',
    '',
    'check_valid_uid(values, answer)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_gid'
  config = qs.new(
    'Account GID',
    'yes',
    '10',
    '',
    'check_valid_gid(values, answer)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_type'
  config = qs.new(
    'Account type',
    'yes',
    'normal',
    'normal,role',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_roles'
  config = qs.new(
    'Account roles',
    'yes',
    'root',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_profiles'
  config = qs.new(
    'Account Profiles',
    'yes',
    'System Administrator',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_sudoers'
  config = qs.new(
    'Account Sudoers Entry',
    'yes',
    'ALL=(ALL) ALL',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_expire'
  config = qs.new(
    'Password Expiry Date (0 = next login)',
    'yes',
    '0',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system_identity'
  config = qs.new(
    'Hostname',
    'yes',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system_console'
  config = qs.new(
    'Terminal Type',
    'yes',
    values['terminal'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system_keymap'
  config = qs.new(
    'System Keymap',
    'yes',
    values['keymap'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system_timezone'
  config = qs.new(
    'System Timezone',
    'yes',
    values['timezone'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system_environment'
  config = qs.new(
    'System Environment',
    'yes',
    values['environment'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ipv4_interface_name'
  config = qs.new(
    'IPv4 interface name',
    'yes',
    "#{values['nic']}/v4",
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  ipv4_address = "#{values['ip']}/#{values['cidr']}"

  name   = 'ipv4_static_address'
  config = qs.new(
    'IPv4 Static Address',
    'yes',
    ipv4_address,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'ipv4_default_route'
  ipv4_default_route = get_ipv4_default_route(values)
  config = qs.new(
    'IPv4 Default Route',
    'yes',
    ipv4_default_route,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'ipv6_interface_name'
  config = qs.new(
    'IPv6 Interface Name',
    'yes',
    "#{values['nic']}/v6",
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dns_nameserver'
  config = qs.new(
    'Nameserver',
    'yes',
    values['nameserver'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dns_search'
  config = qs.new(
    'DNS Search Domain',
    'yes',
    values['local'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dns_files'
  config = qs.new(
    'DNS Default Lookup',
    'yes',
    values['files'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dns_hosts'
  config = qs.new(
    'DNS Hosts Lookup',
    'yes',
    values['hosts'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'bename'
  config = qs.new(
    'Boot Environment name',
    'yes',
    values['bename'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rpool'
  config = qs.new(
    'Root disk ZFS pool name',
    'yes',
    values['rpoolname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'rootdisk'
  config = qs.new(
    'Root disk',
    'yes',
    values['rootdisk'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  mirror_disk_id = get_js_mirror_disk_id(values)

  name   = 'mirrordisk'
  config = qs.new(
    'Mirror disk',
    'yes',
    mirror_disk_id,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values
end
