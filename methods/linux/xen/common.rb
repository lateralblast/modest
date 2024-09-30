# XEN support code

# Check XEN is installed

def check_xen_is_installed(values)
  return
end

# List XEN VMs

def list_xen_vms(values)
  if !values['host-os-uname'].to_s.match(/Linux/)
    return
  end
  return
end