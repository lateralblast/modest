# MAAS serer related functions

# Configure MAAS server components

def configure_maas_server(options)
  maas_url = "http://"+options['hostip']+"/MAAS/"
  if options['host-os-uname'].match(/Ubuntu/)
    message = "Information:\tChecking installation status of MAAS"
    command = "dpkg -l maas"
    output  = execute_command(options, message, command)
    if output.match(/no packages found/)
      message = "Information:\tGetting Ubuntu release information"
      command = "lsb_release -c"
      output  = execute_command(options, message, command)
      if output.match(/precise/)
        message = "Information:\tEnabling APT Repository - Cloud Archive"
        command = "echo '' |add-apt-repository cloud-archive:tool"
        execute_command(options, message, command)
      end
      message = "Information:\tInstalling MAAS"
      command = "echo '' |apt-get install -y apt-get install maas dnsmasq debmirror"
      execute_command(options, message, command)
      service = "apache"
      restart_service(options, service)
      service = "avahi-daemon"
      restart_service(options, service)
      message = "Information:\tCreating MAAS Admin"
      command = "maas createadmin --username = #{options['maasadmin']} --email=#{options['maasemail']} --password=#{options['maaspassword']}"
      execute_command(options, message, command)
      handle_output(options, "") 
      handle_output(options, "Information:\tLog into #{maas_url} and continue configuration")
      handle_output(options, "") 
    end
  else
    handle_output(options, "Warning:\tMAAS is only supported on Ubuntu LTS")
    quit(options)
  end
  return
end
