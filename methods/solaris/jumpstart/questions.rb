

# Jumpstart questions

# Get system architecture for sparc (sun4u/sun4v)

def get_js_system_karch(values)
  system_model = values['answers']['system_model'].value
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

def get_js_nic_model(values)
  if values['nic'] != values['empty']
    nic_model = values['nic']
  else
    nic_model = "e1000g0"
    case values['answers']['system_model'].value.downcase
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

def get_js_root_disk_id(values)
  if values['rootdisk'].to_s.match(/c[0-9]/)
    root_disk_id = values['rootdisk']
  else
    root_disk_id = "c0t0d0"
    case values['answers']['system_model'].value.downcase
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

def get_js_mirror_disk_id(values)
  if values['mirrordisk'].to_s.match(/c[0-9]/)
    mirror_disk_id = values['mirrordisk']
  else
    root_disk_id = values['answers']['root_disk_id'].value
    if not root_disk_id.match(/any/)
      mirror_controller_id = root_disk_id.split(/t/)[0].gsub(/^c/, "")
      mirror_target_id     = root_disk_id.split(/t/)[1].split(/d/)[0]
      mirror_disk_id       = root_disk_id.split(/d/)[1]
      system_model         = values['answers']['system_model'].value.downcase
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

def get_js_disk_size(values)
  case values['answers']['system_model'].value.downcase
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

def get_js_memory_size(values)
  case values['answers']['system_model'].value.downcase
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

def set_js_fs(values)
  fs_name = ""
  if values['answers']['root_fs'].value.downcase.match(/zfs/)
    ['memory_size", "disk_size", "swap_size", "root_metadb", "mirror_metadb", "metadb_size", "metadb_count'].each do |key|
      if values['answers'][key]
        values['answers'][key].ask  = "no"
        values['answers'][key].type = ""
      end
    end
  else
    values['answers']['zfs_layout'].ask  = "no"
    values['answers']['zfs_bootenv'].ask = "no"
    (f_struct, f_order) = populate_js_fs_list(values)
    f_struct = ""
    f_order.each do |fs_name|
      key                 = fs_name+"_filesys"
      values['answers'][key].ask  = "no"
      values['answers'][key].type = ""
      key                 = fs_name+"_size"
      values['answers'][key].ask  = "no"
      values['answers'][key].type = ""
    end
  end
  return values
end

# Get Jumpstart network information

def get_js_network(values)
  values['version'] = values['answers']['os_version'].value
  if Integer(values['version']) > 7
    network = values['answers']['nic_model'].value+" { hostname="+values['answers']['hostname'].value+" default_route="+values['answers']['default_route'].value+" ip_address="+values['answers']['ip_address'].value+" netmask="+values['answers']['netmask'].value+" protocol_ipv6="+values['answers']['protocol_ipv6'].value+" }"
  else
    network = values['answers']['nic_model'].value+" { hostname="+values['answers']['hostname'].value+" default_route="+values['answers']['default_route'].value+" ip_address="+values['answers']['ip_address'].value+" netmask="+values['answers']['netmask'].value+" }"
  end
  return network
end

# Set mirror disk

def set_js_mirror_disk(values)
  if values['answers']['mirror_disk'].value.match(/no/)
    values['answers']['mirror_disk_id'].ask  = "no"
    values['answers']['mirror_disk_id'].type = ""
  end
  return values
end

# Get Jumpstart flash location

def get_js_flash_location(values)
  flash_location = values['answers']['flash_method'].value+"://"+values['answers']['flash_host'].value+"/"+values['answers']['flash_file'].value
  return flash_location
end

# Get fs layout
def get_js_zfs_layout(values)
  if values['answers']['system_model'].value.match(/vm/)
    values['answers']['swap_size'].value = "auto"
  end
  if values['answers']['mirror_disk'].value.match(/yes/)
    zfs_layout = values['answers']['rpool_name'].value+" "+values['answers']['disk_size'].value+" "+values['answers']['swap_size'].value+" "+values['answers']['dump_size'].value+" mirror "+values['answers']['root_disk_id'].value+"s0 "+values['answers']['mirror_disk_id'].value+"s0"
  else
    zfs_layout = values['answers']['rpool_name'].value+" "+values['answers']['disk_size'].value+" "+values['answers']['swap_size'].value+" "+values['answers']['dump_size'].value+" "+values['answers']['root_disk_id'].value+"s0"
  end
  return zfs_layout
end

# Get ZFS bootenv

def get_js_zfs_bootenv(values)
  zfs_bootenv = "installbe bename "+values['service']
  return zfs_bootenv
end

# Get UFS filesys entries

