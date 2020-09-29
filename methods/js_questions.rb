

# Jumpstart questions

# Get system architecture for sparc (sun4u/sun4v)

def get_js_system_karch(options)
  system_model = $q_struct['system_model'].value
  if not system_model.match(/vm|i386/)
    if system_model.downcase.match(/^t/)
      system_karch = "sun4v"
    else
      system_karch = "sun4u"
    end
  else
    system_karch = "i86pc"
  end
  return system_karch
end

# Get disk id based on model

def get_js_nic_model(options)
  if options['nic'] != options['empty']
    nic_model = options['nic']
  else
    nic_model = "e1000g0"
    case $q_struct['system_model'].value.downcase
    when /445|t1000/
      nic_model = "bge0"
    when /280|440|480|490|4x0/
      nic_model = "eri0"
    when /880|890|8x0/
      nic_model = "ce0"
    when /250|450|220/
      nic_model = "hme0"
    when /^t4/
      nic_model = "igb0"
    end
  end
  return nic_model
end

# Get disk id based on model

def get_js_root_disk_id(options)
  if options['rootdisk'].to_s.match(/c[0-9]/)
    root_disk_id = options['rootdisk']
  else
    root_disk_id = "c0t0d0"
    case $q_struct['system_model'].value.downcase
    when /vm/
      root_disk_id = "any"
    when /445|440|480|490|4x0|880|890|8x0|t5220|t5120|t5xx0|t5140|t5240|t5440/
      root_disk_id = "c1t0d0"
    when /100|120|x1/
      root_disk_id = "c0t2d0"
    end
  end
  return root_disk_id
end

# Get mirror disk id

def get_js_mirror_disk_id(options)
  if options['mirrordisk'].to_s.match(/c[0-9]/)
    mirror_disk_id = options['mirrordisk']
  else
    root_disk_id = $q_struct['root_disk_id'].value
    if not root_disk_id.match(/any/)
      mirror_controller_id = root_disk_id.split(/t/)[0].gsub(/^c/,"")
      mirror_target_id     = root_disk_id.split(/t/)[1].split(/d/)[0]
      mirror_disk_id       = root_disk_id.split(/d/)[1]
      system_model         = $q_struct['system_model'].value.downcase
      if !mirror_target_id.match(/[A-Z]/)
        case system_model
        when /^v8/
          mirror_target_id = Integer(mirror_target_id)+3
        when /^e6/
          mirror_controller_id = Integer(mirror_controller_id)+1
        else
          mirror_target_id = Integer(mirror_target_id)+1
        end
        mirror_disk_id = "c"+mirror_controller_id.to_s+"t"+mirror_target_id.to_s+"d"+mirror_disk_id.to_s
      else
        mirror_disk_id = "any"
      end
    else
      mirror_disk_id = "any"
    end
  end
  return mirror_disk_id
end

# Get disk size based on model

def get_js_disk_size(options)
  case $q_struct['system_model'].value.downcase
  when /vm/
    disk_size = "auto"
  when /t5220|t5120|t5xx0|t5140|t5240|t5440|t6300|t6xx0|t6320|t6340/
    disk_size = "146g"
  when /280/
    disk_size = "36g"
  else
    disk_size = "auto"
  end
  return disk_size
end

# Get disk size based on model

def get_js_memory_size(options)
  case $q_struct['system_model'].value.downcase
  when /280|250|450|220/
    memory_size = "2g"
  when /100|120|x1|vm/
    memory_size = "1g"
  else
    memory_size = "auto"
  end
  return memory_size
end

# Set Jumpstart filesystem

def set_js_fs(options)
  fs_name = ""
  if $q_struct['root_fs'].value.downcase.match(/zfs/)
    ['memory_size","disk_size","swap_size","root_metadb","mirror_metadb","metadb_size","metadb_count'].each do |key|
      if $q_struct[key]
        $q_struct[key].ask  = "no"
        $q_struct[key].type = ""
      end
    end
  else
    $q_struct['zfs_layout'].ask  = "no"
    $q_struct['zfs_bootenv'].ask = "no"
    (f_struct,f_order) = populate_js_fs_list(options)
    f_struct = ""
    f_order.each do |fs_name|
      key                 = fs_name+"_filesys"
      $q_struct[key].ask  = "no"
      $q_struct[key].type = ""
      key                 = fs_name+"_size"
      $q_struct[key].ask  = "no"
      $q_struct[key].type = ""
    end
  end
  return options
