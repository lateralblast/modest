# frozen_string_literal: true

# Preseed configuration questions for Ubuntu

def populate_ps_questions(values)
  qs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

  install_ip1 = 'none'
  install_ip2 = 'none'
  install_ip3 = 'none'
  install_ip4 = 'none'
  install_ip5 = 'none'

  if values['packages'] == values['empty']
    pkg_list = %w[
      nfs-common openssh-server setserial net-tools ansible jq ipmitool screen ruby-build git cryptsetup curl
    ]
    pkg_list.append('linux-generic-hwe-18.04') if values['service'].match(/18_04/)
  else
    pkg_list = values['packages'].to_s.split(/,| /)
  end

  if values['ip'].to_s.match(/,/)
    full_ip = values['ip']
    values['ip'] = full_ip.split(/,/)[0]
    if full_ip[1]
      install_ip1 = full_ip.split(/,/)[1]
      install_ip1 ||= 'none'
    end
    if full_ip[2]
      install_ip2 = full_ip.split(/,/)[2]
      install_ip2 ||= 'none'
    end
    if full_ip[3]
      install_ip3 = full_ip.split(/,/)[3]
      install_ip3 ||= 'none'
    end
    if full_ip[4]
      install_ip4 = full_ip.split(/,/)[4]
      install_ip4 ||= 'none'
    end
    if full_ip[5]
      install_ip5 = full_ip.split(/,/)[5]
      install_ip5 ||= 'none'
    end
  end

  if values['service'].to_s != 'purity'

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

    language = values['language']
    language = 'en' if values['service'].match(/ubuntu_20/) && language.match(/en_/)

    name   = 'language'
    config = qs.new(
      'string',
      'Language',
      'yes',
      'debian-installer/language',
      language,
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'country'
    config = qs.new(
      'string',
      'Country',
      'yes',
      'debian-installer/country',
      values['country'],
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
      'debian-installer/locale',
      values['locale'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'console'
    config = qs.new(
      'boolean',
      'Enable keymap detection',
      'no',
      'console-setup/ask_detect',
      'false',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'layout'
    config = qs.new(
      'string',
      'Keyboard layout',
      'no',
      'keyboard-configuration/layoutcode',
      values['keyboard'].downcase,
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'disable_autoconfig'
    config = qs.new(
      'boolean',
      'Disable network autoconfig',
      'yes',
      'netcfg/disable_autoconfig',
      values['disableautoconf'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    disable_dhcp = if values['vm'].to_s.match(/vbox/) && values['type'].to_s.match(/packer/)
                     'false'
                   elsif values['service'].to_s.match(/live/) || values['vm'].to_s.match(/mp|multipass/)
                     if values['ip'] == values['empty']
                       'false'
                     else
                       'true'
                     end
                   else
                     'true'
                   end

    name   = 'disable_dhcp'
    config = qs.new(
      'boolean',
      'Disable DHCP',
      'yes',
      'netcfg/disable_dhcp',
      disable_dhcp,
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'admin_fullname'
  config = qs.new(
    'string',
    'User full name',
    'yes',
    'passwd/user-fullname',
    values['adminname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_username'
  config = qs.new(
    'string',
    'Username',
    'yes',
    'passwd/username',
    values['adminuser'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_shell'
  config = qs.new(
    'string',
    'Shell',
    'yes',
    'passwd/shell',
    values['adminshell'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_sudo'
  config = qs.new(
    'string',
    'Sudo',
    'yes',
    'passwd/sudo',
    values['adminsudo'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'sudoers'
  config = qs.new(
    '',
    'Admin sudoers',
    'yes',
    '',
    values['sudoers'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_password'
  config = qs.new(
    '',
    'User password',
    'yes',
    '',
    values['adminpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_crypt'
  config = qs.new(
    'password',
    'User Password Crypt',
    'yes',
    'passwd/user-password-crypted',
    get_password_crypt(values['adminpassword']),
    '',
    'get_password_crypt(answer)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'admin_groups'
  config = qs.new(
    'string',
    'User groups',
    'yes',
    'passwd/user-default-groups',
    'wheel',
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  if !values['method'] == 'ci'

    name   = 'admin_home_encrypt'
    config = qs.new(
      'boolean',
      'Encrypt user home directory',
      'yes',
      'user-setup/encrypt-home',
      'false',
      '',
      ''
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'locale'
  config = qs.new(
    'string',
    'Locale',
    'yes',
    'debian-installer/locale',
    values['locale'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  nic_name = if values['vmnic'] == values['empty']
               if values['nic'] != values['empty']
                 values['nic']
               else
                 get_nic_name_from_install_service(values)
               end
             elsif values['vmnic'] != values['empty']
               values['vmnic'].to_s
             elsif values['nic'] != values['empty']
               values['nic']
             else
               values['vmnic'].to_s
             end

  name   = 'interface'
  config = qs.new(
    'select',
    'Network interface',
    'yes',
    'netcfg/choose_interface',
    nic_name,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  values['answers']['nic'] = values['answers']['interface']
  values['order'].push(name)

  nameserver = if values['dnsmasq'] == true
                 "#{values['vmgateway']},#{values['nameserver']}"
               else
                 values['nameserver'].to_s
               end

  name   = 'nameserver'
  config = qs.new(
    'string',
    'Nameservers',
    'yes',
    'netcfg/get_nameservers',
    nameserver,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['answers']['disable_dhcp'].value.match(/true/)

    name   = 'ip'
    config = qs.new(
      'string',
      'IP address',
      'yes',
      'netcfg/get_ipaddress',
      values['ip'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'netmask'
    config = qs.new(
      'string',
      'Netmask',
      'yes',
      'netcfg/get_netmask',
      values['netmask'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  if values['service'].to_s.match(/live/) || values['vm'].to_s.match(/mp|multipass/)

    name   = 'cidr'
    config = qs.new(
      'string',
      'CIDR',
      'yes',
      'netcfg/get_cidr',
      values['cidr'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  gateway = if values['gateway'].to_s.match(/[0-9]/) && (values['vm'].to_s == values['empty'].to_s)
              values['gateway']
            elsif values['vmgateway'].to_s.split(/\./)[2] == values['ip'].to_s.split(/\./)[2]
              values['vmgateway']
            elsif values['gateway'].to_s.split(/\./)[2] == values['ip'].to_s.split(/\./)[2]
              values['gateway']
            elsif values['vmgateway'].to_s.match(/[0-9]/)
              values['vmgateway']
            elsif values['type'].to_s.match(/packer/)
              "#{values['ip'].split(/\./)[0..2].join('.')}.#{values['gatewaynode']}"
            elsif values['server'] == values['empty']
              values['hostip']
            else
              values['server']
            end

  gateway = `netstat -rn |grep "^0" |awk '{print $2}'`.chomp if gateway.to_s.split(/\./)[2] != values['ip'].to_s.split(/\./)[2]

  name   = 'gateway'
  config = qs.new(
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

  if values['answers']['disable_dhcp'].value.match(/true/)

    broadcast = "#{values['ip'].split(/\./)[0..2].join('.')}.255"

    name   = 'broadcast'
    config = qs.new(
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
    config = qs.new(
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

  end

  static = if values['dhcp'] == true
             'false'
           else
             'true'
           end

  name   = 'static'
  config = qs.new(
    'boolean',
    'Confirm Static',
    'yes',
    'netcfg/confirm_static',
    static,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'hostname'
  config = qs.new(
    'string',
    'Hostname',
    'yes',
    'netcfg/get_hostname',
    values['name'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  # if values['service'].to_s.match(/ubuntu/)
  #  if values['service'].to_s.match(/18_04/) and values['vm'].to_s.match(/vbox/)
  #    values['vmnic'] = "eth0"
  #  else
  #    if values['vm'].to_s.match(/kvm/)
  #      values['vmnic'] = "ens3"
  #    else
  #      if values['service'].to_s.match(/16_10/)
  #        if values['vm'].to_s.match(/fusion/)
  #          values['vmnic'] = "ens33"
  #        else
  #          values['vmnic'] = "enp0s3"
  #        end
  #      end
  #    end
  #  end
  # end

  #  name = "nic"
  #  config = qs.new(
  #    type      = "",
  #    question  = "NIC",
  #    ask       = "yes",
  #    parameter = "",
  #    value     = nic_name,
  #    valid     = "",
  #    eval      = "no"
  #    )
  #  values['answers'][name] = config
  #  values['order'].push(name)

  client_domain = values['domainname'].to_s

  name   = 'domain'
  config = qs.new(
    'string',
    'Domainname',
    'yes',
    'netcfg/get_domain',
    client_domain,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'timezone'
  config = qs.new(
    'string',
    'Timezone',
    'yes',
    'time/zone',
    values['timezone'].to_s,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'timeserver'
  config = qs.new(
    'string',
    'Timeserer',
    'yes',
    'clock-setup/ntp-server',
    values['timeserver'].to_s,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  if values['service'].to_s.match(/purity/)

    if install_ip1.match(/[0-9]/)

      name   = 'eth1_ip'
      config = qs.new(
        'string',
        'IP address for eth1',
        'yes',
        '',
        install_ip1,
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name = 'eth1_service'
      config = qs.new(
        'string',
        'Service for eth1',
        'yes',
        '',
        'management',
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

    if install_ip2.match(/[0-9]/)

      name   = 'eth2_ip'
      config = qs.new(
        'string',
        'IP address for eth2',
        'yes',
        '',
        install_ip2,
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = 'eth2_service'
      config = qs.new(
        'string',
        'Service for eth2',
        'yes',
        '',
        'replication',
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

    if install_ip3.match(/[0-9]/)

      name   = 'eth3_ip'
      config = qs.new(
        'string',
        'IP address for eth3',
        'yes',
        '',
        install_ip3,
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = 'eth3_service'
      config = qs.new(
        'string',
        'Service for eth3',
        'yes',
        '',
        'replication',
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

    if install_ip4.match(/[0-9]/)

      name   = 'eth4_ip'
      config = qs.new(
        'string',
        'IP address for eth4',
        'yes',
        '',
        install_ip4,
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = 'eth4_service'
      config = qs.new(
        'string',
        'Service for eth4',
        'yes',
        '',
        'iscsi',
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

    if install_ip5.match(/[0-9]/)

      name   = 'eth5_ip'
      config = qs.new(
        'string',
        'IP address for eth5',
        'yes',
        '',
        install_ip5,
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = 'eth5_service'
      config = qs.new(
        'string',
        'Service for eth5',
        'yes',
        '',
        'iscsi',
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

    end

    return values
  end

  unless values['method'].to_s.match(/ci/)

    name   = 'firmware'
    config = qs.new(
      'boolean',
      'Prompt for firmware',
      'no',
      'hw-detect/load_firmware',
      'false',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'clock'
    config = qs.new(
      'string',
      'Hardware clock set to UTC',
      'yes',
      'clock-setup/utc',
      'false',
      'false,true',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  #  name = "use_mirror"
  #  config = qs.new(
  #    type      = "boolean",
  #    question  = "Use Mirror",
  #    ask       = "no",
  #    parameter = "apt-setup/use_mirror",
  #    value     = values['usemirror'].to_s,
  #    valid     = "",
  #    eval      = "no"
  #    )
  #  values['answers'][name] = config
  #  values['order'].push(name)

  name   = 'mirror_country'
  config = qs.new(
    'string',
    'Mirror country',
    'no',
    'mirror/country',
    'manual',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'mirror_hostname'
  config = qs.new(
    'string',
    'Mirror hostname',
    'no',
    'mirror/http/hostname',
    # value     = mirror_hostname,
    values['mirror'].to_s,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'mirror_directory'
  config = qs.new(
    'string',
    'Mirror directory',
    'no',
    'mirror/http/directory',
    # value     = "/"+values['service'],
    values['mirrordir'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  # name = "mirror_url"
  # config = qs.new(
  #  type      = "string",
  #  question  = "Mirror URL",
  #  ask       = "no",
  #  parameter = "mirror/http/directory",
  #  #value     = "/"+values['service'],
  #  value     = values['mirrorurl'],
  #  valid     = "",
  #  eval      = "no"
  #  )
  # values['answers'][name] = config
  # values['order'].push(name)

  unless values['method'].to_s.match(/ci/)

    name   = 'mirror_proxy'
    config = qs.new(
      'string',
      'Mirror country',
      'no',
      'mirror/http/proxy',
      '',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'updates'
    config = qs.new(
      'select',
      'Update policy',
      'yes',
      'pkgsel/update-policy',
      'none',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  software = if values['software'].to_s.match(/[a-z]/)
               values['software']
             else
               'openssh-server'
             end

  name   = 'software'
  config = qs.new(
    'multiselect',
    'Software',
    'yes',
    'tasksel/first',
    software,
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  unless values['method'].to_s.match(/ci/)

    name   = 'additional_packages'
    config = qs.new(
      'string',
      'Additional packages',
      'yes',
      'pkgsel/include',
      pkg_list.join(' '),
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  name   = 'exit'
  config = qs.new(
    'boolean',
    'Exit installer',
    'yes',
    'debian-installer/exit/halt',
    'false',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'basicfilesystem_choose_label'
  config = qs.new(
    'string',
    'Basic Filesystem Chose Label',
    'no',
    'partman-basicfilesystems/choose_label',
    'gpt',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'basicfilesystem_default_label'
  config = qs.new(
    'string',
    'Basic Filesystem Default Label',
    'no',
    'partman-basicfilesystems/default_label',
    'gpt',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_choose_label'
  config = qs.new(
    'string',
    'Partition Chose Label',
    'no',
    'partman-partitioning/choose_label',
    'gpt',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_default_label'
  config = qs.new(
    'string',
    'Partition Default Label',
    'no',
    'partman-partitioning/default_label',
    'gpt',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'choose_label'
  config = qs.new(
    'string',
    'Partition Chose Label',
    'no',
    'partman/choose_label',
    'gpt',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'default_label'
  config = qs.new(
    'string',
    'Partition Default Label',
    'no',
    'partman/default_label',
    'gpt',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_disk'
  config = qs.new(
    'string',
    'Parition disk',
    'yes',
    'partman-auto/disk',
    values['rootdisk'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_method'
  config = qs.new(
    'string',
    'Parition method',
    'yes',
    'partman-auto/method',
    'lvm',
    'regular,lvm,crypto',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'remove_existing_lvm'
  config = qs.new(
    'boolean',
    'Remove existing LVM devices',
    'yes',
    'partman-lvm/device_remove_lvm',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'remove_existing_md'
  config = qs.new(
    'boolean',
    'Remove existing MD devices',
    'yes',
    'partman-md/device_remove_md',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_write'
  config = qs.new(
    'boolean',
    'Write parition',
    'yes',
    'partman-lvm/confirm',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_overwrite'
  config = qs.new(
    'boolean',
    'Overwrite existing parition',
    'yes',
    'partman-lvm/confirm_nooverwrite',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_size'
  config = qs.new(
    'string',
    'Partition size',
    'yes',
    'partman-auto-lvm/guided_size',
    'max',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'filesystem_type'
  config = qs.new(
    'string',
    'Write partition label',
    'yes',
    'partman/default_filesystem',
    'ext4',
    'ext3,ext4,xfs',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'volume_name'
  config = qs.new(
    'string',
    'Volume name',
    'yes',
    'partman-auto-lvm/new_vg_name',
    values['vgname'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name = 'filesystem_layout'
  if values['splitvols'] == true

    config = qs.new(
      'select',
      'Filesystem recipe',
      'yes',
      'partman-auto/choose_recipe',
      'boot-root',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'filesystem_recipe'
    config = qs.new(
      'string',
      'Filesystem layout',
      'yes',
      'partman-auto/expert_recipe',
      "\\\n" \
                  "boot-root :: \\\n" \
                  "#{values['bootsize']} 10 #{values['bootsize']} #{values['bootfs']} \\\n" \
                  "$primary{ } \\\n" \
                  "$bootable{ } \\\n" \
                  "$defaultignore{ } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['bootfs']} } \\\n" \
                  "mountpoint{ /boot } \\\n" \
                  ".\\\n" \
                  "#{values['swapsize']} 20 #{values['swapsize']} #{values['swapfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "format{ } \\\n" \
                  "lv_name{ swap } \\\n" \
                  "method{ swap } \\\n" \
                  ".\\\n" \
                  "#{values['rootsize']} 30 #{values['rootsize']} #{values['rootfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ root } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['rootfs']} } \\\n" \
                  "mountpoint{ / } \\\n" \
                  ".\\\n" \
                  "#{values['tmpsize']} 40 #{values['tmpsize']} #{values['tmpfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ tmp } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['tmpfs']} } \\\n" \
                  "mountpoint{ /tmp } \\\n" \
                  ".\\\n" \
                  "#{values['varsize']} 50 #{values['varsize']} #{values['varfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ var } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['varfs']} } \\\n" \
                  "mountpoint{ /var } \\\n" \
                  ".\\\n" \
                  "#{values['logsize']} 60 #{values['logsize']} #{values['logfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ log } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['logfs']} } \\\n" \
                  "mountpoint{ /var/log } \\\n" \
                  ".\\\n" \
                  "#{values['usrsize']} 70 #{values['usrsize']} #{values['usrfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ usr } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['usrfs']} } \\\n" \
                  "mountpoint{ /usr } \\\n" \
                  ".\\\n" \
                  "#{values['localsize']} 80 #{values['localsize']} #{values['localfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ local } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['localfs']} } \\\n" \
                  "mountpoint{ /usr/local } \\\n" \
                  ".\\\n" \
                  "#{values['homesize']} 90 #{values['homesize']} #{values['homefs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ home } \\\n" \
                  "method{ format } \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['homefs']} } \\\n" \
                  "mountpoint{ /home } \\\n" \
                  ".\\\n" \
                  "#{values['scratchsize']} 95 -1 #{values['scratchfs']} \\\n" \
                  "$defaultignore{ } \\\n" \
                  "$lvmok{ } \\\n" \
                  "in_vg { #{values['vgname']} } \\\n" \
                  "lv_name{ scratch } \\\n" \
                  "method{ format }  \\\n" \
                  "format{ } \\\n" \
                  "use_filesystem{ } \\\n" \
                  "filesystem{ #{values['scratchfs']} } \\\n" \
                  "mountpoint{ /scratch } \\\n" \
                  '.',
      '',
      'no'
    )

  else

    config = qs.new(
      'select',
      'Filesystem layout',
      'yes',
      'partman-auto/choose_recipe',
      'atomic',
      'string,atomic,home,multi',
      'no'
    )

  end
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_label'
  config = qs.new(
    'boolean',
    'Write partition label',
    'no',
    'partman-partitioning/confirm_write_new_label',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_finish'
  config = qs.new(
    'select',
    'Finish partition',
    'no',
    'partman/choose_partition',
    'finish',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_confirm'
  config = qs.new(
    'boolean',
    'Confirm partition',
    'no',
    'partman/confirm',
    'true',
    'true,faule',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'partition_nooverwrite'
  config = qs.new(
    'boolean',
    "Don't overwrite partition",
    'no',
    'partman/confirm_nooverwrite',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'kernel_image'
  config = qs.new(
    'string',
    'Kernel image',
    'yes',
    'base-installer/kernel/image',
    'linux-generic',
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'additional_packages'
  config = qs.new(
    'string',
    'Additional packages',
    'yes',
    'pkgsel/include',
    pkg_list.join(' '),
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_login'
  config = qs.new(
    'boolean',
    'Root login',
    'yes',
    'passwd/root-login',
    'false',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'make_user'
  config = qs.new(
    'boolean',
    'Create user',
    'yes',
    'passwd/make-user',
    'true',
    'true,false',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_password'
  config = qs.new(
    '',
    'Root password',
    'yes',
    '',
    values['rootpassword'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'root_crypt'
  config = qs.new(
    'password',
    'Root Password Crypt',
    'yes',
    'passwd/root-password-crypted',
    get_password_crypt(values['rootpassword']),
    '',
    'get_password_crypt(answer)'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'install_grub_mbr'
  config = qs.new(
    'boolean',
    'Install grub',
    'yes',
    'grub-installer/only_debian',
    'true',
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'install_grub_bootdev'
  config = qs.new(
    'string',
    'Install grub to device',
    'yes',
    'grub-installer/bootdev',
    values['rootdisk'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'reboot_note'
  config = qs.new(
    'note',
    'Install grub',
    'no',
    'finish-install/reboot_in_progress',
    '',
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  script_url = if values['type'].to_s.match(/packer/)
                 if values['vmnetwork'].to_s.match(/hostonly|bridged/)
                   if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10
                     "http://#{values['hostip']}:#{values['httpport']}/#{values['vm']}/#{values['name']}/#{values['name']}_post.sh"
                   else
                     "http://#{gateway}:#{values['httpport']}/#{values['vm']}/#{values['name']}/#{values['name']}_post.sh"
                   end
                 elsif values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10
                   "http://#{values['hostip']}:#{values['httpport']}/#{values['vm']}/#{values['name']}/#{values['name']}_post.sh"
                 else
                   "http://#{values['hostonlyip']}:#{values['httpport']}/#{values['vm']}/#{values['name']}/#{values['name']}_post.sh"
                 end
               elsif values['server'] == values['empty']
                 "http://#{values['hostip']}/#{values['name']}/#{values['name']}_post.sh"
               else
                 "http://#{values['server']}/#{values['name']}/#{values['name']}_post.sh"
               end

  #  if not values['type'].to_s.match(/packer/)

  name   = 'late_command'
  config = qs.new(
    'string',
    'Post install commands',
    'yes',
    'preseed/late_command',
    "in-target wget -O /tmp/post_install.sh #{script_url} ; in-target chmod 700 /tmp/post_install.sh ; in-target sh /tmp/post_install.sh",
    '',
    ''
  )
  values['answers'][name] = config
  values['order'].push(name)

  #  end

  values
end
