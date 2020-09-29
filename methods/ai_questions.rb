
# Populate array of structs containing AI manifest questions

def populate_ai_manifest_questions(options)
  $q_struct={}
  $q_order=[]

  name = "auto_reboot"
  config = Ai.new(
    question  = "Reboot after installation",
    ask       = "yes",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "headless_mode"
  config = Ai.new(
    question  = "Headless mode",
    ask       = "yes",
    value     = options['headless'].to_s.downcase,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name    = "ai_publisherurl"
  options = get_ai_publisherurl(options)
  config = Ai.new(
    question  = "Publisher URL",
    ask       = "yes",
    value     = options['publisherurl'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "server_install"
  config = Ai.new(
    question  = "Server install",
    ask       = "yes",
    value     = "pkg:/group/system/solaris-"+options['size']+"-server",
    valid     = "pkg:/group/system/solaris-large-server,pkg:/group/system/solaris-small-server",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "repo_url"
  repo_url = get_ai_repo_url(options)
  config = Ai.new(
    question  = "Solaris repository version",
    ask       = "yes",
    value     = repo_url,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return options
end

# Populate array of structs with profile questions

def populate_ai_client_profile_questions(options)
  $q_struct={}
  $q_order=[]

  name = "headless_mode"
  config = Js.new(
    type      = "",
    question  = "Headless mode",
    ask       = "yes",
    parameter = "",
    value     = options['headless'].to_s.downcase,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_password"
  config = Ai.new(
    question  = "Root Password",
    ask       = "yes",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_crypt"
  config = Ai.new(
    question  = "Root Password Crypt",
    ask       = "yes",
    value     = "get_root_password_crypt(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_type"
  config = Ai.new(
    question  = "Root Account Type",
    ask       = "yes",
    value     = "role",
    valid     = "role,normal",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_expire"
  config = Ai.new(
    question  = "Password Expiry Date (0 = next login)",
    ask       = "yes",
    value     = "0",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_username"
  config = Ai.new(
    question  = "Account login name",
    ask       = "yes",
    value     = options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_password"
  config = Ai.new(
    question  = "Admin Account Password",
    ask       = "yes",
    value     = options['adminpassword'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_crypt"
  config = Ai.new(
    question  = "Admin Account Password Crypt",
    ask       = "yes",
    value     = "get_admin_password_crypt(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_description"
  config = Ai.new(
    question  = "Account Description",
    ask       = "yes",
    value     = "System Administrator",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_home"
  config = Ai.new(
    question  = "Account Home",
    ask       = "yes",
    value     = "/export/home/"+options['adminuser'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_shell"
  vaild_shells=get_valid_shells()
  config = Ai.new(
    question  = "Account Shell",
    ask       = "yes",
    value     = "/usr/bin/bash",
    valid     = vaild_shells,
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_uid"
  config = Ai.new(
    question  = "Account UID",
    ask       = "yes",
    value     = "101",
    valid     = "",
    eval      = "check_valid_uid(options,answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_gid"
  config = Ai.new(
    question  = "Account GID",
    ask       = "yes",
    value     = "10",
    valid     = "",
    eval      = "check_valid_gid(options,answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_type"
  config = Ai.new(
    question  = "Account type",
    ask       = "yes",
    value     = "normal",
    valid     = "normal,role",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_roles"
  config = Ai.new(
    question  = "Account roles",
    ask       = "yes",
    value     = "root",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_profiles"
  config = Ai.new(
    question  = "Account Profiles",
    ask       = "yes",
    value     = "System Administrator",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_sudoers"
  config = Ai.new(
    question  = "Account Sudoers Entry",
    ask       = "yes",
    value     = "ALL=(ALL) ALL",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "admin_expire"
  config = Ai.new(
    question  = "Password Expiry Date (0 = next login)",
    ask       = "yes",
    value     = "0",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system_identity"
  config = Ai.new(
    question  = "Hostname",
    ask       = "yes",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system_console"
  config = Ai.new(
    question  = "Terminal Type",
    ask       = "yes",
    value     = options['terminal'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system_keymap"
  config = Ai.new(
    question  = "System Keymap",
    ask       = "yes",
    value     = options['keymap'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system_timezone"
  config = Ai.new(
    question  = "System Timezone",
    ask       = "yes",
    value     = options['timezone'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system_environment"
  config = Ai.new(
    question  = "System Environment",
    ask       = "yes",
    value     = options['environment'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ipv4_interface_name"
  config = Ai.new(
    question  = "IPv4 interface name",
    ask       = "yes",
    value     = "#{options['nic']}/v4",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  ipv4_address = options['ip']+"/"+options['cidr']

  name = "ipv4_static_address"
  config = Ai.new(
    question  = "IPv4 Static Address",
    ask       = "yes",
    value     = ipv4_address,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ipv4_default_route"
  ipv4_default_route = get_ipv4_default_route(options)
  config = Ai.new(
    question  = "IPv4 Default Route",
    ask       = "yes",
    value     = ipv4_default_route,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "ipv6_interface_name"
  config = Ai.new(
    question  = "IPv6 Interface Name",
    ask       = "yes",
    value     = "#{options['nic']}/v6",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "dns_nameserver"
  config = Ai.new(
    question  = "Nameserver",
    ask       = "yes",
    value     = options['nameserver'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "dns_search"
  config = Ai.new(
    question  = "DNS Search Domain",
    ask       = "yes",
    value     = options['local'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "dns_files"
  config = Ai.new(
    question  = "DNS Default Lookup",
    ask       = "yes",
    value     = options['files'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "dns_hosts"
    config = Ai.new(
    question  = "DNS Hosts Lookup",
    ask       = "yes",
    value     = options['hosts'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "bename"
    config = Ai.new(
    question  = "Boot Environment name",
    ask       = "yes",
    value     = options['bename'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rpool"
    config = Ai.new(
    question  = "Root disk ZFS pool name",
    ask       = "yes",
    value     = options['rpoolname'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "rootdisk"
    config = Ai.new(
    question  = "Root disk",
    ask       = "yes",
    value     = options['rootdisk'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  mirror_disk_id = get_js_mirror_disk_id(options)

  name = "mirrordisk"
    config = Ai.new(
    question  = "Mirror disk",
    ask       = "yes",
    value     = mirror_disk_id,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  return options
end
