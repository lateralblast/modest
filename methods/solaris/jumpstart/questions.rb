# frozen_string_literal: true

# Jumpstart questions

# Get system architecture for sparc (sun4u/sun4v)

def get_js_system_karch(values)
  system_model = values['answers']['system_model'].value
  if !system_model.match(/vm|i386/)
    if system_model.downcase.match(/^t/)
      'sun4v'
    else
      'sun4u'
    end
  else
    'i86pc'
  end
end

# Get disk id based on model

def get_js_nic_model(values)
  if values['nic'] != values['empty']
    nic_model = values['nic']
  else
    nic_model = 'e1000g0'
    case values['answers']['system_model'].value.downcase
    when /445|t1000/
      nic_model = 'bge0'
    when /280|440|480|490|4x0/
      nic_model = 'eri0'
    when /880|890|8x0/
      nic_model = 'ce0'
    when /250|450|220/
      nic_model = 'hme0'
    when /^t4/
      nic_model = 'igb0'
    end
  end
  nic_model
end

# Get disk id based on model

def get_js_root_disk_id(values)
  if values['rootdisk'].to_s.match(/c[0-9]/)
    root_disk_id = values['rootdisk']
  else
    root_disk_id = 'c0t0d0'
    case values['answers']['system_model'].value.downcase
    when /vm/
      root_disk_id = 'any'
    when /445|440|480|490|4x0|880|890|8x0|t5220|t5120|t5xx0|t5140|t5240|t5440/
      root_disk_id = 'c1t0d0'
    when /100|120|x1/
      root_disk_id = 'c0t2d0'
    end
  end
  root_disk_id
end

# Get mirror disk id

def get_js_mirror_disk_id(values)
  if values['mirrordisk'].to_s.match(/c[0-9]/)
    mirror_disk_id = values['mirrordisk']
  else
    root_disk_id = values['answers']['root_disk_id'].value
    if !root_disk_id.match(/any/)
      mirror_controller_id = root_disk_id.split(/t/)[0].gsub(/^c/, '')
      mirror_target_id     = root_disk_id.split(/t/)[1].split(/d/)[0]
      mirror_disk_id       = root_disk_id.split(/d/)[1]
      system_model         = values['answers']['system_model'].value.downcase
      if !mirror_target_id.match(/[A-Z]/)
        case system_model
        when /^v8/
          mirror_target_id = Integer(mirror_target_id) + 3
        when /^e6/
          mirror_controller_id = Integer(mirror_controller_id) + 1
        else
          mirror_target_id = Integer(mirror_target_id) + 1
        end
        mirror_disk_id = "c#{mirror_controller_id}t#{mirror_target_id}d#{mirror_disk_id}"
      else
        mirror_disk_id = 'any'
      end
    else
      mirror_disk_id = 'any'
    end
  end
  mirror_disk_id
end

# Get disk size based on model

def get_js_disk_size(values)
  case values['answers']['system_model'].value.downcase
  when /vm/
    'auto'
  when /t5220|t5120|t5xx0|t5140|t5240|t5440|t6300|t6xx0|t6320|t6340/
    '146g'
  when /280/
    '36g'
  else
    'auto'
  end
end

# Get disk size based on model

def get_js_memory_size(values)
  case values['answers']['system_model'].value.downcase
  when /280|250|450|220/
    '2g'
  when /100|120|x1|vm/
    '1g'
  else
    'auto'
  end
end

# Set Jumpstart filesystem

def set_js_fs(values)
  if values['answers']['root_fs'].value.downcase.match(/zfs/)
    ['memory_size", "disk_size", "swap_size", "root_metadb", "mirror_metadb", "metadb_size", "metadb_count'].each do |key|
      if values['answers'][key]
        values['answers'][key].ask  = 'no'
        values['answers'][key].type = ''
      end
    end
  else
    values['answers']['zfs_layout'].ask  = 'no'
    values['answers']['zfs_bootenv'].ask = 'no'
    (_, f_order) = populate_js_fs_list(values)
    f_order.each do |fs_name|
      key = "#{fs_name}_filesys"
      values['answers'][key].ask  = 'no'
      values['answers'][key].type = ''
      key = "#{fs_name}_size"
      values['answers'][key].ask  = 'no'
      values['answers'][key].type = ''
    end
  end
  values
end

# Get Jumpstart network information

def get_js_network(values)
  values['version'] = values['answers']['os_version'].value
  if Integer(values['version']) > 7
    network = "#{values['answers']['nic_model'].value} { hostname=#{values['answers']['hostname'].value} default_route=#{values['answers']['default_route'].value} ip_address=#{values['answers']['ip_address'].value} netmask=#{values['answers']['netmask'].value} protocol_ipv6=#{values['answers']['protocol_ipv6'].value} }"
  else
    network = "#{values['answers']['nic_model'].value} { hostname=#{values['answers']['hostname'].value} default_route=#{values['answers']['default_route'].value} ip_address=#{values['answers']['ip_address'].value} netmask=#{values['answers']['netmask'].value} }"
  end
  network
