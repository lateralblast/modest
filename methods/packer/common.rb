# frozen_string_literal: true

# Common packer code

# Get packer version

def get_packer_version(values)
  `#{shell_arg(values['packer'])} --version`.chomp
end

# Check packer is installed

def check_packer_is_installed(values)
  packer_bin = if values['packer'] == values['empty']
                 which_program('packer')
               else
                 values['packer'].to_s
               end
  packer_version = values['packerversion'].to_s
  if !packer_bin.match(/packer/) || !File.exist?(packer_bin)
    if values['host-os-uname'].to_s.match(/Darwin/)
      install_osx_package(values, 'packer')
      packer_bin = which_program('packer')
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
      command = "sudo sh -c 'cd /tmp ; unzip -o #{shell_sq(tmp_file)} ; cp /tmp/packer /usr/local/bin ; chmod +x /usr/local/bin/packer'"
      execute_command(values, message, command)
    end
  end
  values['packer'] = packer_bin
  values
end

# Check Packer is installed (--action check --check packer). With --install, install it when it is missing

def check_packer(values)
  information_message(values, 'Checking Packer is installed')
  packer_bin = which_program('packer')
  if packer_bin.empty?
    warning_message(values, 'Packer is not installed (packer not found on PATH)')
    install_packer(values) if values['install-check'] == true
    packer_bin = which_program('packer')
    return nil if packer_bin.empty?
  end
  # Read-only, so it runs under --dryrun too (execute_command would skip it as a packer call)
  version = `#{shell_arg(packer_bin)} version`.lines.first.to_s.strip
  information_message(values, "#{version} is installed at #{packer_bin}")
  nil
end

# Install Packer with Homebrew from the HashiCorp tap on macOS. Other systems get the download page

def install_packer(values)
  return nil unless values['install-check'] == true

  unless values['host-os-uname'].to_s.match(/Darwin/)
    warning_message(values, 'Packer install is automated for macOS only. Download it from https://developer.hashicorp.com/packer/install and put it on PATH')
    return nil
  end
  if which_program('brew').empty?
    warning_message(values, 'Cannot install Packer: Homebrew (brew) is not installed')
    return nil
  end
  if values['dryrun'] == true
    information_message(values, 'Dry run: would install Packer with Homebrew (brew install hashicorp/tap/packer)')
    return nil
  end
  message = "Information:\tInstalling Packer with Homebrew"
  command = 'brew install hashicorp/tap/packer'
  execute_command(values, message, command)
  nil
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
