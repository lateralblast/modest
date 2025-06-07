# frozen_string_literal: true

# Output Zone profile XML

def create_zone_profile_xml(output_file)
  xml_output = []
  xml = Builder::XmlMarkup.new(target: xml_output, indent: 2)
  xml.declare! :DOCTYPE, :service_bundle, :SYSTEM, '/usr/share/lib/xml/dtd/service_bundle.dtd.1'
  xml.service_bundle(type: 'profile', name: 'system configuration') do
    xml.service(version: '1', name: 'system/config-user', type: 'service') do
      xml.instance(enabled: 'true', name: 'default') do
        xml.property_group(name: 'root_account', type: 'application') do
          xml.propval(type: 'astring', value: values['answers']['root_crypt'].value, name: 'password')
          xml.propval(type: 'astring', value: values['answers']['root_type'].value, name: 'type')
          xml.propval(type: 'astring', value: values['answers']['root_expire'].value, name: 'expire')
        end
        xml.property_group(name: 'user_account', type: 'application') do
          xml.propval(type: 'astring', value: values['answers']['admin_username'].value, name: 'login')
          xml.propval(type: 'astring', value: values['answers']['admin_crypt'].value, name: 'password')
          xml.propval(type: 'astring', value: values['answers']['admin_description'].value,
                      name: 'description')
          xml.propval(type: 'astring', value: values['answers']['admin_shell'].value, name: 'shell')
          xml.propval(value: values['answers']['admin_uid'].value, name: 'uid')
          xml.propval(value: values['answers']['admin_gid'].value, name: 'gid')
          xml.propval(type: 'astring', value: values['answers']['admin_type'].value, name: 'type')
          xml.propval(type: 'astring', value: values['answers']['admin_roles'].value, name: 'roles')
          xml.propval(type: 'astring', value: values['answers']['admin_profiles'].value, name: 'profiles')
          xml.propval(type: 'astring', value: values['answers']['admin_sudoers'].value, name: 'sudoers')
          xml.propval(type: 'astring', value: values['answers']['admin_expire'].value, name: 'expire')
        end
      end
    end
    xml.service(name: 'system/timezone', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'timezone') do
          xml.propval(name: 'localtime', value: values['answers']['system_timezone'].value)
        end
      end
    end
    xml.service(name: 'system/environment', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'environment') do
          xml.propval(name: 'LC_ALL', value: values['answers']['system_environment'].value)
        end
      end
    end
    xml.service(name: 'system/identity', version: '1', type: 'service') do
      xml.instance(name: 'node', enabled: 'true') do
        xml.property_group(name: 'config') do
          xml.propval(name: 'nodename', value: values['answers']['system_identity'].value)
        end
      end
    end
    xml.service(name: 'system/keymap', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'keymap') do
          xml.propval(name: 'layout', value: values['answers']['system_keymap'].value)
        end
      end
    end
    xml.service(name: 'system/console-login', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'ttymon') do
          xml.propval(name: 'terminal_type', value: values['answers']['system_console'].value)
        end
      end
    end
    xml.service(name: 'network/physical', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'netcfg', type: 'application') do
          xml.propval(name: 'active_ncp', type: 'astring', value: 'DefaultFixed')
        end
      end
    end
    xml.service(name: 'network/install', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: "values['ip']v4_interface", type: 'application') do
          xml.propval(type: 'astring', name: 'name', value: values['answers']['ipv4_interface_name'].value)
          xml.propval(type: 'astring', name: 'address_type', value: 'static')
          xml.propval(type: 'net_address_v4', name: 'static_address',
                      value: values['answers']['ipv4_static_address'].value)
          xml.propval(type: 'net_address_v4', name: 'default_route',
                      value: values['answers']['ipv4_default_route'].value)
        end
        xml.property_group(name: "values['ip']v6_interface", type: 'application') do
          xml.propval(type: 'astring', name: 'name', value: values['answers']['ipv6_interface_name'].value)
          xml.propval(type: 'astring', name: 'address_type', value: 'addrconf')
          xml.propval(type: 'astring', name: 'stateless', value: 'yes')
          xml.propval(type: 'astring', name: 'stateful', value: 'yes')
        end
      end
    end
    xml.service(name: 'network/dns/client', version: '1', type: 'service') do
      xml.property_group(name: 'config', type: 'application') do
        xml.property(name: 'nameserver') do
          xml.net_address_list do
            xml.value_node(value: values['answers']['dns_nameserver'].value)
          end
        end
        xml.property(name: 'search') do
          xml.astring_list do
            xml.value_node(value: values['answers']['dns_search'].value)
          end
        end
      end
      xml.instance(name: 'default', enabled: 'true')
    end
    xml.service(name: 'system/name-service/switch', version: '1', type: 'service') do
      xml.property_group(name: 'config', type: 'application') do
        xml.propval(name: 'default', value: values['answers']['dns_files'].value)
        xml.propval(name: 'host', value: values['answers']['dns_hosts'].value)
      end
      xml.instance(name: 'default', enabled: 'true')
    end
    xml.service(name: 'system/ocm', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'reg', type: 'application') do
          xml.propval(type: 'astring', name: 'user', value: 'anonymous@oracle.com')
          xml.propval(type: 'astring', name: 'password', value: '')
          xml.propval(type: 'astring', name: 'key', value: '')
          xml.propval(type: 'astring', name: 'cipher', value: '')
          xml.propval(type: 'astring', name: 'proxy_host', value: '')
          xml.propval(type: 'astring', name: 'proxy_user', value: '')
          xml.propval(type: 'astring', name: 'proxy_password', value: '')
          xml.propval(type: 'astring', name: 'config_hub', value: '')
        end
      end
    end
    xml.service(name: 'system/fm/asr-notify', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'autoreg', type: 'application') do
          xml.propval(type: 'astring', name: 'user', value: 'anonymous@oracle.com')
          xml.propval(type: 'astring', name: 'password', value: '')
          xml.propval(type: 'astring', name: 'private-key', value: '')
          xml.propval(type: 'astring', name: 'public-key', value: '')
          xml.propval(type: 'astring', name: 'client-id', value: '')
          xml.propval(type: 'astring', name: 'timestamp', value: '')
          xml.propval(type: 'astring', name: 'proxy-host', value: '')
          xml.propval(type: 'astring', name: 'proxy-user', value: '')
          xml.propval(type: 'astring', name: 'proxy-password', value: '')
          xml.propval(type: 'astring', name: 'hub-endpoint', value: '')
        end
      end
    end
  end
  file = File.open(output_file, 'w')
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Checking:\tClient profile #{output_file}"
  command = "xmllint #{output_file}"
  execute_command(values, message, command)
  nil