end

# Set mirror disk

def set_js_mirror_disk(values)
  if values['answers']['mirror_disk'].value.match(/no/)
    values['answers']['mirror_disk_id'].ask  = 'no'
    values['answers']['mirror_disk_id'].type = ''
  end
  values
end

# Get Jumpstart flash location

def get_js_flash_location(values)
  "#{values['answers']['flash_method'].value}://#{values['answers']['flash_host'].value}/#{values['answers']['flash_file'].value}"
end

# Get fs layout
def get_js_zfs_layout(values)
  values['answers']['swap_size'].value = 'auto' if values['answers']['system_model'].value.match(/vm/)
  if values['answers']['mirror_disk'].value.match(/yes/)
    zfs_layout = "#{values['answers']['rpool_name'].value} #{values['answers']['disk_size'].value} #{values['answers']['swap_size'].value} #{values['answers']['dump_size'].value} mirror #{values['answers']['root_disk_id'].value}s0 #{values['answers']['mirror_disk_id'].value}s0"
  else
    zfs_layout = "#{values['answers']['rpool_name'].value} #{values['answers']['disk_size'].value} #{values['answers']['swap_size'].value} #{values['answers']['dump_size'].value} #{values['answers']['root_disk_id'].value}s0"
  end
  zfs_layout
end

# Get ZFS bootenv

def get_js_zfs_bootenv(values)
  "installbe bename #{values['service']}"
end

# Get UFS filesys entries

def get_js_ufs_filesys(values, fs_mount, fs_slice, fs_mirror, fs_size)
  if values['answers']['mirror_disk'].value.match(/no/)
    if values['answers']['root_disk_id'].value.match(/any/)
      "#{values['answers']['root_disk_id'].value} #{fs_size} #{fs_mount}"
    else
      "#{values['answers']['root_disk_id'].value}#{fs_slice} #{fs_size} #{fs_mount}"
    end
  else
    "mirror:#{fs_mirror} #{values['answers']['root_disk_id'].value}#{fs_slice} #{values['answers']['mirror_disk_id'].value}#{fs_slice} #{fs_size} #{fs_mount}"
  end
end

def get_js_filesys(values, fs_name)
  unless values['answers']['root_fs'].value.downcase.match(/zfs/)
    (f_struct,) = populate_js_fs_list(values)
    fs_mount  = f_struct[fs_name].mount
    fs_slice  = f_struct[fs_name].slice
    key_name  = "#{fs_name}_size"
    fs_size   = values['answers'][key_name].value
    fs_mirror = f_struct[fs_name].mirror
    filesys_entry = get_js_ufs_filesys(fs_mount, fs_slice, fs_mirror, fs_size)
  end
  filesys_entry
end

# Get metadb entry

def get_js_metadb(values)
  if !values['answers']['root_fs'].value.downcase.match(/zfs/) && !values['answers']['mirror_disk'].value.match(/no/)
    metadb_entry = "#{values['answers']['root_disk_id'].value}s7 size #{values['answers']['metadb_size'].value} count #{values['answers']['metadb_count'].value}"
  end
  metadb_entry
end

# Get root metadb entry

def get_js_root_metadb(values)
  if !values['answers']['root_fs'].value.downcase.match(/zfs/) && !values['answers']['mirror_disk'].value.match(/no/)
    metadb_entry = "#{values['answers']['root_disk_id'].value}s7 size #{values['answers']['metadb_size'].value} count #{values['answers']['metadb_count'].value}"
  end
  metadb_entry
end

# Get mirror metadb entry

def get_js_mirror_metadb(values)
  metadb_entry = "#{values['answers']['mirror_disk_id'].value}s7" if !values['answers']['root_fs'].value.downcase.match(/zfs/) && !values['answers']['mirror_disk'].value.match(/no/)
  metadb_entry
end

# Get dump size

def get_js_dump_size(values)
  if values['answers']['system_model'].value.downcase.match(/vm/)
    'auto'
  else
    values['answers']['memory_size'].value
  end
end

# Set password crypt

def set_js_password_crypt(values, answer)
  password_crypt = get_password_crypt(answer)
  values['answers']['root_crypt'].value = password_crypt
  values
end

# Get password crypt

def get_js_password_crypt(values)
  values['answers']['root_crypt'].value
end

# Populate Jumpstart machine file

