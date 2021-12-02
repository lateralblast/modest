# Code common to ESX

# Import a disk to ESX

def import_esx_disk(options)
	options['vmdkfile'] = File.basename(options['vmdkfile'])
	new_vmdk_file = File.basename(options['vmdkfile'],".old")
	new_vmdk_dir  = Pathname.new(options['vmdkfile'])
	new_vmdk_dir  = new_vmdk_dir.dirname.to_s
	command = "cd "+new_vmdk_dir+" ; vmkfstools -i "+options['vmdkfile']+" -d thin "+new_vmdk_file
	execute_ssh_command(options,command)
	return
end

# Import vmx file to ESX inventory

def import_esx_vm(options)
	command = "vim-cmd solo/registervm "+options['vmxfile']
	execute_ssh_command(options,command)
	return
end