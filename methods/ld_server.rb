# Control Domain related code

# List CDom services

def list_cdom_services(options)
  if options['host-os-uname'].match(/SunOS/)
    if options['host-os-release'].match(/10|11/)
      if options['host-os-uname'].match(/sun4v/)
        ldom_type    = "Control Domain"
        ldom_command = "ldm list |grep ^primary |awk '{print $1}'"
        list_doms(ldom_type,ldom_command)
      else
        if options['verbose'] == true
          handle_output(options,"") 
          handle_output(options,"Warning:\tThis service is only available on the Sun4v platform")
          handle_output(options,"") 
        end
      end
    else
      if options['verbose'] == true
        handle_output(options,"") 
        handle_output(options,"Warning:\tThis service is only available on Solaris 10 or later")
        handle_output(options,"") 
      end
    end
  else
    if options['verbose'] == true
      handle_output(options,"") 
      handle_output(options,"Warning:\tThis service is only available on Solaris")
      handle_output(options,"") 
    end
  end
  return
end

def list_ldom_services(options)
  list_cdom_services(options)
  return
end

def list_gdom_services(options)
  list_cdom_services(options)
  return
end

# Check LDoms installed

def check_cdom_install(options)
  ldm_bin = "/usr/sbin/ldm"
  if not File.exist?(ldm_bin)
    if options['host-os-release'].match(/11/)
      message = "Information:\tInstalling LDoms software"
      command = "pkg install ldomsmanager"
      execute_command(options,message,command)
    end
  end
  smf_service = "ldmd"
  enable_smf_service(smf_service)
  return
end

# Check LDom VCC

def check_cdom_vcc()
  message = "Information:\tChecking LDom VCC"
  command = "ldm list-services |grep 'primary-vcc'"
  output  = execute_command(options,message,command)
  if not output.match(/vcc/)
    message = "Information:\tEnabling VCC"
    command = "ldm add-vcc port-range=5000-5100 primary-vcc0 primary"
    execute_command(options,message,command)
  end
  return
end

# Check LDom VDS

def check_cdom_vds()
  message = "Information:\tChecking LDom VDS"
  command = "ldm list-services |grep 'primary-vds'"
  output  = execute_command(options,message,command)
  if not output.match(/vds/)
    message = "Information:\tEnabling VDS"
    command = "ldm add-vds primary-vds0 primary"
    execute_command(options,message,command)
  end
  return
end

# Check LDom vSwitch

def check_cdom_vsw()
  message = "Information:\tChecking LDom vSwitch"
  command = "ldm list-services |grep 'primary-vsw'"
  output  = execute_command(options,message,command)
  if not output.match(/vsw/)
    message = "Information:\tEnabling vSwitch"
    command = "ldm add-vsw net-dev=net0 primary-vsw0 primary"
    execute_command(options,message,command)
  end
  return
end

# Check LDom config

def check_cdom_config(options)
  message = "Information:\tChecking LDom configuration"
  command = "ldm list-config |grep 'current'"
  output  = execute_command(options,message,command)
  if output.match(/factory\-default/)
    config  = $q_struct['cdom_name'].value
    message = "Information:\tChecking LDom configuration "+config+" doesn't exist"
    command = "ldm list-config |grep #{config}"
    output  = execute_command(options,message,command)
    if output.match(/#{config}/)
      handle_output(options,"Warning:\tLDom configuration #{config} already exists")
      quit(options)
    end
    if options['host-os-uname'].match(/T5[0-9]|T3/)
      mau     = $q_struct['cdom_mau'].value
      message = "Information:\tAllocating "+mau+"Crypto unit(s) to primary domain"
      command = "ldm set-mau #{mau} primary"
      execute_command(options,message,command)
    end
    vcpu    = $q_struct['cdom_vcpu'].value
    message = "Information:\tAllocating "+vcpu+"vCPU unit(s) to primary domain"
    command = "ldm set-vcpu #{vcpu} primary"
    execute_command(options,message,command)
    message = "Information:\tStarting reconfiguration of primary domain"
    command = "ldm start-reconf primary"
    execute_command(options,message,command)
    memory  = $q_struct['cdom_memory'].value
    message = "Information:\tAllocating "+memory+"to primary domain"
    command = "ldm set-memory #{memory} primary"
    execute_command(options,message,command)
    message = "Information:\tSaving LDom configuration of primary domain as "+config
    command = "ldm add-config #{config}"
    execute_command(options,message,command)
    command = "shutdown -y -g0 -i6"
    if options['yes'] == true
      message = "Warning:\tRebooting primary domain to enable settings"
      execute_command(options,message,command)
    else
      handle_output(options,"Warning:\tReboot required for settings to take effect")
      handle_output(options,"Infromation:\tExecute #{command}")
      quit(options)
    end
  end
  return
end

# Configure LDom vntsd

def check_cdom_vntsd()
  smf_service = "vntsd"
  enable_smf_service(smf_service)
  return
end

# Configure LDom Control (primary) domain

def configure_cdom(options)
  options['service'] = ""
  check_dhcpd_config(options)
  populate_cdom_questions()
  process_questions(options)
  check_cdom_install()
  check_cdom_vcc()
  check_cdom_vds()
  check_cdom_vsw()
  check_cdom_config(options)
  check_cdom_vntsd()
  return
end

# Configure LDom Server (calls configure_cdom)

def configure_ldom_server(options)
  configure_cdom(options)
  return
end

def configure_cdom_server(options)
  configure_cdom(options)
  return
end

# Unconfigure LDom Server

def unconfigure_cdom()
  handle_output(options,"Warning:\tCurrently unconfiguring the Control Domain must be done manually")
  quit(options)
  return
end

def unconfigure_ldom_server(options)
  unconfigure_cdom()
  return
end

def unconfigure_gdom_server(options)
  unconfigure_cdom()
  return
end

# List LDom ISOs

def list_ldom_isos()
  return
end

def list_cdom_isos()
  return
end

def list_gdom_isos()
  return
end
