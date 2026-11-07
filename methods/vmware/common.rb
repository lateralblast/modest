# frozen_string_literal: true

# Code common to ESX

# Import a disk to ESX

def import_esx_disk(values)
  values['vmdkfile'] = File.basename(values['vmdkfile'])
  new_vmdk_file = File.basename(values['vmdkfile'], '.old')
  new_vmdk_dir  = Pathname.new(values['vmdkfile'])
  new_vmdk_dir  = new_vmdk_dir.dirname.to_s
  command = "cd #{shell_arg(new_vmdk_dir)} ; vmkfstools -i #{shell_arg(values['vmdkfile'])} -d thin #{shell_arg(new_vmdk_file)}"
  execute_ssh_command(values, command)
  nil
end

# Import vmx file to ESX inventory

def import_esx_vm(values)
  command = "vim-cmd solo/registervm #{shell_arg(values['vmxfile'])}"
  execute_ssh_command(values, command)
  nil
end

# Check VMware Fusion (macOS) or VMware Workstation (Linux) is installed, reporting its version

def check_vmware(values)
  case values['check'].to_s
  when /fusion/ then check_vmware_fusion(values)
  when /workstation/ then check_vmware_workstation(values)
  end
  nil
end

def check_vmware_fusion(values)
  information_message(values, 'Checking VMware Fusion is installed')
  unless values['host-os-uname'].to_s.match(/Darwin/)
    warning_message(values, 'VMware Fusion runs on macOS only (use --check workstation on Linux)')
    return nil
  end
  app = '/Applications/VMware Fusion.app'
  unless File.directory?(app)
    warning_message(values, 'VMware Fusion is not installed (no /Applications/VMware Fusion.app)')
    install_vmware(values, 'Fusion', 'https://www.vmware.com/products/desktop-hypervisor.html')
    return nil
  end
  version = `defaults read "#{app}/Contents/Info.plist" CFBundleShortVersionString`.strip
  information_message(values, "VMware Fusion #{version} is installed at #{app}")
  warning_message(values, 'vmrun not found in VMware Fusion') unless File.executable?("#{app}/Contents/Library/vmrun")
  nil
end

def check_vmware_workstation(values)
  information_message(values, 'Checking VMware Workstation is installed')
  unless values['host-os-uname'].to_s.match(/Linux/)
    warning_message(values, 'VMware Workstation runs on Linux only (use --check fusion on macOS)')
    return nil
  end
  vmware = which_program('vmware')
  if vmware.empty?
    warning_message(values, 'VMware Workstation is not installed (vmware not found on PATH)')
    install_vmware(values, 'Workstation', 'https://www.vmware.com/products/workstation-pro.html')
    return nil
  end
  version = `#{shell_arg(vmware)} -v`.strip
  information_message(values, "#{version} is installed at #{vmware}")
  warning_message(values, 'vmrun not found on PATH') if which_program('vmrun').empty?
  nil
end

# VMware products are not in Homebrew or apt, so --install cannot install them; it says where to get them

def install_vmware(values, product, url)
  return nil unless values['install-check'] == true

  warning_message(values, "Cannot install VMware #{product} automatically: it is not in Homebrew or apt. Download it from #{url} and install it, then run --check again")
  nil
end