end

# Output AI profile XML

def create_ai_client_profile(values, output_file)
  xml_output = []
  xml = Builder::XmlMarkup.new(target: xml_output, indent: 2)
  xml.declare! :DOCTYPE, :service_bundle, :SYSTEM, '/usr/share/lib/xml/dtd/service_bundle.dtd.1'
  xml.service_bundle(type: 'profile', name: 'system configuration') do
    xml.service(version: '1', name: 'system/config-user') do
      xml.instance(enabled: 'true', name: 'default') do
        xml.property_group(name: 'root_account') do
          xml.propval(type: 'astring', value: values['answers']['root_crypt'].value, name: 'password')
          xml.propval(type: 'astring', value: values['answers']['root_type'].value, name: 'type')
          xml.propval(type: 'astring', value: values['answers']['root_expire'].value, name: 'expire')
        end
        xml.property_group(name: 'user_account') do
          xml.propval(type: 'astring', value: values['answers']['admin_username'].value, name: 'login')
          xml.propval(type: 'astring', value: values['answers']['admin_crypt'].value, name: 'password')
          xml.propval(type: 'astring', value: values['answers']['admin_description'].value,
                      name: 'description')
          xml.propval(type: 'astring', value: values['answers']['admin_shell'].value, name: 'shell')
          xml.propval(value: values['answers']['admin_uid'].value, name: 'uid')
          xml.propval(value: values['answers']['admin_gid'].value, name: 'gid')
          xml.propval(type: 'astring', value: values['answers']['admin_type'].value, name: 'type')
          xml.propval(type: 'astring', value: values['answers']['admin_roles'].value, name: 'roles')
          xml.propval(type: 'astring', value: values['answers']['admin_profiles'].value, name: 'profiles')
          xml.propval(type: 'astring', value: values['answers']['admin_sudoers'].value, name: 'sudoers')
          xml.propval(type: 'astring', value: values['answers']['admin_expire'].value, name: 'expire')
          # xml.propval(:type => "astring", :value => values['answers']['admin_home_zfs_dataset'].value, :name => "home_zfs_dataset")
          # xml.propval(:type => "astring", :value => values['answers']['admin_home_mountpoint'].value, :name => "home_mountpoint")
        end
      end
    end
    xml.service(name: 'system/identity', version: '1') do
      xml.instance(name: 'node', enabled: 'true') do
        xml.property_group(name: 'config') do
          xml.propval(name: 'nodename', value: values['answers']['system_identity'].value)
        end
      end
    end
    xml.service(name: 'system/console-login', version: '1') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'ttymon') do
          xml.propval(name: 'terminal_type', value: values['answers']['system_console'].value)
        end
      end
    end
    xml.service(name: 'system/keymap', version: '1') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'keymap') do
          xml.propval(name: 'layout', value: values['answers']['system_keymap'].value)
        end
      end
    end
    xml.service(name: 'system/timezone', version: '1') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'timezone') do
          xml.propval(name: 'localtime', value: values['answers']['system_timezone'].value)
        end
      end
    end
    xml.service(name: 'system/environment', version: '1') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'environment') do
          xml.propval(name: 'LC_ALL', value: values['answers']['system_environment'].value)
        end
      end
    end
    xml.service(name: 'network/physical', version: '1') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'netcfg', type: 'application') do
          xml.propval(name: 'active_ncp', type: 'astring', value: 'DefaultFixed')
        end
      end
    end
    xml.service(name: 'network/install', version: '1', type: 'service') do
      xml.instance(name: 'default', enabled: 'true') do
        xml.property_group(name: 'install_ipv4_interface', type: 'application') do
          xml.propval(type: 'astring', name: 'name', value: values['answers']['ipv4_interface_name'].value)
          xml.propval(type: 'astring', name: 'address_type', value: 'static')
          xml.propval(type: 'net_address_v4', name: 'static_address',
                      value: values['answers']['ipv4_static_address'].value)
          xml.propval(type: 'net_address_v4', name: 'default_route',
                      value: values['answers']['ipv4_default_route'].value)
        end
        xml.property_group(name: 'install_ipv6_interface', type: 'application') do
          xml.propval(type: 'astring', name: 'name', value: values['answers']['ipv6_interface_name'].value)
          xml.propval(type: 'astring', name: 'address_type', value: 'addrconf')
          xml.propval(type: 'astring', name: 'stateless', value: 'yes')
          xml.propval(type: 'astring', name: 'stateful', value: 'yes')
        end
      end
    end
    xml.service(name: 'network/dns/client', version: '1') do
      xml.property_group(name: 'config') do
        xml.property(name: 'nameserver') do
          xml.net_address_list do
            xml.value_node(value: values['answers']['dns_nameserver'].value)
          end
        end
        xml.property(name: 'search') do
          xml.astring_list do
            xml.value_node(value: values['answers']['dns_search'].value)
          end
        end
      end
      xml.instance(name: 'default', enabled: 'true')
    end
    xml.service(name: 'system/name-service/switch', version: '1') do
      xml.property_group(name: 'config') do
        xml.propval(name: 'default', value: values['answers']['dns_files'].value)
        xml.propval(name: 'host', value: values['answers']['dns_hosts'].value)
      end
      xml.instance(name: 'default', enabled: 'true')
    end
  end
  file = File.open(output_file, 'w')
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Checking:\tClient profile #{output_file}"
  command = "xmllint #{output_file}"
  execute_command(values, message, command)
  nil