def get_js_ufs_filesys(values, fs_mount, fs_slice, fs_mirror, fs_size)
  if values['answers']['mirror_disk'].value.match(/no/)
    if values['answers']['root_disk_id'].value.match(/any/)
      filesys_entry = values['answers']['root_disk_id'].value+" "+fs_size+" "+fs_mount
    else
      filesys_entry = values['answers']['root_disk_id'].value+fs_slice+" "+fs_size+" "+fs_mount
    end
  else
    filesys_entry = "mirror:"+fs_mirror+" "+values['answers']['root_disk_id'].value+fs_slice+" "+values['answers']['mirror_disk_id'].value+fs_slice+" "+fs_size+" "+fs_mount
  end
  return filesys_entry
end

def get_js_filesys(values, fs_name)
  if not values['answers']['root_fs'].value.downcase.match(/zfs/)
    (f_struct, f_order) = populate_js_fs_list(values)
    f_order   = ""
    fs_mount  = f_struct[fs_name].mount
    fs_slice  = f_struct[fs_name].slice
    key_name  = fs_name+"_size"
    fs_size   = values['answers'][key_name].value
    fs_mirror = f_struct[fs_name].mirror
    filesys_entry = get_js_ufs_filesys(fs_mount, fs_slice, fs_mirror, fs_size)
  end
  return filesys_entry
end

# Get metadb entry

def get_js_metadb(values)
  if not values['answers']['root_fs'].value.downcase.match(/zfs/) and not values['answers']['mirror_disk'].value.match(/no/)
    metadb_entry = values['answers']['root_disk_id'].value+"s7 size "+values['answers']['metadb_size'].value+" count "+values['answers']['metadb_count'].value
  end
  return metadb_entry
end

# Get root metadb entry

def get_js_root_metadb(values)
  if not values['answers']['root_fs'].value.downcase.match(/zfs/) and not values['answers']['mirror_disk'].value.match(/no/)
    metadb_entry = values['answers']['root_disk_id'].value+"s7 size "+values['answers']['metadb_size'].value+" count "+values['answers']['metadb_count'].value
  end
  return metadb_entry
end

# Get mirror metadb entry

def get_js_mirror_metadb(values)
  if not values['answers']['root_fs'].value.downcase.match(/zfs/) and not values['answers']['mirror_disk'].value.match(/no/)
    metadb_entry = values['answers']['mirror_disk_id'].value+"s7"
  end
  return metadb_entry
end

# Get dump size

def get_js_dump_size(values)
  if values['answers']['system_model'].value.downcase.match(/vm/)
    dump_size = "auto"
  else
    dump_size = values['answers']['memory_size'].value
  end
  return dump_size
end

# Set password crypt

def set_js_password_crypt(values, answer)
  password_crypt = get_password_crypt(answer)
  values['answers']['root_crypt'].value = password_crypt
  return values
end

# Get password crypt

def get_js_password_crypt(values)
  password_crypt = values['answers']['root_crypt'].value
  return password_crypt
end

# Populate Jumpstart machine file

