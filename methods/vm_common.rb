# Code for creating client VMs for testing (e.g. VirtualBox)

# Handle VM install status

def handle_vm_install_status(options)
  if options['status'].to_s.match(/no/)
    handle_output(options,"Warning:\tVirtualisation application does not exist for #{options['vm']}")
    quit(options)
  end
  return
end

# AWS check

def check_aws_is_installed(options)
  check_if_aws_cli_is_installed()
  return
end

# Check a vm exists

def check_vm_exists(options)
  case options['vm']
  when /docker/
    exists = check_docker_vm_exists(options)
  when /aws/
    exists = check_aws_vm_exists(options)
  when /parallels/
    exists = check_parallels_vm_exists(options)
  when /qemu/
    exists = check_qemu_vm_exists(options)
  when /kvm/
    exists = check_kvm_vm_exists(options)
  when /vbox/
    exists = check_vbox_vm_exists(options)
  when /fusion/
    exists = check_fusion_vm_exists(options)
  end
  return exists
end

# Delete VM network

def delete_vm_network(options)
  case options['vm']
  when /fusion/
    exists = delete_fusion_vm_network(options)
  end
  return
end

# Delete VM snapshot

def delete_vm_snapshot(options)
  case options['vm']
  when /fusion/
    exists = delete_fusion_vm_snapshot(options)
  end
  return
end

# Try to get client VM type

def get_client_vm_type(options)
  options['vm'] = ""
  options['valid-vm'].each do |test_vm|
    if options['verbose'] == true
      handle_output(options,"Information:\tChecking if '#{options['name']}' is a '#{test_vm}' VM")
    end
    exists = eval"[check_#{test_vm}_is_installed(options)]"
    if exists.to_s.match(/yes/)
      exists = eval"[check_#{test_vm}_vm_exists(options)]"
      if exists.to_s.match(/yes/)
        options['vm'] = test_vm
        return options['vm']
      end
    end
  end
  return options['vm']
end

# Show VM config

def show_vm_config(options)
  case options['vm']
  when /fusion/
    show_fusion_vm_config(options)
  when /vbox/
    show_vbox_vm_config(options)
  end
  return
end

# Get VM screen

def get_vm_screen(options)
  case options['vm']
  when /fusion/
    get_fusion_vm_screen(options)
  end
  return
end

# Get VM network

def show_vm_network(options)
  case options['vm']
  when /fusion/
    show_fusion_vm_network(options)
  end
  return
end

# Get VM status

def get_vm_status(options)
  case options['vm']
  when /fusion/
    get_fusion_vm_status(options)
  when /vbox/
    get_vboc_vm_status(options)
  when /parallels/
    get_parallels_vm_status(options)
  end
  return
end

# VNC to VMware Fusion VM

def vnc_to_vm(options)
  options['ip'] = single_install_ip(options)
  novnc_dir = options['novncdir']
  check_vnc_install(options)
  exists = check_vm_exists(options)
  if exists.match(/yes/)
    if File.directory?(options['novncdir'])
      if not options['ip'].to_s.match(/[0-9]/)
        options['ip'] = get_fusion_vm_ip(options)
      end
      if options['ip'].to_s.match(/[0-9]/)
        temp_ip = options['ip'].split(/\./)[-1]
        if temp_ip.to_i < 100
          local_vnc_port = "60"+temp_ip
        else
          local_vnc_port = "6"+temp_ip
        end
        if options['vncport'] == options['empty']
          if options['vm'].to_s.match(/fusion/)
            remote_vnc_port = get_fusion_vm_vmx_file_value(options['name'],"remotedisplay.vnc.port")
          end
        else
          remote_vnc_port = options['vncport'] 
        end
        if remote_vnc_port.match(/[0-9]/)
          message = "Information:\tChecking noVNC isn't already running"
          command = "ps -ef |grep noVNC |grep #{options['ip']} | grep -v grep"
          output  = execute_command(options,message,command)
          if not output.match(/noVNC/)
            message = "Information:\tStarting noVNC web proxy on port "+local_vnc_port+" and redirecting to "+remote_vnc_port
            command = "cd '#{novnc_dir}' ; ./utils/launch.sh --listen #{local_vnc_port} --vnc #{options['ip']}:#{remote_vnc_port} &"
            execute_command(options,message,command)
            handle_output(options,"Information:\tNoVNC started on port #{local_vnc_port}")
          else
            handle_output(options,"Information:\tnoVNC already running")
          end
        else
          handle_output(options,"Warning:\tUnable to determine VNC port for #{options['vmapp']} VM #{options['name']}")
        end
      else
        handle_output(options,"Warning:\tUnable to determine IP for #{options['vmapp']} VM #{options['name']}")
      end
    end
  end
  return options['ip'],local_vnc_port,remote_vnc_port