end

# Get Jumpstart network information

def get_js_network(options)
  options['version'] = $q_struct['os_version'].value
  if Integer(options['version']) > 7
    network = $q_struct['nic_model'].value+" { hostname="+$q_struct['hostname'].value+" default_route="+$q_struct['default_route'].value+" ip_address="+$q_struct['ip_address'].value+" netmask="+$q_struct['netmask'].value+" protocol_ipv6="+$q_struct['protocol_ipv6'].value+" }"
  else
    network = $q_struct['nic_model'].value+" { hostname="+$q_struct['hostname'].value+" default_route="+$q_struct['default_route'].value+" ip_address="+$q_struct['ip_address'].value+" netmask="+$q_struct['netmask'].value+" }"
  end
  return network
end

# Set mirror disk

def set_js_mirror_disk(options)
  if $q_struct['mirror_disk'].value.match(/no/)
    $q_struct['mirror_disk_id'].ask  = "no"
    $q_struct['mirror_disk_id'].type = ""
  end
  return options
end

# Get Jumpstart flash location

def get_js_flash_location(options)
  flash_location = $q_struct['flash_method'].value+"://"+$q_struct['flash_host'].value+"/"+$q_struct['flash_file'].value
  return flash_location
end

# Get fs layout
def get_js_zfs_layout(options)
  if $q_struct['system_model'].value.match(/vm/)
    $q_struct['swap_size'].value = "auto"
  end
  if $q_struct['mirror_disk'].value.match(/yes/)
    zfs_layout = $q_struct['rpool_name'].value+" "+$q_struct['disk_size'].value+" "+$q_struct['swap_size'].value+" "+$q_struct['dump_size'].value+" mirror "+$q_struct['root_disk_id'].value+"s0 "+$q_struct['mirror_disk_id'].value+"s0"
  else
    zfs_layout = $q_struct['rpool_name'].value+" "+$q_struct['disk_size'].value+" "+$q_struct['swap_size'].value+" "+$q_struct['dump_size'].value+" "+$q_struct['root_disk_id'].value+"s0"
  end
  return zfs_layout
end

# Get ZFS bootenv

def get_js_zfs_bootenv(options)
  zfs_bootenv = "installbe bename "+options['service']
  return zfs_bootenv
end

# Get UFS filesys entries

def get_js_ufs_filesys(options,fs_mount,fs_slice,fs_mirror,fs_size)
  if $q_struct['mirror_disk'].value.match(/no/)
    if $q_struct['root_disk_id'].value.match(/any/)
      filesys_entry = $q_struct['root_disk_id'].value+" "+fs_size+" "+fs_mount
    else
      filesys_entry = $q_struct['root_disk_id'].value+fs_slice+" "+fs_size+" "+fs_mount
    end
  else
    filesys_entry = "mirror:"+fs_mirror+" "+$q_struct['root_disk_id'].value+fs_slice+" "+$q_struct['mirror_disk_id'].value+fs_slice+" "+fs_size+" "+fs_mount
  end
  return filesys_entry
end

def get_js_filesys(options,fs_name)
  if not $q_struct['root_fs'].value.downcase.match(/zfs/)
    (f_struct,f_order) = populate_js_fs_list(options)
    f_order            = ""
    fs_mount           = f_struct[fs_name].mount
    fs_slice           = f_struct[fs_name].slice
    key_name           = fs_name+"_size"
    fs_size            = $q_struct[key_name].value
    fs_mirror          = f_struct[fs_name].mirror
    filesys_entry      = get_js_ufs_filesys(fs_mount,fs_slice,fs_mirror,fs_size)
  end
  return filesys_entry
end

# Get metadb entry

def get_js_metadb(options)
  if not $q_struct['root_fs'].value.downcase.match(/zfs/) and not $q_struct['mirror_disk'].value.match(/no/)
    metadb_entry = $q_struct['root_disk_id'].value+"s7 size "+$q_struct['metadb_size'].value+" count "+$q_struct['metadb_count'].value
  end
  return metadb_entry
