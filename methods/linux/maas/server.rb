# frozen_string_literal: true

# MAAS serer related functions

# Configure MAAS server components

def configure_maas_server(values)
  maas_url = "http://#{values['hostip']}/MAAS/"
  if values['host-os-unamea'].match(/Ubuntu/)
    message = "Information:\tChecking installation status of MAAS"
    command = 'dpkg -l maas'
    output  = execute_command(values, message, command)
    if output.match(/no packages found/)
      message = "Information:\tGetting Ubuntu release information"
      command = 'lsb_release -c'
      output  = execute_command(values, message, command)
      if output.match(/precise/)
        message = "Information:\tEnabling APT Repository - Cloud Archive"
        command = "echo '' |add-apt-repository cloud-archive:tool"
        execute_command(values, message, command)
      end
      message = "Information:\tInstalling MAAS"
      command = "echo '' |apt-get install -y apt-get install maas dnsmasq debmirror"
      execute_command(values, message, command)
      service = 'apache'
      restart_service(values, service)
      service = 'avahi-daemon'
      restart_service(values, service)
      message = "Information:\tCreating MAAS Admin"
      command = "maas createadmin --username = #{values['maasadmin']} --email=#{values['maasemail']} --password=#{values['maaspassword']}"
      execute_command(values, message, command)
      verbose_message(values, '')
      information_message(values, "Log into #{maas_url} and continue configuration")
      verbose_message(values, '')
    end
  else
    warning_message(values, 'MAAS is only supported on Ubuntu LTS')
    quit(values)
  end
  nil
end