def populate_js_machine_questions(values)
  js = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  # Store system model information from previous set of questions

  name   = "headless_mode"
  config = js.new(
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

  name   = "system_model"
  config = js.new(
    type      = "",
    question  = "System Model",
    ask       = "yes",
    parameter = "",
    value     = values['model'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['model'] = values['answers']['system_model'].value
  # values = get_arch_from_model(values)

  name   = "root_disk_id"
  config = js.new(
    type      = "",
    question  = "System Disk",
    ask       = "yes",
    parameter = "",
    value     = "get_js_root_disk_id(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['model'].downcase.match(/vm/)
    mirror_disk = "no"
  else
    if values['mirrordisk'] == true
      mirror_disk = "yes"
    else
      mirror_disk = "no"
    end
  end

  name   = "mirror_disk"
  config = js.new(
    type      = "",
    question  = "Mirror Disk",
    ask       = "yes",
    parameter = "",
    value     = mirror_disk,
    valid     = "yes,no",
    eval      = "set_js_mirror_disk(values)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = "mirror_disk_id"

  if values['model'].to_s.match(/[a-z]/)
    
    config = js.new(
      type      = "",
      question  = "System Disk",
      ask       = "yes",
      parameter = "",
      value     = "get_js_mirror_disk_id(values)",
      valid     = "",
      eval      = "no"
    )

  else

    config = js.new(
      type      = "",
      question  = "System Disk",
      ask       = "no",
      parameter = "",
      value     = "get_js_mirror_disk_id(values)",
      valid     = "",
      eval      = "no"
    )

  end

  values['answers'][name] = config
  values['order'].push(name)

  name   = "memory_size"
  config = js.new(
    type      = "",
    question  = "System Memory Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_memory_size(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "disk_size"
  config = js.new(
    type      = "",
    question  = "System Memory Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_disk_size(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "dump_size"
  config = js.new(
    type      = "",
    question  = "System Dump Size",
    ask       = "yes",
    parameter = "",
    value     = "get_js_dump_size(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['image'].to_s.match(/flar/)
    values['install'] = "flash_install"
  end

  name   = "install_type"
  config = js.new(
    type      = "output",
    question  = "Install Type",
    ask       = "yes",
    parameter = "install_type",
    value     = values['install'],
    valid     = "",
    eval      = ""
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['image'].to_s.match(/flar/)

    archive_url = "http://"+values['publisherhost']+values['image']

    name   = "archive_location"
    config = js.new(
      type      = "output",
      question  = "Install Type",
      ask       = "yes",
      parameter = "archive_location",
      value     = archive_url,
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  if not values['image'].to_s.match(/flar/)

    name   = "system_type"
    config = js.new(
      type      = "output",
      question  = "System Type",
      ask       = "yes",
      parameter = "system_type",
      value     = "server",
      valid     = "",
      eval      = ""
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "cluster"
    config = js.new(
      type      = "output",
      question  = "Install Cluser",
      ask       = "yes",
      parameter = "cluster",
      value     = "SUNWCall",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "disk_partitioning"
  config = js.new(
    type      = "output",
    question  = "Disk Paritioning",
    ask       = "yes",
    parameter = "partitioning",
    value     = "explicit",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['version'].to_i == 10

    if Integer(values['update']) >= 6

      name   = "root_fs"
      config = js.new(
        type      = "",
        question  = "Root filesystem",
        ask       = "yes",
        parameter = "",
        value     = "zfs",
        valid     = "",
        eval      = "values = set_js_fs(values)"
      )
      values['answers'][name] = config
      values['order'].push(name)

      name = "rpool_name"
      config = js.new(
        type      = "",
        question  = "Root Pool Name",
        ask       = "yes",
        parameter = "",
        value     = values['zpoolname'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

  end

  (f_struct,f_order) = populate_js_fs_list(values)

  f_order.each do |fs_name|

    if values['service'].to_s.match(/sol_10_0[6-9]|sol_10_[10,11]/) and values['answers']['root_fs'].value.match(/zfs/)
      fs_size = "auto"
    else
      fs_size = f_struct[fs_name].size
    end

    name   = f_struct[fs_name].name+"_size"
    config = js.new(
      type      = "",
      question  = f_struct[fs_name].name.capitalize+" Size",
      ask       = "yes",
      parameter = "",
      value     = fs_size,
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    funct_string="get_js_filesys(\""+fs_name+"\")"

    if not values['service'].to_s.match(/sol_10/)

      name   = f_struct[fs_name].name+"_fs"
      config = js.new(
        type      = "output",
        question  = "UFS Root File System",
        ask       = "yes",
        parameter = "filesys",
        value     = funct_string,
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

  end

  if values['service'].to_s.match(/sol_10_0[6-9]|sol_10_[10,11]/) and values['answers']['root_fs'].value.match(/zfs/)

    name   = "zfs_layout"
    config = js.new(
      type      = "output",
      question  = "ZFS File System Layout",
      ask       = "yes",
      parameter = "pool",
      value     = "get_js_zfs_layout(values)",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    zfs_bootenv=get_js_zfs_bootenv(values)

    name   = "zfs_bootenv"
    config = js.new(
      type      = "output",
      question  = "File System Layout",
      ask       = "yes",
      parameter = "bootenv",
      value     = zfs_bootenv,
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  if not values['answers']['mirror_disk'].value.match(/no/)

    name   = "metadb_size"
    config = js.new(
      type      = "",
      question  = "Metadb Size",
      ask       = "yes",
      parameter = "",
      value     = "16384",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)
  
    name   = "metadb_count"
    config = js.new(
      type      = "",
      question  = "Metadb Count",
      ask       = "yes",
      parameter = "",
      value     = "3",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "root_metadb"
    config = js.new(
      type      = "output",
      question  = "Root Disk Metadb",
      ask       = "yes",
      parameter = "metadb",
      value     = "get_js_root_metadb(values)",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = "mirror_metadb"
    config = js.new(
      type      = "output",
      question  = "Mirror Disk Metadb",
      ask       = "yes",
      parameter = "metadb",
      value     = "get_js_mirror_metadb(values)",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end
  return values
end

# Populate Jumpstart sysidcfg questions

def populate_js_sysid_questions(values)
  values['ip'] = single_install_ip(values)

  # values['answers'] = {}
  # values['order']  = []

  name   = "hostname"
  config = js.new(
    type      = "",
    question  = "System Hostname",
    ask       = "yes",
    parameter = "",
    value     = values['name'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config

  name   = "os_version"
  config = js.new(
    type      = "",
    question  = "OS Version",
    ask       = "yes",
    parameter = "",
    value     = values['version'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config

  name   = "os_update"
  config = js.new(
    type      = "",
    question  = "OS Update",
    ask       = "yes",
    parameter = "",
    value     = values['version'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config

  name   = "ip_address"
  config = js.new(
    type      = "",
    question  = "System IP",
    ask       = "yes",
    parameter = "",
    value     = values['ip'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "netmask"
  config = js.new(
    type      = "",
    question  = "System Netmask",
    ask       = "yes",
    parameter = "",
    value     = values['netmask'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  ipv4_default_route=get_ipv4_default_route(values)

  name   = "system_model"
  config = js.new(
    type      = "",
    question  = "System Model",
    ask       = "yes",
    parameter = "",
    value     = values['model'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if not values['arch'].to_s.match(/i386|sun4/)

    name   = "system_karch"
    config = js.new(
      type      = "",
      question  = "System Kernel Architecture",
      ask       = "yes",
      parameter = "",
      value     = "get_js_system_karch(values)",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  else

    name   = "system_karch"
    config = js.new(
      type      = "",
      question  = "System Kernel Architecture",
      ask       = "yes",
      parameter = "",
      value     = values['arch'],
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "nic_model"
  config = js.new(
    type      = "",
    question  = "Network Interface",
    ask       = "yes",
    parameter = "",
    value     = "get_js_nic_model(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "default_route"
  config = js.new(
    type      = "",
    question  = "Default Route",
    ask       = "yes",
    parameter = "",
    value     = ipv4_default_route,
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if Integer(values['version']) > 7

    name   = "protocol_ipv6"
    config = js.new(
      type      = "",
      question  = "IPv6",
      ask       = "yes",
      parameter = "",
      value     = "no",
      valid     = "",
      eval      = "no"
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = "network_interface"
  config = js.new(
    type      = "output",
    question  = "Network Interface",
    ask       = "yes",
    parameter = "network_interface",
    value     = "get_js_network(values)",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "timezone"
  config = js.new(
    type      = "output",
    question  = "Timezone",
    ask       = "yes",
    parameter = "timezone",
    value     = values['timezone'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "system_locale"
  config = js.new(
    type      = "output",
    question  = "System Locale",
    ask       = "yes",
    parameter = "system_locale",
    value     = values['systemlocale'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "keyboard"
  config = js.new(
    type      = "output",
    question  = "Keyboard Type",
    ask       = "yes",
    parameter = "keyboard",
    value     = "US-English",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "terminal"
  config = js.new(
    type      = "output",
    question  = "Terminal Type",
    ask       = "yes",
    parameter = "terminal",
    value     = "sun-cmd",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_password"
  config = js.new(
    type      = "",
    question  = "Root password",
    ask       = "yes",
    parameter = "",
    value     = values['rootpassword'],
    valid     = "",
    eval      = "values = set_js_password_crypt(values,answer)"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "root_crypt"
  config = js.new(
    type      = "output",
    question  = "Root password (encrypted)",
    ask       = "no",
    parameter = "root_password",
    value     = "get_password_crypt(values['rootpassword'])",
    valid     = "",
    eval      = ""
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "timeserver"
  config = js.new(
    type      = "output",
    question  = "Timeserver",
    ask       = "yes",
    parameter = "timeserver",
    value     = "localhost",
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = "name_service"
  config = js.new(
    type      = "output",
    question  = "Name Service",
    ask       = "yes",
    parameter = "name_service",
    value     = values['nameservice'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['version'].to_i == 10

    if values['update'].to_i >= 5

      name   = "nfs4_domain"
      config = js.new(
        type      = "output",
        question  = "NFSv4 Domain",
        ask       = "yes",
        parameter = "nfs4_domain",
        value     = values['nfs4domain'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

  end

  name   = "security_policy"
  config = js.new(
    type      = "output",
    question  = "Security",
    ask       = "yes",
    parameter = "security_policy",
    value     = values['security'],
    valid     = "",
    eval      = "no"
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['version'].to_i == 10

    if values['update'].to_i >= 10

      name   = "auto_reg"
      config = js.new(
        type      = "output",
        question  = "Auto Registration",
        ask       = "yes",
        parameter = "auto_reg",
        value     = values['autoreg'],
        valid     = "",
        eval      = "no"
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

  end
  return values
end