end

# Get root metadb entry

def get_js_root_metadb(options)
  if not $q_struct['root_fs'].value.downcase.match(/zfs/) and not $q_struct['mirror_disk'].value.match(/no/)
    metadb_entry = $q_struct['root_disk_id'].value+"s7 size "+$q_struct['metadb_size'].value+" count "+$q_struct['metadb_count'].value
  end
  return metadb_entry
end

# Get mirror metadb entry

def get_js_mirror_metadb(options)
  if not $q_struct['root_fs'].value.downcase.match(/zfs/) and not $q_struct['mirror_disk'].value.match(/no/)
    metadb_entry = $q_struct['mirror_disk_id'].value+"s7"
  end
  return metadb_entry
end

# Get dump size

def get_js_dump_size(options)
  if $q_struct['system_model'].value.downcase.match(/vm/)
    dump_size = "auto"
  else
    dump_size = $q_struct['memory_size'].value
  end
  return dump_size
end

# Set password crypt

def set_js_password_crypt(options,answer)
  password_crypt = get_password_crypt(answer)
  $q_struct['root_crypt'].value = password_crypt
  return options
end

# Get password crypt

def get_js_password_crypt(options)
  password_crypt = $q_struct['root_crypt'].value
  return password_crypt
end

# Populate Jumpstart machine file

