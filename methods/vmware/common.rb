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
