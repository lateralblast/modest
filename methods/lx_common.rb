# Code to manage Linux containers

# Check LXC install

def check_lxc_is_installed(options)
  message = "Information:\tChecking LXC Packages are installed"
  if options['host-os-unamea'].match(/Ubuntu/)
    command = "dpkg -l lxc"
    output  = execute_command(options, message, command)
    if output.match(/no packages/)
      message = "Information:\tInstalling LXC Packages"
      command = "apt-get -y install lxc cloud-utils"
      execute_command(options, message, command)
    end
  else
    command = "rpm -ql libvirt"
    output  = execute_command(options, message, command)
    if output.match(/not installed/)
      message = "Information:\tInstalling LXC Packages"
      command = "yum -y install libvirt libvirt-client python-virtinst"
      execute_command(options, message, command)
    end
  end
  check_dir_exists(options, options['lxcdir'])
  return
end

# List LXC images - Needs code

def list_lxc_isos()
  return
end