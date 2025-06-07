# frozen_string_literal: true

# Common packer code

# Get packer version

def get_packer_version(values)
  `#{values['packer']} --version`.chomp
end

# Check packer is installed

def check_packer_is_installed(values)
  packer_bin = if values['packer'] == values['empty']
                 `which packer`.chomp
               else
                 values['packer'].to_s
               end
  packer_version = values['packerversion'].to_s
  if !packer_bin.match(/packer/) || !File.exist?(packer_bin)
    if values['host-os-uname'].to_s.match(/Darwin/)
      install_osx_package(values, 'packer')
      packer_bin = `which packer`.chomp
    else
      if values['host-os-unamem'].to_s.match(/64/)
        packer_bin = "packer_#{packer_version}_#{values['host-os-uname'].downcase}_amd64.zip"
        packer_url = "https://releases.hashicorp.com/packer/#{packer_version}/#{packer_bin}"
      else
        packer_bin = "packer_#{packer_version}_#{values['host-os-uname'].downcase}_386.zip"
        packer_url = "https://releases.hashicorp.com/packer/#{$packer_version}/#{packer_bin}"
      end
      tmp_file = "/tmp/#{packer_bin}"
      wget_file(values, packer_url, tmp_file) unless File.exist?(tmp_file)
      if !File.directory?('/usr/local/bin') && !File.symlink?('/usr/local/bin')
        message = "Information:\tCreating /usr/local/bin"
        command = 'mkdir /usr/local/bin'
        execute_command(values, message, command)
      end
      message = "Information:\tExtracting and installing Packer"
      command = "sudo sh -c 'cd /tmp ; unzip -o #{tmp_file} ; cp /tmp/packer /usr/local/bin ; chmod +x /usr/local/bin/packer'"
      execute_command(values, message, command)
    end
  end
  values['packer'] = packer_bin
  values
end

# Import Packer VM

def import_packer_vm(values)
  case values['vm']
  when /fusion/
    import_packer_fusion_vm(values)
  when /vbox/
    import_packer_vbox_vm(values)
  when /kvm/
    import_packer_kvm_vm(values)
  end
  nil
end
