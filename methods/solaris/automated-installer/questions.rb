
# Populate array of structs containing AI manifest questions

def populate_ai_manifest_questions(values)

  qs = Struct.new(:question, :ask, :value, :valid, :eval)

  name   = "auto_reboot"
  config = qs.new(
    question  = "Reboot after installation",
    ask       = "yes",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "headless_mode"
  config = qs.new(
    question  = "Headless mode",
    ask       = "yes",
    value     = values['headless'].to_s.downcase,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ai_publisherurl"
  values = get_ai_publisherurl(values)
  config = qs.new(
    question  = "Publisher URL",
    ask       = "yes",
    value     = values['publisherurl'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "server_install"
  config = qs.new(
    question  = "Server install",
    ask       = "yes",
    value     = "pkg:/group/system/solaris-"+values['size']+"-server",
    valid     = "pkg:/group/system/solaris-large-server,pkg:/group/system/solaris-small-server",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name     = "repo_url"
  repo_url = get_ai_repo_url(values)
  config   = qs.new(
    question  = "Solaris repository version",
    ask       = "yes",
    value     = repo_url,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end

# Populate array of structs with profile questions

def populate_ai_client_profile_questions(values)
  values['answers']={}
  values['order']=[]

  name   = "headless_mode"
  config = Js.new(
    type      = "",
    question  = "Headless mode",
    ask       = "yes",
    parameter = "",
    value     = values['headless'].to_s.downcase,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_password"
  config = qs.new(
    question  = "Root Password",
    ask       = "yes",
    value     = values['rootpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_crypt"
  config = qs.new(
    question  = "Root Password Crypt",
    ask       = "yes",
    value     = "get_root_password_crypt(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_type"
  config = qs.new(
    question  = "Root Account Type",
    ask       = "yes",
    value     = "role",
    valid     = "role,normal",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_expire"
  config = qs.new(
    question  = "Password Expiry Date (0 = next login)",
    ask       = "yes",
    value     = "0",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_username"
  config = qs.new(
    question  = "Account login name",
    ask       = "yes",
    value     = values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_password"
  config = qs.new(
    question  = "Admin Account Password",
    ask       = "yes",
    value     = values['adminpassword'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_crypt"
  config = qs.new(
    question  = "Admin Account Password Crypt",
    ask       = "yes",
    value     = "get_admin_password_crypt(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_description"
  config = qs.new(
    question  = "Account Description",
    ask       = "yes",
    value     = "System Administrator",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_home"
  config = qs.new(
    question  = "Account Home",
    ask       = "yes",
    value     = "/export/home/"+values['adminuser'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_shell"
  vaild_shells = get_valid_shells(values)
  config = qs.new(
    question  = "Account Shell",
    ask       = "yes",
    value     = "/usr/bin/bash",
    valid     = vaild_shells,
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_uid"
  config = qs.new(
    question  = "Account UID",
    ask       = "yes",
    value     = "101",
    valid     = "",
    eval      = "check_valid_uid(values, answer)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_gid"
  config = qs.new(
    question  = "Account GID",
    ask       = "yes",
    value     = "10",
    valid     = "",
    eval      = "check_valid_gid(values, answer)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_type"
  config = qs.new(
    question  = "Account type",
    ask       = "yes",
    value     = "normal",
    valid     = "normal,role",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_roles"
  config = qs.new(
    question  = "Account roles",
    ask       = "yes",
    value     = "root",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_profiles"
  config = qs.new(
    question  = "Account Profiles",
    ask       = "yes",
    value     = "System Administrator",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_sudoers"
  config = qs.new(
    question  = "Account Sudoers Entry",
    ask       = "yes",
    value     = "ALL=(ALL) ALL",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "admin_expire"
  config = qs.new(
    question  = "Password Expiry Date (0 = next login)",
    ask       = "yes",
    value     = "0",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system_identity"
  config = qs.new(
    question  = "Hostname",
    ask       = "yes",
    value     = values['name'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system_console"
  config = qs.new(
    question  = "Terminal Type",
    ask       = "yes",
    value     = values['terminal'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system_keymap"
  config = qs.new(
    question  = "System Keymap",
    ask       = "yes",
    value     = values['keymap'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system_timezone"
  config = qs.new(
    question  = "System Timezone",
    ask       = "yes",
    value     = values['timezone'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system_environment"
  config = qs.new(
    question  = "System Environment",
    ask       = "yes",
    value     = values['environment'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ipv4_interface_name"
  config = qs.new(
    question  = "IPv4 interface name",
    ask       = "yes",
    value     = "#{values['nic']}/v4",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  ipv4_address = values['ip']+"/"+values['cidr']

  name   = "ipv4_static_address"
  config = qs.new( 
    question  = "IPv4 Static Address",
    ask       = "yes",
    value     = ipv4_address,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ipv4_default_route"
  ipv4_default_route = get_ipv4_default_route(values)
  config = qs.new(
    question  = "IPv4 Default Route",
    ask       = "yes",
    value     = ipv4_default_route,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "ipv6_interface_name"
  config = qs.new(
    question  = "IPv6 Interface Name",
    ask       = "yes",
    value     = "#{values['nic']}/v6",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "dns_nameserver"
  config = qs.new(
    question  = "Nameserver",
    ask       = "yes",
    value     = values['nameserver'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "dns_search"
  config = qs.new(
    question  = "DNS Search Domain",
    ask       = "yes",
    value     = values['local'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "dns_files"
  config = qs.new(
    question  = "DNS Default Lookup",
    ask       = "yes",
    value     = values['files'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "dns_hosts"
  config = qs.new(
    question  = "DNS Hosts Lookup",
    ask       = "yes",
    value     = values['hosts'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "bename"
  config = qs.new(
    question  = "Boot Environment name",
    ask       = "yes",
    value     = values['bename'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rpool"
  config = qs.new(
    question  = "Root disk ZFS pool name",
    ask       = "yes",
    value     = values['rpoolname'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "rootdisk"
  config = qs.new(
    question  = "Root disk",
    ask       = "yes",
    value     = values['rootdisk'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  mirror_disk_id = get_js_mirror_disk_id(values)

  name   = "mirrordisk"
  config = qs.new(
    question  = "Mirror disk",
    ask       = "yes",
    value     = mirror_disk_id,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  return values
end