def populate_js_machine_questions(values)
  js = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  # Store system model information from previous set of questions

  name   = 'headless_mode'
  config = js.new(
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

  name   = 'system_model'
  config = js.new(
    '',
    'System Model',
    'yes',
    '',
    values['model'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['model'] = values['answers']['system_model'].value
  # values = get_arch_from_model(values)

  name   = 'root_disk_id'
  config = js.new(
    '',
    'System Disk',
    'yes',
    '',
    'get_js_root_disk_id(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  mirror_disk = if values['model'].downcase.match(/vm/)
                  'no'
                elsif values['mirrordisk'] == true
                  'yes'
                else
                  'no'
                end

  name   = 'mirror_disk'
  config = js.new(
    type      = '',
    question  = 'Mirror Disk',
    ask       = 'yes',
    parameter = '',
    value     = mirror_disk,
    valid     = 'yes,no',
    eval      = 'set_js_mirror_disk(values)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'mirror_disk_id'

  config = if values['model'].to_s.match(/[a-z]/)

             js.new(
               type      = '',
               question  = 'System Disk',
               ask       = 'yes',
               parameter = '',
               value     = 'get_js_mirror_disk_id(values)',
               valid     = '',
               eval      = 'no'
             )

           else

             js.new(
               type      = '',
               question  = 'System Disk',
               ask       = 'no',
               parameter = '',
               value     = 'get_js_mirror_disk_id(values)',
               valid     = '',
               eval      = 'no'
             )

           end

  values['answers'][name] = config
  values['order'].push(name)

  name   = 'memory_size'
  config = js.new(
    '',
    'System Memory Size',
    'yes',
    '',
    'get_js_memory_size(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'disk_size'
  config = js.new(
    '',
    'System Memory Size',
    'yes',
    '',
    'get_js_disk_size(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'dump_size'
  config = js.new(
    '',
    'System Dump Size',
    'yes',
    '',
    'get_js_dump_size(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['install'] = 'flash_install' if values['image'].to_s.match(/flar/)

  name   = 'install_type'
  config = js.new(
    type      = 'output',
    question  = 'Install Type',
    ask       = 'yes',
    parameter = 'install_type',
    value     = values['install'],
    valid     = '',
    eval      = ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['image'].to_s.match(/flar/)

    archive_url = "http://#{values['publisherhost']}#{values['image']}"

    name   = 'archive_location'
    config = js.new(
      type      = 'output',
      question  = 'Install Type',
      ask       = 'yes',
      parameter = 'archive_location',
      value     = archive_url,
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  unless values['image'].to_s.match(/flar/)

    name   = 'system_type'
    config = js.new(
      'output',
      'System Type',
      'yes',
      'system_type',
      'server',
      '',
      ''
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'cluster'
    config = js.new(
      type      = 'output',
      question  = 'Install Cluser',
      ask       = 'yes',
      parameter = 'cluster',
      value     = 'SUNWCall',
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'disk_partitioning'
  config = js.new(
    type      = 'output',
    question  = 'Disk Paritioning',
    ask       = 'yes',
    parameter = 'partitioning',
    value     = 'explicit',
    valid     = '',
    eval      = 'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if (values['version'].to_i == 10) && (Integer(values['update']) >= 6)

    name = 'root_fs'
    config = js.new(
      '',
      'Root filesystem',
      'yes',
      '',
      'zfs',
      '',
      'values = set_js_fs(values)'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name = 'rpool_name'
    config = js.new(
      type      = '',
      question  = 'Root Pool Name',
      ask       = 'yes',
      parameter = '',
      value     = values['zpoolname'],
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  (f_struct, f_order) = populate_js_fs_list(values)

  f_order.each do |fs_name|
    fs_size = if values['service'].to_s.match(/sol_10_0[6-9]|sol_10_[10,11]/) && values['answers']['root_fs'].value.match(/zfs/)
                'auto'
              else
                f_struct[fs_name].size
              end

    name   = "#{f_struct[fs_name].name}_size"
    config = js.new(
      type      = '',
      question  = "#{f_struct[fs_name].name.capitalize} Size",
      ask       = 'yes',
      parameter = '',
      value     = fs_size,
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    funct_string = "get_js_filesys(\"#{fs_name}\")"

    next if values['service'].to_s.match(/sol_10/)

    name   = "#{f_struct[fs_name].name}_fs"
    config = js.new(
      type      = 'output',
      question  = 'UFS Root File System',
      ask       = 'yes',
      parameter = 'filesys',
      value     = funct_string,
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)
  end

  if values['service'].to_s.match(/sol_10_0[6-9]|sol_10_[10,11]/) && values['answers']['root_fs'].value.match(/zfs/)

    name   = 'zfs_layout'
    config = js.new(
      type      = 'output',
      question  = 'ZFS File System Layout',
      ask       = 'yes',
      parameter = 'pool',
      value     = 'get_js_zfs_layout(values)',
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    zfs_bootenv = get_js_zfs_bootenv(values)

    name   = 'zfs_bootenv'
    config = js.new(
      type      = 'output',
      question  = 'File System Layout',
      ask       = 'yes',
      parameter = 'bootenv',
      value     = zfs_bootenv,
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  unless values['answers']['mirror_disk'].value.match(/no/)

    name   = 'metadb_size'
    config = js.new(
      type      = '',
      question  = 'Metadb Size',
      ask       = 'yes',
      parameter = '',
      value     = '16384',
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'metadb_count'
    config = js.new(
      type      = '',
      question  = 'Metadb Count',
      ask       = 'yes',
      parameter = '',
      value     = '3',
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'root_metadb'
    config = js.new(
      type      = 'output',
      question  = 'Root Disk Metadb',
      ask       = 'yes',
      parameter = 'metadb',
      value     = 'get_js_root_metadb(values)',
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'mirror_metadb'
    config = js.new(
      type      = 'output',
      question  = 'Mirror Disk Metadb',
      ask       = 'yes',
      parameter = 'metadb',
      value     = 'get_js_mirror_metadb(values)',
      valid     = '',
      eval      = 'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end
  values
end

# Populate Jumpstart sysidcfg questions

def populate_js_sysid_questions(values)
  values['ip'] = single_install_ip(values)

  # values['answers'] = {}
  # values['order']  = []

  name   = 'hostname'
  config = js.new(
    '',
    'System Hostname',
    'yes',
    '',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config

  name   = 'os_version'
  config = js.new(
    '',
    'OS Version',
    'yes',
    '',
    values['version'],
    '',
    'no'
  )
  values['answers'][name] = config

  name   = 'os_update'
  config = js.new(
    '',
    'OS Update',
    'yes',
    '',
    values['version'],
    '',
    'no'
  )
  values['answers'][name] = config

  name   = 'ip_address'
  config = js.new(
    '',
    'System IP',
    'yes',
    '',
    values['ip'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'netmask'
  config = js.new(
    '',
    'System Netmask',
    'yes',
    '',
    values['netmask'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  ipv4_default_route = get_ipv4_default_route(values)

  name   = 'system_model'
  config = js.new(
    '',
    'System Model',
    'yes',
    '',
    values['model'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'system_karch'
  config = if !values['arch'].to_s.match(/i386|sun4/)

             js.new(
               '',
               'System Kernel Architecture',
               'yes',
               '',
               'get_js_system_karch(values)',
               '',
               'no'
             )

           else

             js.new(
               '',
               'System Kernel Architecture',
               'yes',
               '',
               values['arch'],
               '',
               'no'
             )

           end
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'nic_model'
  config = js.new(
    '',
    'Network Interface',
    'yes',
    '',
    'get_js_nic_model(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'default_route'
  config = js.new(
    '',
    'Default Route',
    'yes',
    '',
    ipv4_default_route,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if Integer(values['version']) > 7

    name   = 'protocol_ipv6'
    config = js.new(
      '',
      'IPv6',
      'yes',
      '',
      'no',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'network_interface'
  config = js.new(
    'output',
    'Network Interface',
    'yes',
    'network_interface',
    'get_js_network(values)',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'timezone'
  config = js.new(
    'output',
    'Timezone',
    'yes',
    'timezone',
    values['timezone'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'system_locale'
  config = js.new(
    'output',
    'System Locale',
    'yes',
    'system_locale',
    values['systemlocale'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'keyboard'
  config = js.new(
    'output',
    'Keyboard Type',
    'yes',
    'keyboard',
    'US-English',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'terminal'
  config = js.new(
    'output',
    'Terminal Type',
    'yes',
    'terminal',
    'sun-cmd',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_password'
  config = js.new(
    '',
    'Root password',
    'yes',
    '',
    values['rootpassword'],
    '',
    'values = set_js_password_crypt(values,answer)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_crypt'
  config = js.new(
    'output',
    'Root password (encrypted)',
    'no',
    'root_password',
    "get_password_crypt(values['rootpassword'])",
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'timeserver'
  config = js.new(
    'output',
    'Timeserver',
    'yes',
    'timeserver',
    'localhost',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'name_service'
  config = js.new(
    'output',
    'Name Service',
    'yes',
    'name_service',
    values['nameservice'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if (values['version'].to_i == 10) && (values['update'].to_i >= 5)

    name = 'nfs4_domain'
    config = js.new(
      'output',
      'NFSv4 Domain',
      'yes',
      'nfs4_domain',
      values['nfs4domain'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'security_policy'
  config = js.new(
    'output',
    'Security',
    'yes',
    'security_policy',
    values['security'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if (values['version'].to_i == 10) && (values['update'].to_i >= 10)

    name = 'auto_reg'
    config = js.new(
      'output',
      'Auto Registration',
      'yes',
      'auto_reg',
      values['autoreg'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  values
end