end

# Output AI manifest XML

def create_ai_manifest(values, output_file)
  xml_output = []
  xml = Builder::XmlMarkup.new(target: xml_output, indent: 2)
  xml.declare! :DOCTYPE, :auto_install, :SYSTEM, 'file:///usr/share/install/ai.dtd.1'
  if values['answers']['rootdisk'].match(/c[0-9]/)
    if values['answers']['mirrordisk'].match(/c[0-9]/)
      xml.auto_install do
        xml.ai_instance(auto_reboot: 'true', name: 'orig_default') do
          xml.target do
            xml.disk(in_vdev: 'mirror_vdev', in_zpool: values['rpoolname'].value, whole_disk: 'true') do
              xml.disk_name(name: values['answers']['rootdisk'].value, name_type: 'ctd')
            end
            xml.disk(in_vdev: 'mirror_vdev', in_zpool: values['rpoolname'].value, whole_disk: 'true') do
              xml.disk_name(name: values['answers']['mirrordisk'].value, name_type: 'ctd')
            end
            xml.logical do
              xml.zpool(is_root: 'true', name: values['rpoolname'].value) do
                xml.filesystem(mountpoint: '/export', name: 'export')
                xml.filesystem(name: 'export/home')
                xml.be(name: 'solaris')
              end
            end
          end
          xml.software(type: 'IPS') do
            xml.destination do
              xml.image do
                xml.facet('facet.local.*', set: 'false')
                xml.facet('facet.local.en', set: 'true')
                xml.facet('facet.local.en_US', set: 'true')
              end
            end
            xml.source do
              xml.publisher(name: 'solaris') do
                xml.origin(name: values['answers']['ai_publisherurl'].value)
              end
            end
            xml.software_data(action: 'install') do
              xml.name(values['answers']['repo_url'].value)
              xml.name(values['answers']['server_install'].value)
              xml.name('pkg:/runtime/ruby-18')
            end
          end
        end
      end
    else
      xml.auto_install do
        xml.ai_instance(auto_reboot: 'true', name: 'orig_default') do
          xml.target do
            xml.disk(in_zpool: values['rpoolname'].value, whole_disk: 'true') do
              xml.disk_name(name: values['answers']['rootdisk'].value, name_type: 'ctd')
            end
            xml.logical do
              xml.zpool(is_root: 'true', name: values['rpoolname'].value) do
                xml.filesystem(mountpoint: '/export', name: 'export')
                xml.filesystem(name: 'export/home')
                xml.be(name: values['answers']['bename'].value)
              end
            end
          end
          xml.software(type: 'IPS') do
            xml.destination do
              xml.image do
                xml.facet('facet.local.*', set: 'false')
                xml.facet('facet.local.en', set: 'true')
                xml.facet('facet.local.en_US', set: 'true')
              end
            end
            xml.source do
              xml.publisher(name: 'solaris') do
                xml.origin(name: values['answers']['ai_publisherurl'].value)
              end
            end
            xml.software_data(action: 'install') do
              xml.name(values['answers']['repo_url'].value)
              xml.name(values['answers']['server_install'].value)
              xml.name('pkg:/runtime/ruby-18')
            end
          end
        end
      end
    end
  else
    xml.auto_install do
      xml.ai_instance(auto_reboot: 'true', name: 'orig_default') do
        xml.target do
          xml.logical do
            xml.zpool(is_root: 'true', name: values['answers']['rpoolname'].value) do
              xml.filesystem(mountpoint: '/export', name: 'export')
              xml.filesystem(name: 'export/home')
              xml.be(name: 'solaris')
            end
          end
        end
        xml.software(type: 'IPS') do
          xml.destination do
            xml.image do
              xml.facet('facet.local.*', set: 'false')
              xml.facet('facet.local.en', set: 'true')
              xml.facet('facet.local.en_US', set: 'true')
            end
          end
          xml.source do
            xml.publisher(name: 'solaris') do
              xml.origin(name: values['answers']['ai_publisherurl'].value)
            end
          end
          xml.software_data(action: 'install') do
            xml.name(values['answers']['repo_url'].value)
            xml.name(values['answers']['server_install'].value)
            xml.name('pkg:/runtime/ruby-18')
          end
        end
      end
    end
  end
  file = File.open(output_file, 'w')
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Information:\tChecking service profile #{output_file}"
  command = "xmllint #{output_file}"
  execute_command(values, message, command)
  nil
end
