
# Output Zone profile XML

def create_zone_profile_xml(output_file)
  xml_output = []
  xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
  xml.declare! :DOCTYPE, :service_bundle, :SYSTEM, "/usr/share/lib/xml/dtd/service_bundle.dtd.1"
  xml.service_bundle(:type => "profile", :name => "system configuration") {
    xml.service(:version => "1", :name => "system/config-user", :type => "service") {
      xml.instance(:enabled => "true", :name => "default") {
        xml.property_group(:name => "root_account", :type => "application") {
          xml.propval(:type => "astring", :value => options['q_struct']['root_crypt'].value, :name => "password")
          xml.propval(:type => "astring", :value => options['q_struct']['root_type'].value, :name => "type")
          xml.propval(:type => "astring", :value => options['q_struct']['root_expire'].value, :name => "expire")
        }
        xml.property_group(:name => "user_account", :type => "application") {
          xml.propval(:type => "astring", :value => options['q_struct']['admin_username'].value, :name => "login")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_crypt'].value, :name => "password")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_description'].value, :name => "description")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_shell'].value, :name => "shell")
          xml.propval(:value => options['q_struct']['admin_uid'].value, :name => "uid")
          xml.propval(:value => options['q_struct']['admin_gid'].value, :name => "gid")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_type'].value, :name => "type")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_roles'].value, :name => "roles")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_profiles'].value, :name => "profiles")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_sudoers'].value, :name => "sudoers")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_expire'].value, :name => "expire")
        }
      }
    }
    xml.service(:name => "system/timezone", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "timezone") {
          xml.propval(:name => "localtime", :value => options['q_struct']['system_timezone'].value)
        }
      }
    }
    xml.service(:name => "system/environment", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "environment") {
          xml.propval(:name => "LC_ALL", :value => options['q_struct']['system_environment'].value)
        }
      }
    }
    xml.service(:name => "system/identity", :version => "1", :type => "service") {
      xml.instance(:name => "node", :enabled => "true") {
        xml.property_group(:name => "config") {
          xml.propval(:name => "nodename", :value => options['q_struct']['system_identity'].value)
        }
      }
    }
    xml.service(:name => "system/keymap", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "keymap") {
          xml.propval(:name => "layout", :value => options['q_struct']['system_keymap'].value)
        }
      }
    }
    xml.service(:name => "system/console-login", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "ttymon") {
          xml.propval(:name => "terminal_type", :value => options['q_struct']['system_console'].value)
        }
      }
    }
    xml.service(:name => "network/physical", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "netcfg", :type => "application") {
          xml.propval(:name => "active_ncp", :type => "astring", :value => "DefaultFixed")
        }
      }
    }
    xml.service(:name => "network/install", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "options['ip']v4_interface", :type => "application") {
          xml.propval(:type => "astring", :name => "name", :value => options['q_struct']['ipv4_interface_name'].value)
          xml.propval(:type => "astring", :name => "address_type", :value => "static")
          xml.propval(:type => "net_address_v4", :name => "static_address", :value => options['q_struct']['ipv4_static_address'].value)
          xml.propval(:type => "net_address_v4", :name => "default_route", :value => options['q_struct']['ipv4_default_route'].value)
        }
        xml.property_group(:name => "options['ip']v6_interface", :type => "application") {
          xml.propval(:type => "astring", :name => "name", :value => options['q_struct']['ipv6_interface_name'].value)
          xml.propval(:type => "astring", :name => "address_type", :value => "addrconf")
          xml.propval(:type => "astring", :name => "stateless", :value => "yes")
          xml.propval(:type => "astring", :name => "stateful", :value => "yes")
        }
      }
    }
    xml.service(:name => "network/dns/client", :version => "1", :type => "service") {
      xml.property_group(:name => "config", :type => "application") {
        xml.property(:name => "nameserver") {
          xml.net_address_list {
            xml.value_node(:value => options['q_struct']['dns_nameserver'].value)
          }
        }
        xml.property(:name => "search") {
          xml.astring_list {
            xml.value_node(:value => options['q_struct']['dns_search'].value)
          }
        }
      }
      xml.instance(:name => "default", :enabled => "true")
    }
    xml.service(:name => "system/name-service/switch", :version => "1", :type => "service") {
      xml.property_group(:name => "config", :type => "application") {
        xml.propval(:name => "default", :value => options['q_struct']['dns_files'].value)
        xml.propval(:name => "host", :value => options['q_struct']['dns_hosts'].value)
      }
      xml.instance(:name => "default", :enabled => "true")
    }
    xml.service(:name => "system/ocm", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "reg", :type => "application") {
          xml.propval(:type => "astring", :name => "user", :value => "anonymous@oracle.com")
          xml.propval(:type => "astring", :name => "password", :value => "")
          xml.propval(:type => "astring", :name => "key", :value => "")
          xml.propval(:type => "astring", :name => "cipher", :value => "")
          xml.propval(:type => "astring", :name => "proxy_host", :value => "")
          xml.propval(:type => "astring", :name => "proxy_user", :value => "")
          xml.propval(:type => "astring", :name => "proxy_password", :value => "")
          xml.propval(:type => "astring", :name => "config_hub", :value => "")
        }
      }
    }
    xml.service(:name => "system/fm/asr-notify", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "autoreg", :type => "application") {
          xml.propval(:type => "astring", :name => "user", :value => "anonymous@oracle.com")
          xml.propval(:type => "astring", :name => "password", :value => "")
          xml.propval(:type => "astring", :name => "private-key", :value => "")
          xml.propval(:type => "astring", :name => "public-key", :value => "")
          xml.propval(:type => "astring", :name => "client-id", :value => "")
          xml.propval(:type => "astring", :name => "timestamp", :value => "")
          xml.propval(:type => "astring", :name => "proxy-host", :value => "")
          xml.propval(:type => "astring", :name => "proxy-user", :value => "")
          xml.propval(:type => "astring", :name => "proxy-password", :value => "")
          xml.propval(:type => "astring", :name => "hub-endpoint", :value => "")
        }
      }
    }
  }
  file = File.open(output_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Checking:\tClient profile "+output_file
  command = "xmllint #{output_file}"
  execute_command(options,message,command)
  return
end

# Output AI profile XML

def create_ai_client_profile(options,output_file)
  xml_output = []
  xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
  xml.declare! :DOCTYPE, :service_bundle, :SYSTEM, "/usr/share/lib/xml/dtd/service_bundle.dtd.1"
  xml.service_bundle(:type => "profile", :name => "system configuration") {
    xml.service(:version => "1", :name => "system/config-user") {
      xml.instance(:enabled => "true", :name => "default") {
        xml.property_group(:name => "root_account") {
          xml.propval(:type => "astring", :value => options['q_struct']['root_crypt'].value, :name => "password")
          xml.propval(:type => "astring", :value => options['q_struct']['root_type'].value, :name => "type")
          xml.propval(:type => "astring", :value => options['q_struct']['root_expire'].value, :name => "expire")
        }
        xml.property_group(:name => "user_account") {
          xml.propval(:type => "astring", :value => options['q_struct']['admin_username'].value, :name => "login")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_crypt'].value, :name => "password")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_description'].value, :name => "description")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_shell'].value, :name => "shell")
          xml.propval(:value => options['q_struct']['admin_uid'].value, :name => "uid")
          xml.propval(:value => options['q_struct']['admin_gid'].value, :name => "gid")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_type'].value, :name => "type")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_roles'].value, :name => "roles")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_profiles'].value, :name => "profiles")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_sudoers'].value, :name => "sudoers")
          xml.propval(:type => "astring", :value => options['q_struct']['admin_expire'].value, :name => "expire")
          #xml.propval(:type => "astring", :value => options['q_struct']['admin_home_zfs_dataset'].value, :name => "home_zfs_dataset")
          #xml.propval(:type => "astring", :value => options['q_struct']['admin_home_mountpoint'].value, :name => "home_mountpoint")
        }
      }
    }
    xml.service(:name => "system/identity", :version => "1") {
      xml.instance(:name => "node", :enabled => "true") {
        xml.property_group(:name => "config") {
          xml.propval(:name => "nodename", :value => options['q_struct']['system_identity'].value)
        }
      }
    }
    xml.service(:name => "system/console-login", :version => "1") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "ttymon") {
          xml.propval(:name => "terminal_type", :value => options['q_struct']['system_console'].value)
        }
      }
    }
    xml.service(:name => "system/keymap", :version => "1") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "keymap") {
          xml.propval(:name => "layout", :value => options['q_struct']['system_keymap'].value)
        }
      }
    }
    xml.service(:name => "system/timezone", :version => "1") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "timezone") {
          xml.propval(:name => "localtime", :value => options['q_struct']['system_timezone'].value)
        }
      }
    }
    xml.service(:name => "system/environment", :version => "1") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "environment") {
          xml.propval(:name => "LC_ALL", :value => options['q_struct']['system_environment'].value)
        }
      }
    }
    xml.service(:name => "network/physical", :version => "1") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "netcfg", :type => "application") {
          xml.propval(:name => "active_ncp", :type => "astring", :value => "DefaultFixed")
        }
      }
    }
    xml.service(:name => "network/install", :version => "1", :type => "service") {
      xml.instance(:name => "default", :enabled => "true") {
        xml.property_group(:name => "install_ipv4_interface", :type => "application") {
          xml.propval(:type => "astring", :name => "name", :value => options['q_struct']['ipv4_interface_name'].value)
          xml.propval(:type => "astring", :name => "address_type", :value => "static")
          xml.propval(:type => "net_address_v4", :name => "static_address", :value => options['q_struct']['ipv4_static_address'].value)
          xml.propval(:type => "net_address_v4", :name => "default_route", :value => options['q_struct']['ipv4_default_route'].value)
        }
        xml.property_group(:name => "install_ipv6_interface", :type => "application") {
          xml.propval(:type => "astring", :name => "name", :value => options['q_struct']['ipv6_interface_name'].value)
          xml.propval(:type => "astring", :name => "address_type", :value => "addrconf")
          xml.propval(:type => "astring", :name => "stateless", :value => "yes")
          xml.propval(:type => "astring", :name => "stateful", :value => "yes")
        }
      }
    }
    xml.service(:name => "network/dns/client", :version => "1") {
      xml.property_group(:name => "config") {
        xml.property(:name => "nameserver") {
          xml.net_address_list {
            xml.value_node(:value => options['q_struct']['dns_nameserver'].value)
          }
        }
        xml.property(:name => "search") {
          xml.astring_list {
            xml.value_node(:value => options['q_struct']['dns_search'].value)
          }
        }
      }
      xml.instance(:name => "default", :enabled => "true")
    }
    xml.service(:name => "system/name-service/switch", :version => "1") {
      xml.property_group(:name => "config") {
        xml.propval(:name => "default", :value => options['q_struct']['dns_files'].value)
        xml.propval(:name => "host", :value => options['q_struct']['dns_hosts'].value)
      }
      xml.instance(:name => "default", :enabled => "true")
    }
  }
  file = File.open(output_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Checking:\tClient profile "+output_file
  command = "xmllint #{output_file}"
  execute_command(options,message,command)
  return
end

# Output AI manifest XML

def create_ai_manifest(options,output_file)
  xml_output = []
  if options['q_struct']['rootdisk'].match(/c[0-9]/)
    if options['q_struct']['mirrordisk'].match(/c[0-9]/)
      xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
      xml.declare! :DOCTYPE, :auto_install, :SYSTEM, "file:///usr/share/install/ai.dtd.1"
      xml.auto_install {
        xml.ai_instance(:auto_reboot => "true", :name => "orig_default") {
          xml.target {
            xml.disk(:in_vdev => "mirror_vdev", :in_zpool => options['rpoolname'].value, :whole_disk => "true") {
              xml.disk_name(:name => options['q_struct']['rootdisk'].value, :name_type => "ctd")
            }
            xml.disk(:in_vdev => "mirror_vdev", :in_zpool => options['rpoolname'].value, :whole_disk => "true") {
              xml.disk_name(:name => options['q_struct']['mirrordisk'].value, :name_type => "ctd")
            }
            xml.logical {
              xml.zpool(:is_root => "true", :name => options['rpoolname'].value) {
                xml.filesystem(:mountpoint => "/export", :name => "export")
                xml.filesystem(:name => "export/home")
                xml.be(:name => "solaris")
              }
            }
          }
          xml.software(:type => "IPS") {
            xml.destination {
              xml.image {
                xml.facet("facet.local.*",:set => "false")
                xml.facet("facet.local.en",:set => "true")
                xml.facet("facet.local.en_US",:set => "true")
              }
            }
            xml.source {
              xml.publisher(:name => "solaris") {
                xml.origin(:name => options['q_struct']['ai_publisherurl'].value)
              }
            }
            xml.software_data(:action => "install") {
              xml.name(options['q_struct']['repo_url'].value)
              xml.name(options['q_struct']['server_install'].value)
              xml.name("pkg:/runtime/ruby-18")
            }
          }
        }
      }
    else
      xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
      xml.declare! :DOCTYPE, :auto_install, :SYSTEM, "file:///usr/share/install/ai.dtd.1"
      xml.auto_install {
        xml.ai_instance(:auto_reboot => "true", :name => "orig_default") {
          xml.target {
            xml.disk(:in_zpool => options['rpoolname'].value, :whole_disk => "true") {
              xml.disk_name(:name => options['q_struct']['rootdisk'].value, :name_type => "ctd")
            }
            xml.logical {
              xml.zpool(:is_root => "true", :name => options['rpoolname'].value) {
                xml.filesystem(:mountpoint => "/export", :name => "export")
                xml.filesystem(:name => "export/home")
                xml.be(:name => options['q_struct']['bename'].value)
              }
            }
          }
          xml.software(:type => "IPS") {
            xml.destination {
              xml.image {
                xml.facet("facet.local.*",:set => "false")
                xml.facet("facet.local.en",:set => "true")
                xml.facet("facet.local.en_US",:set => "true")
              }
            }
            xml.source {
              xml.publisher(:name => "solaris") {
                xml.origin(:name => options['q_struct']['ai_publisherurl'].value)
              }
            }
            xml.software_data(:action => "install") {
              xml.name(options['q_struct']['repo_url'].value)
              xml.name(options['q_struct']['server_install'].value)
              xml.name("pkg:/runtime/ruby-18")
            }
          }
        }
      }
    end
  else
    xml = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
    xml.declare! :DOCTYPE, :auto_install, :SYSTEM, "file:///usr/share/install/ai.dtd.1"
    xml.auto_install {
      xml.ai_instance(:auto_reboot => "true", :name => "orig_default") {
        xml.target {
          xml.logical {
            xml.zpool(:is_root => "true", :name => options['q_struct']["rpoolname"].value) {
              xml.filesystem(:mountpoint => "/export", :name => "export")
              xml.filesystem(:name => "export/home")
              xml.be(:name => "solaris")
            }
          }
        }
        xml.software(:type => "IPS") {
          xml.destination {
            xml.image {
              xml.facet("facet.local.*",:set => "false")
              xml.facet("facet.local.en",:set => "true")
              xml.facet("facet.local.en_US",:set => "true")
            }
          }
          xml.source {
            xml.publisher(:name => "solaris") {
              xml.origin(:name => options['q_struct']['ai_publisherurl'].value)
            }
          }
          xml.software_data(:action => "install") {
            xml.name(options['q_struct']['repo_url'].value)
            xml.name(options['q_struct']['server_install'].value)
            xml.name("pkg:/runtime/ruby-18")
          }
        }
      }
    }
  end
  file = File.open(output_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Information:\tChecking service profile "+output_file
  command = "xmllint #{output_file}"
  execute_command(options,message,command)
  return
end
