# QEMU support code

# Check QEMU VM exists

def check_qemu_vm_exists(options)
  message   = "Information:\tChecking VM "+options['name']+" exists"
  command   = "virsh list --all"
  host_list = execute_command(options,message,command)
  if not host_list.match(/#{options['name']}/)
    if options['verbose'] == true
      handle_output(options,"Information:\tKVM VM #{options['name']} does not exist")
    end
    exists = false
  else
    exists = true
  end
  return exists
end

# Get QEMY guest OS

def get_qemu_guest_os(options)
  if options['method'].to_s.match(/win/)
    guest_os = "windows"
  else
    guest_os = "linux"
  end
  return guest_os
end

# Check KVM VM exists

def check_kvm_vm_exists(options)
  check_qemu_vm_exists(options)
end

# Check KVM VM exists

def check_xen_vm_exists(options)
  check_qemu_vm_exists(options)
end

# Get KVM guest OS

def get_kvm_guest_os(options)
  guest_os = get_qemu_guest_os(options)
  return guest_os
end

# Get XEN guest OS

def get_xen_guest_os(options)
  return
end

# Check QEMU is installed

def check_qemu_is_installed(options)
  return
end

# List QEMU VMs

def list_qemu_vms(options)
  return
end