def populate_js_machine_questions(options)
  # $q_struct = {}
  # $q_order  = []

  # Store system model information from previous set of questions

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

  name = "system_model"
  config = Js.new(
    type      = "",
    question  = "System Model",
    ask       = "yes",
    parameter = "",
    value     = options['model'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  options['model'] = $q_struct['system_model'].value
  # options = get_arch_from_model(options)

  name = "root_disk_id"
  config = Js.new(
    type      = "",
    question  = "System Disk",
    ask       = "yes",
    parameter = "",
    value     = "get_js_root_disk_id(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['model'].downcase.match(/vm/)
    mirror_disk = "no"
  else
    if options['mirrordisk'] == true
      mirror_disk = "yes"
    else
      mirror_disk = "no"
    end
  end

  name = "mirror_disk"
  config = Js.new(
    type      = "",
    question  = "Mirror Disk",
    ask       = "yes",
    parameter = "",
    value     = mirror_disk,
    valid     = "yes,no",
    eval      = "set_js_mirror_disk(options)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "mirror_disk_id"
  if options['model'].to_s.match(/[a-z]/)
    config = Js.new(
      type      = "",
      question  = "System Disk",
      ask       = "yes",
      parameter = "",
      value     = "get_js_mirror_disk_id(options)",
      valid     = "",
      eval      = "no"
      )
  else
    config = Js.new(
      type      = "",
      question  = "System Disk",
      ask       = "no",
      parameter = "",
      value     = "get_js_mirror_disk_id(options)",
      valid     = "",
      eval      = "no"
      )
  end
  $q_struct[name] = config
  $q_order.push(name)

  name = "memory_size"
  config = Js.new(
    type      = "",
    question  = "System Memory Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_memory_size(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "disk_size"
  config = Js.new(
    type      = "",
    question  = "System Memory Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_disk_size(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "dump_size"
  config = Js.new(
    type      = "",
    question  = "System Dump Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_dump_size(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['image'].to_s.match(/flar/)
    options['install'] = "flash_install"
  end

  name = "install_type"
  config = Js.new(
    type      = "output",
    question  = "Install Type",
    ask       = "yes",
    parameter = "install_type",
    value     = options['install'],
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['image'].to_s.match(/flar/)

    archive_url = "http://"+options['publisherhost']+options['image']

    name = "archive_location"
    config = Js.new(
      type      = "output",
      question  = "Install Type",
      ask       = "yes",
      parameter = "archive_location",
      value     = archive_url,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  if not options['image'].to_s.match(/flar/)

    name = "system_type"
    config = Js.new(
      type      = "output",
      question  = "System Type",
      ask       = "yes",
      parameter = "system_type",
      value     = "server",
      valid     = "",
      eval      = ""
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "cluster"
    config = Js.new(
      type      = "output",
      question  = "Install Cluser",
      ask       = "yes",
      parameter = "cluster",
      value     = "SUNWCall",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  name = "disk_partitioning"
  config = Js.new(
    type      = "output",
    question  = "Disk Paritioning",
    ask       = "yes",
    parameter = "partitioning",
    value     = "explicit",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['version'].to_i == 10
    if Integer(options['update']) >= 6

      name = "root_fs"
      config = Js.new(
        type      = "",
        question  = "Root filesystem",
        ask       = "yes",
        parameter = "",
        value     = "zfs",
        valid     = "",
        eval      = "options = set_js_fs(options)"
        )
      $q_struct[name] = config
      $q_order.push(name)

      name = "rpool_name"
      config = Js.new(
        type      = "",
        question  = "Root Pool Name",
        ask       = "yes",
        parameter = "",
        value     = options['zpoolname'],
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

    end
  end

  (f_struct,f_order) = populate_js_fs_list(options)

  f_order.each do |fs_name|

    if options['service'].to_s.match(/sol_10_0[6-9]|sol_10_[10,11]/) and $q_struct['root_fs'].value.match(/zfs/)
      fs_size = "auto"
    else
      fs_size = f_struct[fs_name].size
    end

    name = f_struct[fs_name].name+"_size"
    config = Js.new(
      type      = "",
      question  = f_struct[fs_name].name.capitalize+" Size",
      ask       = "yes",
      parameter = "",
      value     = fs_size,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    funct_string="get_js_filesys(\""+fs_name+"\")"

    if not options['service'].to_s.match(/sol_10/)

      name = f_struct[fs_name].name+"_fs"
      config = Js.new(
        type      = "output",
        question  = "UFS Root File System",
        ask       = "yes",
        parameter = "filesys",
        value     = funct_string,
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

    end

  end

  if options['service'].to_s.match(/sol_10_0[6-9]|sol_10_[10,11]/) and $q_struct['root_fs'].value.match(/zfs/)

    name = "zfs_layout"
    config = Js.new(
      type      = "output",
      question  = "ZFS File System Layout",
      ask       = "yes",
      parameter = "pool",
      value     = "get_js_zfs_layout(options)",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    zfs_bootenv=get_js_zfs_bootenv(options)

    name = "zfs_bootenv"
    config = Js.new(
      type      = "output",
      question  = "File System Layout",
      ask       = "yes",
      parameter = "bootenv",
      value     = zfs_bootenv,
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  if not $q_struct['mirror_disk'].value.match(/no/)

    name = "metadb_size"
    config = Js.new(
      type      = "",
      question  = "Metadb Size",
      ask       = "yes",
      parameter = "",
      value     = "16384",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)
  
    name = "metadb_count"
    config = Js.new(
      type      = "",
      question  = "Metadb Count",
      ask       = "yes",
      parameter = "",
      value     = "3",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "root_metadb"
    config = Js.new(
      type      = "output",
      question  = "Root Disk Metadb",
      ask       = "yes",
      parameter = "metadb",
      value     = "get_js_root_metadb(options)",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

    name = "mirror_metadb"
    config = Js.new(
      type      = "output",
      question  = "Mirror Disk Metadb",
      ask       = "yes",
      parameter = "metadb",
      value     = "get_js_mirror_metadb(options)",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end
  return options
end

# Populate Jumpstart sysidcfg questions

def populate_js_sysid_questions(options)
  options['ip'] = single_install_ip(options)

  # $q_struct = {}
  # $q_order  = []

  name = "hostname"
  config = Js.new(
    type      = "",
    question  = "System Hostname",
    ask       = "yes",
    parameter = "",
    value     = options['name'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config

  name = "os_version"
  config = Js.new(
    type      = "",
    question  = "OS Version",
    ask       = "yes",
    parameter = "",
    value     = options['version'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config

  name = "os_update"
  config = Js.new(
    type      = "",
    question  = "OS Update",
    ask       = "yes",
    parameter = "",
    value     = options['version'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config

  name = "ip_address"
  config = Js.new(
    type      = "",
    question  = "System IP",
    ask       = "yes",
    parameter = "",
    value     = options['ip'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "netmask"
  config = Js.new(
    type      = "",
    question  = "System Netmask",
    ask       = "yes",
    parameter = "",
    value     = options['netmask'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  ipv4_default_route=get_ipv4_default_route(options)

  name = "system_model"
  config = Js.new(
    type      = "",
    question  = "System Model",
    ask       = "yes",
    parameter = "",
    value     = options['model'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if not options['arch'].to_s.match(/i386|sun4/)

    name = "system_karch"
    config = Js.new(
      type      = "",
      question  = "System Kernel Architecture",
      ask       = "yes",
      parameter = "",
      value     = "get_js_system_karch(options)",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  else

    name = "system_karch"
    config = Js.new(
      type      = "",
      question  = "System Kernel Architecture",
      ask       = "yes",
      parameter = "",
      value     = options['arch'],
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  name = "nic_model"
  config = Js.new(
    type      = "",
    question  = "Network Interface",
    ask       = "yes",
    parameter = "",
    value     = "get_js_nic_model(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "default_route"
  config = Js.new(
    type      = "",
    question  = "Default Route",
    ask       = "yes",
    parameter = "",
    value     = ipv4_default_route,
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if Integer(options['version']) > 7

    name = "protocol_ipv6"
    config = Js.new(
      type      = "",
      question  = "IPv6",
      ask       = "yes",
      parameter = "",
      value     = "no",
      valid     = "",
      eval      = "no"
      )
    $q_struct[name] = config
    $q_order.push(name)

  end

  name = "network_interface"
  config = Js.new(
    type      = "output",
    question  = "Network Interface",
    ask       = "yes",
    parameter = "network_interface",
    value     = "get_js_network(options)",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "timezone"
  config = Js.new(
    type      = "output",
    question  = "Timezone",
    ask       = "yes",
    parameter = "timezone",
    value     = options['timezone'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "system_locale"
  config = Js.new(
    type      = "output",
    question  = "System Locale",
    ask       = "yes",
    parameter = "system_locale",
    value     = options['systemlocale'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "keyboard"
  config = Js.new(
    type      = "output",
    question  = "Keyboard Type",
    ask       = "yes",
    parameter = "keyboard",
    value     = "US-English",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "terminal"
  config = Js.new(
    type      = "output",
    question  = "Terminal Type",
    ask       = "yes",
    parameter = "terminal",
    value     = "sun-cmd",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_password"
  config = Js.new(
    type      = "",
    question  = "Root password",
    ask       = "yes",
    parameter = "",
    value     = options['rootpassword'],
    valid     = "",
    eval      = "options = set_js_password_crypt(options,answer)"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "root_crypt"
  config = Js.new(
    type      = "output",
    question  = "Root password (encrypted)",
    ask       = "no",
    parameter = "root_password",
    value     = "get_password_crypt(options['rootpassword'])",
    valid     = "",
    eval      = ""
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "timeserver"
  config = Js.new(
    type      = "output",
    question  = "Timeserver",
    ask       = "yes",
    parameter = "timeserver",
    value     = "localhost",
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  name = "name_service"
  config = Js.new(
    type      = "output",
    question  = "Name Service",
    ask       = "yes",
    parameter = "name_service",
    value     = options['nameservice'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['version'].to_i == 10
    if options['update'].to_i >= 5

      name = "nfs4_domain"
      config = Js.new(
        type      = "output",
        question  = "NFSv4 Domain",
        ask       = "yes",
        parameter = "nfs4_domain",
        value     = options['nfs4domain'],
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

    end
  end

  name = "security_policy"
  config = Js.new(
    type      = "output",
    question  = "Security",
    ask       = "yes",
    parameter = "security_policy",
    value     = options['security'],
    valid     = "",
    eval      = "no"
    )
  $q_struct[name] = config
  $q_order.push(name)

  if options['version'].to_i == 10
    if options['update'].to_i >= 10

      name = "auto_reg"
      config = Js.new(
        type      = "output",
        question  = "Auto Registration",
        ask       = "yes",
        parameter = "auto_reg",
        value     = options['autoreg'],
        valid     = "",
        eval      = "no"
        )
      $q_struct[name] = config
      $q_order.push(name)

    end
  end
  return options
end