end

# Get Guest OS type

def get_vm_guest_os(options)
  case options['vm']
  when /qemu/
    guest_os = get_qemu_guest_os(options)
  when /kvm/
    guest_os = get_kvm_guest_os(options)
  when /xen/
    guest_os = get_xen_guest_os(options)
  when /vbox/
    guest_os = get_vbox_guest_os(options)
  when /fusion/
    guest_os = get_fusion_guest_os(options)
  end
  return guest_os
end

# Check VM network

def check_vm_network(options)
  check_local_config(options)
  get_default_host(options)
  vm_if_name = get_vm_if_name(options)
  if options['vmnetwork'].to_s.match(/nat/)
    gw_if_name = get_gw_if_name(options)
    gw_if_ip   = get_gw_if_ip(options,gw_if_name)
    options['vmgateway'] = gw_if_ip
  end
  case options['vm']
  when /vbox/
    options = check_vbox_natd(options,vm_if_name)
  when /fusion/
    options = check_fusion_natd(options,vm_if_name)
  when /mp|multipass/
    options = check_multipass_natd(options,vm_if_name)
  end
  if options['host-os-name'].to_s.match(/NT/)
    output = get_win_ip_from_if_name(vm_if_name)
  else
    message = "Information:\tChecking "+vm_if_name+" is configured"
    command = "ifconfig #{vm_if_name} |grep inet"
    output  = execute_command(options,message,command)
  end
  if not output.match(/#{options['hostonlyip']}/)
    message = "Information:\tConfiguring "+vm_if_name
    if options['host-os-name'].to_s.match(/NT/)
      command = "netsh interface ip set address #{vm_if_name} static #{options['hostonlyip']} #{options['netmask']}"
    else
      command = "ifconfig #{vm_if_name} inet #{options['hostonlyip']} netmask #{options['netmask']} up"
    end
    execute_command(options,message,command)
  end
  return options
end

# List VM snapshots

def list_vm_snapshots(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /vbox/
    list_vbox_vm_snapshots(options)
  when /fusion/
    list_fusion_vm_snapshots(options)
  end
  return
end

# List all VM snapshots

def list_all_vm_snaphsots(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /vbox/
    list_all_vbox_vm_snapshots(options)
  when /fusion/
    list_all_fusion_vm_snapshots(options)
  end
  return
end

# Delete VM snapshots

def delete_vm_snaphsot(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /vbox/
    delete_vbox_vm_snapshot(options)
  when /fusion/
    delete_fusion_vm_snapshot(options)
  when /aws/
    delete_aws_vm_snapshot(options)
  end
  return
end

# Control VM

def control_vm(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['action']
  when /delete|unconfigure/
    unconfigure_vm(options)
  when /create|configure/
    configure_vm(options)
  when /boot|start/
    boot_vm(options)
  when /halt|stop/
    halt_vm(options)
  end
  return
end

# Boot VM

def boot_vm(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /docker/
    exists = boot_docker_vm(options)
  when /aws/
    exists = boot_aws_vm(options)
  when /parallels/
    exists = boot_parallels_vm(options)
  when /qemu/
    exists = boot_qemu_vm(options)
  when /kvm/
    exists = boot_kvm_vm(options)
  when /vbox/
    exists = boot_vbox_vm(options)
  when /fusion/
    exists = boot_fusion_vm(options)
  when /cdom/
    exists = boot_cdom_vm(options)
  when /gdom/
    exists = boot_cdom_vm(options)
  end
  return exists
end

# Stop VM

def stop_vm(options)
  exists = halt_vm(options)
  return exists
end

# Import VMDK

def import_vmdk(options)
  case options['vm']
  when /fusion/
    import_fusion_ova(options)
  end
  return
end

# Add VM network

def add_vm_network(options)
  case options['vm']
  when /fusion/
    add_fusion_vm_network(options)
  end
  return
end

# Halt VM

def halt_vm(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /docker/
    exists = halt_docker_vm(options)
  when /aws/
    exists = halt_aws_vm(options)
  when /parallels/
    exists = halt_parallels_vm(options)
  when /qemu/
    exists = halt_qemu_vm(options)
  when /kvm/
    exists = halt_kvm_vm(options)
  when /vbox/
    exists = halt_vbox_vm(options)
  when /fusion/
    exists = halt_fusion_vm(options)
  when /cdom/
    exists = halt_cdom_vm(options)
  when /gdom/
    exists = halt_cdom_vm(options)
  end
  return exists
end

# Configure VM

def configure_vm(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /docker/
    configure_docker_vm(options)
  when /aws/
    configure_aws_vm(options)
  when /parallels/
   configure_parallels_vm(options)
  when /qemu/
   configure_qemu_vm(options)
  when /kvm/
    configure_kvm_vm(options)
  when /vbox/
    configure_vbox_vm(options)
  when /fusion/
    configure_fusion_vm(options)
  when /cdom/
    configure_cdom_vm(options)
  when /gdom/
    configure_cdom_vm(options)
  when /multipass|mp/
    configure_multipass_vm(options)
  end
  return
end

# Delete VM

def unconfigure_vm(options)
  delete_vm(options)
  return
end

def delete_vm(options)
  if options['vm'] == options['empty']
    options['vm'] = get_client_vm_type(options)
  end
  case options['vm']
  when /docker/
    unconfigure_docker_vm(options)
  when /aws/
    unconfigure_aws_vm(options)
  when /parallels/
    unconfigure_parallels_vm(options)
  when /qemu/
    unconfigure_qemu_vm(options)
  when /kvm/
    unconfigure_kvm_vm(options)
  when /vbox/
    unconfigure_vbox_vm(options)
  when /fusion/
    unconfigure_fusion_vm(options)
  when /cdom/
    unconfigure_cdom_vm(options)
  when /gdom/
    unconfigure_cdom_vm(options)
  when /multipass|mp/
    unconfigure_multipass_vm(options)
  end
  return
end

# Create VM

def create_vm(options)
  options['ip'] = single_install_ip(options)
  if options['vm'].to_s.match(/fusion/) and options['mac'].to_s.match(/[0-9]/)
    options['mac'] = check_fusion_vm_mac(options)
  end
  if not options['method'].to_s.match(/[a-z]/) and not options['os-type'].to_s.match(/[a-z]/)
    if options['verbose'] == true
      handle_output(options,"Warning:\tInstall method or OS not specified")
      handle_output(options,"Information:\tSetting OS to other")
    end
    options['method'] = "other"
  end
  if options['file'].to_s.match(/ova$/)
    if options['vm'].to_s.match(/vbox/)
      configure_vm(options)
    end
    import_ova(options)
  else
    configure_vm(options)
  end
  return
end

# Import OVA

def import_ova(options)
  case options['vm']
  when /kmv/
    import_kvm_ova(options)
  when /vbox/
    import_vbox_ova(options)
  when /fusion/
    import_fusion_ova(options)
  end
  return
end

# list VMs

def list_vms(options)
  case options['vm']
  when /vbox/
    list_vbox_vms(options)
  when /fusion/
    list_fusion_vms(options)
  when /parallels/
    list_parallels_vms(options)
  when /kvm/
    list_kvm_vms(options)
  when /docker/
    list_docker_vms(options)
  when /multipass|mp/
    list_multipass_vms(options)
  else
    list_all_vms(options)
  end
  return
end

# list VM

def list_vm(options)
  if not options['os-type'].to_s.match(/[a-z]/) and not options['method'].to_s.match(/[a-z]/)
    eval"[list_all_#{options['vm']}_vms()]"
  else
    if options['method'].to_s.match(/[a-z]/)
      eval"[list_#{options['method']}_#{options['vm']}_vms()]"
    else
      [ "ks", "js", "ps", "ay", "ai" ].each do |method|
        eval"[list_#{method}_#{options['vm']}_vms()]"
      end
    end
  end
  return
end

# List VM snaphots

def list_vm_snapshots(options)
  if options['name'].to_s.match(/[a-z]/)
    eval"[list_#{options['vm']}_vm_snapshots(options)]"
  else
    if not options['os-type'].to_s.match(/[a-z]/) and not options['method'].to_s.match(/[a-z]/)
      eval"[list_all_#{options['vm']}_vm_snapshots()]"
    end
  end
  return
end

# Catch all for listing VMs

def list_none_vms(options)
  return
end
