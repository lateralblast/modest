# Server related code for Linux related code

# List availabel images

def list_lxc_services(values)
  if values['host-os-uname'].to_s.match(/Linux/) && Dir.exist?(values['lxcimagedir'])
    image_list = Dir.entries(values['lxcimagedir'])
    if image_list.length > 0
      if values['output'].to_s.match(/html/)
        verbose_message(values, "<h1>Available LXC service(s)</h1>")
        verbose_message(values, "<table border=\"1\">")
        verbose_message(values, "<tr>")
        verbose_message(values, "<th>Distribution</th>")
        verbose_message(values, "<th>Version</th>")
        verbose_message(values, "<th>Architecture</th>")
        verbose_message(values, "<th>Image File</th>")
        verbose_message(values, "<th>Service</th>")
        verbose_message(values, "</tr>")
      else
        verbose_message(values, "") 
        verbose_message(values, "Available LXC Images:")
        verbose_message(values, "") 
      end
      image_list.each do |image_name|
        if image_name.match(/tar/)
          values['image']   = $lxc_image_dir+"/"+image_name
          image_info = File.basename(image_name, ".tar.gz")
          image_info = image_info.split(/-/)
          image_os   = image_info[0]
          image_ver  = image_info[1]
          image_arch = image_info[2]
          if values['output'].to_s.match(/html/)
            verbose_message(values, "<tr>")
            verbose_message(values, "<td>#{image_os.capitalize}</td>")
            verbose_message(values, "<td>#{image_ver}</td>")
            verbose_message(values, "<td><#{image_arch}/td>")
            verbose_message(values, "<td>#{values['image']}</td>")
          else
            verbose_message(values, "Distribution:\t#{image_os.capitalize}")
            verbose_message(values, "Version:\t#{image_ver}")
            verbose_message(values, "Architecture:\t#{image_arch}")
            verbose_message(values, "Image File:\t#{values['image']}")
          end
          if image_info[3]
            values['service'] = image_os.gsub(/ /, "")+"_"+image_ver.gsub(/\./, "_")+"_"+image_arch+"_"+image_info[3]
          else
            values['service'] = image_os.gsub(/ /, "")+"_"+image_ver.gsub(/\./, "_")+"_"+image_arch
          end
          if values['output'].to_s.match(/html/)
            verbose_message(values, "<td><#{values['service']}</td>")
            verbose_message(values, "</tr>")
          else
            verbose_message(values, "Service Name:\t#{values['service']}")
            verbose_message(values, "")
          end
        end
      end
    end
    if values['output'].to_s.match(/html/)
      verbose_message(values, "</table>")
    end
  end
  return
end

# Configure Ubunut LXC server

def configure_ubuntu_lxc_server(values, server_type)
  config_file  = "/etc/network/interfaces"
  if server_type.match(/public/)
    message = "Checking:\tLXC network configuration"
    command = "cat #{config_file} |grep 'bridge_ports eth0'"
    output  = execute_command(values, message, command)
    if not output.match(/bridge_ports/)
      tmp_file   = "/tmp/interfaces"
      server_ip  = values['hostip']
      gateway    = values['answers']['gateway'].value
      broadcast  = values['answers']['broadcast'].value
      network    = values['answers']['network_address'].value
      nameserver = values['answers']['nameserver'].value
      file = File.open(tmp_file, "w")
      file.write("# The loopback network interface\n")
      file.write("auto lo\n")
      file.write("iface lo inet loopback\n")
      file.write("\n")
      file.write("# The primary network interface\n")
      file.write("auto eth0\n")
      file.write("iface eth0 inet manual\n")
      file.write("\n")
      file.write("# LXC network\n")
      file.write("auto lxcbr0\n")
      file.write("iface lxcbr0 inet static\n")
      file.write("bridge_ports eth0\n")
      file.write("bridge_fd 0\n")
      file.write("bridge_stp off\n")
      file.write("bridge_waitport 0\n")
      file.write("bridge_maxwait 0\n")
      file.write("address #{server_ip}\n")
      file.write("gateway #{gateway}\n")
      file.write("netmask #{netmask}\n")
      file.write("network #{network}\n")
      file.write("broadcast #{broadcast}\n")
      file.write("dns-nameservers #{nameserver}\n")
      file.write("\n")
      file.close
      backup_file = config_file+".nolxc"
      message = "Information:\tArchiving network configuration file "+config_file+" to "+backup_file
      command = "cp #{config_file} #{backup_file}"
      execute_command(values, message, command)
      message = "Information:\tCreating network configuration file "+config_file
      command = "cp #{tmp_file} #{config_file} ; rm #{tmp_file}"
      execute_command(values, message, command)
      service = "networking"
      restart_service(values, service)
    end
  end
  return
end

# Configure LXC Server

def configure_lxc_server(values, server_type)
  values['service'] = ""
  values = populate_lxc_server_questions(values)
  process_questions(values)
  if values['host-os-unamea'].match(/Ubuntu/)
    configure_ubuntu_lxc_server(values, server_type)
  end
  check_lxc_install(values)
  return
end
