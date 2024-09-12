# QEMU support code

# Check QEMU VM exists

def check_qemu_vm_exists(values)
  message   = "Information:\tChecking VM "+values['name']+" exists"
  command   = "virsh list --all"
  host_list = execute_command(values, message, command)
  if not host_list.match(/#{values['name']}/)
    if values['verbose'] == true
      verbose_output(values, "Information:\tKVM VM #{values['name']} does not exist")
    end
    exists = false
  else
    exists = true
  end
  return exists
end

# Get QEMY guest OS

def get_qemu_guest_os(values)
  if values['method'].to_s.match(/win/)
    guest_os = "windows"
  else
    guest_os = "linux"
  end
  return guest_os
end

# Check KVM VM exists

def check_kvm_vm_exists(values)
  check_qemu_vm_exists(values)
end

# Check KVM VM exists

def check_xen_vm_exists(values)
  check_qemu_vm_exists(values)
end

# Get KVM guest OS

def get_kvm_guest_os(values)
  guest_os = get_qemu_guest_os(values)
  return guest_os
end

# Get XEN guest OS

def get_xen_guest_os(values)
  return
end

# Check QEMU is installed

def check_qemu_is_installed(values)
  return
end

# List QEMU VMs

def list_qemu_vms(values)
  return
end
