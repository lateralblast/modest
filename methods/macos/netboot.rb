# frozen_string_literal: true
require 'securerandom'
require 'socket'
require 'io/console'

# macOS netboot services: dnsmasq (DHCP and TFTP) on the VMware host-only network,
# and Homebrew httpd (repository and seed files). Config and state live under
# <export>/state/netboot, so removing that directory (after stopping the services) undoes them.

# Netboot state directory

def osx_netboot_dir(values)
  "#{File.dirname(values['baserepodir'])}/state/netboot"
end

# Host address of a VMware host-only network, read from the Fusion networking file (for example vmnet9 gives 192.168.209.1)

def get_osx_vmnet_host_ip(values)
  vnet_number = values['vmnet'].to_s[/\d+/]
  return nil if vnet_number.nil?

  vmnet_file = '/Library/Preferences/VMware Fusion/networking'
  return nil unless File.exist?(vmnet_file)

  subnet = nil
  IO.readlines(vmnet_file).each do |line|
    subnet = line.split(' ')[-1] if line.match?(/answer VNET_#{vnet_number}_HOSTONLY_SUBNET /)
  end
  return nil if subnet.nil?

  "#{subnet.split('.')[0..2].join('.')}.1"
end

# Interface that holds an IP address (for example bridge104)

def get_osx_interface_for_ip(values, host_ip)
  message = "Checking:\tInterface with IP #{host_ip}"
  command = "ifconfig -a | awk '/^[a-z]/{i=$1} /inet #{host_ip} /{sub(/:$/,\"\",i); print i; exit}'"
  execute_command(values, message, command).to_s.chomp
end

# Write the dnsmasq config for DHCP and TFTP on one interface (DNS is disabled)

def write_osx_dnsmasq_config(values, if_name, host_ip, boot_file)
  state_dir = osx_netboot_dir(values)
  network   = host_ip.split('.')[0..2].join('.')
  conf_file = "#{state_dir}/dnsmasq-#{if_name}.conf"
  lines = [
    "# Written by MODEST for the host-only network on #{if_name} (#{host_ip})",
    "interface=#{if_name}",
    'bind-interfaces',
    'port=0',
    "dhcp-range=#{network}.100,#{network}.150,12h",
    "dhcp-option=option:router,#{host_ip}",
    "dhcp-leasefile=#{state_dir}/dnsmasq-#{if_name}.leases",
    'enable-tftp',
    "tftp-root=#{values['tftpdir']}",
    "dhcp-boot=#{boot_file},,#{host_ip}",
    'log-dhcp',
    "log-facility=#{state_dir}/dnsmasq-#{if_name}.log"
  ]
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would write #{conf_file}")
    return conf_file
  end
  FileUtils.mkdir_p(state_dir)
  File.write(conf_file, "#{lines.join("\n")}\n")
  conf_file
end

# Start dnsmasq with the config (stops the previous instance started by MODEST first)

def start_osx_dnsmasq(values, conf_file)
  pid_file = conf_file.sub(/\.conf$/, '.pid')
  dnsmasq  = '/opt/homebrew/opt/dnsmasq/sbin/dnsmasq'
  message  = "Information:\tStarting dnsmasq with #{conf_file}"
  command  = "if [ -f #{shell_arg(pid_file)} ]; then sudo kill $(cat #{shell_arg(pid_file)}) 2>/dev/null; sleep 1; fi; " \
             "sudo #{shell_arg(dnsmasq)} -C #{shell_arg(conf_file)} --pid-file=#{shell_arg(pid_file)}"
  execute_command(values, message, command)
  nil
end

# Write the httpd config: Homebrew httpd on the host-only address, serving the export directory

def write_osx_httpd_config(values, host_ip, port)
  state_dir = osx_netboot_dir(values)
  conf_file = "#{state_dir}/httpd.conf"
  doc_root  = File.dirname(values['baserepodir'])
  brew_root = File.exist?('/opt/homebrew/etc/httpd/httpd.conf') ? '/opt/homebrew' : '/usr/local'
  modules   = IO.readlines("#{brew_root}/etc/httpd/httpd.conf").grep(/^LoadModule/).reject do |line|
    line.match?(/mpm_prefork|mpm_worker|php|dav|proxy|ssl|cgi|userdir|ldap|auth_digest|session|socache|status/)
  end
  lines = [
    "ServerRoot \"#{brew_root}\"",
    "Listen #{host_ip}:#{port}",
    "ServerName #{host_ip}:#{port}",
    "PidFile \"#{state_dir}/httpd.pid\"",
    "ErrorLog \"#{state_dir}/httpd-error.log\"",
    "CustomLog \"#{state_dir}/httpd-access.log\" common",
    "TypesConfig #{brew_root}/etc/httpd/mime.types",
    *modules.map(&:chomp),
    'LoadModule mpm_event_module lib/httpd/modules/mod_mpm_event.so',
    "DocumentRoot \"#{doc_root}\"",
    "<Directory \"#{doc_root}\">",
    '  Options +FollowSymLinks +Indexes',
    '  Require all granted',
    '</Directory>'
  ]
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would write #{conf_file}")
    return conf_file
  end
  FileUtils.mkdir_p(state_dir)
  File.write(conf_file, "#{lines.join("\n")}\n")
  conf_file
end

# Start Homebrew httpd with the config

def start_osx_httpd(values, conf_file)
  httpd   = '/opt/homebrew/opt/httpd/bin/httpd'
  message = "Information:\tStarting httpd with #{conf_file}"
  command = "if [ -f #{shell_arg(osx_netboot_dir(values))}/httpd.pid ]; then " \
            "kill $(cat #{shell_arg(osx_netboot_dir(values))}/httpd.pid) 2>/dev/null; sleep 1; fi; " \
            "#{shell_arg(httpd)} -f #{shell_arg(conf_file)} -k start"
  execute_command(values, message, command)
  nil
end

# Configure the netboot services for a macOS server: dnsmasq and httpd on the VMware host-only network

def configure_osx_netboot_services(values, boot_file = 'grubaa64.efi', port = '8081')
  # The generic default TFTP directory is /etc/netboot, which is not used on macOS
  values['tftpdir'] = '/private/tftpboot'
  unless values['nic-given'] == true
    warning_message(values, 'No --nic given: a server add on macOS needs the network interface for DHCP and TFTP, for example --nic bridge104. Nothing was configured')
    quit(values)
    return nil
  end
  if_name = values['nic']
  message = "Information:\tGetting the address of #{if_name}"
  host_ip = execute_command(values, message, "ifconfig #{shell_arg(if_name)} | awk '/inet /{print $2; exit}'").to_s.strip
  if host_ip.empty? && values['dryrun'] != true
    warning_message(values, "Interface #{if_name} has no IPv4 address (start the VM on its network first), so the netboot services are not configured")
    quit(values)
    return nil
  end
  host_ip = "#{if_name}-address" if host_ip.empty?
  information_message(values, "Netboot interface #{if_name} with host address #{host_ip}")
  dnsmasq_conf = write_osx_dnsmasq_config(values, if_name, host_ip, boot_file)
  start_osx_dnsmasq(values, dnsmasq_conf)
  httpd_conf = write_osx_httpd_config(values, host_ip, port)
  start_osx_httpd(values, httpd_conf)
  nil
end

# Autoinstall user-data for a Fusion or PXE cloud-init install: the ubuntu user (hashed password), the SSH key, and openssh-server

def osx_seed_user_lines(values, crypt, ssh_key)
  name = values['name']
  key_lines = ssh_key.nil? ? [] : ['      - "' + ssh_key + '"']
  [
    '#cloud-config',
    'autoinstall:',
    '  version: 1',
    '  locale: en_US.UTF-8',
    '  keyboard:',
    '    layout: us',
    '  identity:',
    "    hostname: #{name}",
    '    username: ubuntu',
    "    password: \"#{crypt}\"",
    '  ssh:',
    '    install-server: true',
    '    allow-pw: true',
    *(ssh_key.nil? ? [] : ['    authorized-keys:', *key_lines]),
    '  packages:',
    '    - openssh-server',
    '  storage:',
    '    layout:',
    '      name: direct',
    '  apt:',
    '    fallback: offline-install',
    '  late-commands:',
    "    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/90-modest-ubuntu",
    '    - chmod 440 /target/etc/sudoers.d/90-modest-ubuntu',
    '    - mkdir -p /target/etc/systemd/system/getty.target.wants',
    '    - ln -sf /usr/lib/systemd/system/serial-getty@.service /target/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service',
    '  shutdown: poweroff'
  ]
end

# Create the cloud-init seed for a macOS Fusion install: a cidata CD with autoinstall user-data (SSH key and install-server) and meta-data.
# The seed is kept under <export>/state/seeds/<name>, so it can be removed to undo it.

def create_osx_cloud_seed(values)
  name      = values['name']
  seed_dir  = "#{File.dirname(values['baserepodir'])}/state/seeds/#{name}"
  seed_iso  = "#{seed_dir}/#{name}-seed.iso"
  user_data = "#{seed_dir}/user-data"
  meta_data = "#{seed_dir}/meta-data"
  key_file  = values['sshkeyfile'].to_s
  if File.exist?(key_file)
    ssh_key = File.read(key_file).chomp
  else
    ssh_key = nil
    warning_message(values, "No SSH public key at #{key_file}, so the seed has no authorized key")
  end
  values['cidataiso'] = seed_iso
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would write the cloud-init seed to #{seed_dir}")
    return values
  end
  FileUtils.mkdir_p(seed_dir)
  password = SecureRandom.alphanumeric(16)
  crypt    = IO.popen(%w[openssl passwd -6 -stdin], 'r+') do |io|
    io.write(password)
    io.close_write
    io.read.chomp
  end
  key_lines = ssh_key.nil? ? [] : ['      - "' + ssh_key + '"']
  user_lines = osx_seed_user_lines(values, crypt, ssh_key)
  File.write(user_data, "#{user_lines.join("\n")}\n")
  File.chmod(0o600, user_data)
  File.write(meta_data, "instance-id: #{name}-#{Time.now.to_i}\nlocal-hostname: #{name}\n")
  File.write("#{seed_dir}/password.txt", "ubuntu password for #{name}: #{password}\n")
  File.chmod(0o600, "#{seed_dir}/password.txt")
  message = "Information:\tCreating cloud-init seed #{seed_iso}"
  command = "rm -f #{shell_arg(seed_iso)} ; xorriso -as mkisofs -V cidata -J -r -o #{shell_arg(seed_iso)} #{shell_arg(user_data)} #{shell_arg(meta_data)}"
  execute_command(values, message, command)
  values
end

# Build a copy of an Ubuntu ISO whose GRUB entry has the autoinstall argument, so the installer runs unattended from the cidata seed.
# The copy is kept under <export>/state/isos and is built once per source ISO.

def create_osx_autoinstall_iso(values)
  source   = values['file'].to_s
  iso_dir  = "#{File.dirname(values['baserepodir'])}/state/isos"
  dest_iso = "#{iso_dir}/#{File.basename(source, '.iso')}-autoinstall.iso"
  values['file'] = dest_iso
  return values if File.exist?(dest_iso)

  grub_cfg = "#{iso_dir}/grub-autoinstall.cfg"
  tmp_iso  = "#{iso_dir}/tmp-autoinstall.iso"
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would build #{dest_iso}")
    return values
  end
  FileUtils.mkdir_p(iso_dir)
  message = "Information:\tBuilding autoinstall ISO #{dest_iso}"
  # The first step removes the GRUB config; the second adds the one with autoinstall on the kernel line
  command = "bsdtar -xOf #{shell_arg(source)} boot/grub/grub.cfg | sed 's|^\\(    linux  /casper/vmlinuz.*\\)  ---|\\1 autoinstall  ---|; s|^\\(    linux .*\\)$|\\1 console=ttyS0,115200|' > #{shell_arg(grub_cfg)} ; " \
            "xorriso -indev #{shell_arg(source)} -outdev #{shell_arg(tmp_iso)} -boot_image any replay -rm /boot/grub/grub.cfg ; " \
            "xorriso -indev #{shell_arg(tmp_iso)} -outdev #{shell_arg(dest_iso)} -boot_image any replay -map #{shell_arg(grub_cfg)} /boot/grub/grub.cfg ; " \
            "rm -f #{shell_arg(tmp_iso)}"
  execute_command(values, message, command)
  values
end

# Console socket for a macOS Fusion VM: a serial port that Fusion serves on a Unix socket under <export>/state/consoles.
# Connect from a terminal with: socat - UNIX-CONNECT:<socket>

def create_osx_console(values)
  console_dir = "#{File.dirname(values['baserepodir'])}/state/consoles"
  sock_file   = "#{console_dir}/#{values['name']}.sock"
  values['consolesock'] = sock_file
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would serve the console on #{sock_file}")
    return values
  end
  FileUtils.mkdir_p(console_dir)
  File.delete(sock_file) if File.exist?(sock_file)
  verbose_message(values, "Console:\tsocat - UNIX-CONNECT:#{sock_file}")
  values
end

# Connect the terminal to the console socket of a macOS Fusion VM: serial output is shown and typed lines are sent to the VM.
# Ctrl-] disconnects; the VM keeps running.

def connect_osx_console(values, sock_file)
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would connect to the console #{sock_file}")
    return nil
  end
  20.times do
    break if File.exist?(sock_file)

    sleep 1
  end
  unless File.exist?(sock_file)
    warning_message(values, "Console socket #{sock_file} does not exist, so the console is not connected")
    return nil
  end
  information_message(values, "Console:\tconnected to #{values['name']} (Ctrl-] disconnects)")
  socket = UNIXSocket.new(sock_file)
  reader = Thread.new do
    loop do
      $stdout.write(socket.readpartial(4096))
      $stdout.flush
    end
  rescue EOFError, IOError, SystemCallError
    nil
  end
  # The terminal is raw while connected, so only the VM echoes what is typed. Ctrl-] disconnects.
  send_loop = lambda do
    while (char = $stdin.getc)
      break if char == "\x1d"

      socket.write(char)
    end
  end
  begin
    $stdin.tty? ? $stdin.raw { send_loop.call } : send_loop.call
  rescue Interrupt
    nil
  ensure
    reader.kill
    socket.close unless socket.closed?
  end
  nil
end

# Console bridge for VirtualBox: one background socat keeps a single connection open to the VM's serial socket
# and serves a pseudo-terminal, so clients can connect and disconnect without blocking the VM's serial port.

def osx_console_bridge_files(values)
  console_dir = "#{File.dirname(values['baserepodir'])}/state/consoles"
  {
    pty:  "#{console_dir}/#{values['name']}.pty",
    pid:  "#{console_dir}/#{values['name']}.bridge.pid",
    sock: "#{console_dir}/#{values['name']}.sock"
  }
end

# Start the bridge (stops a previous bridge for the same VM first)

def start_osx_console_bridge(values)
  files = osx_console_bridge_files(values)
  if values['dryrun'] == true
    verbose_message(values, "Dry run: would start the console bridge on #{files[:pty]}")
    return nil
  end
  if File.exist?(files[:pid])
    old_pid = File.read(files[:pid]).to_i
    Process.kill('TERM', old_pid) rescue nil
    File.delete(files[:pid])
  end
  File.delete(files[:pty]) if File.symlink?(files[:pty]) || File.exist?(files[:pty])
  command = "socat UNIX-CONNECT:#{shell_arg(files[:sock])} PTY,link=#{shell_arg(files[:pty])},raw,echo=0 >/dev/null 2>&1 & echo $! > #{shell_arg(files[:pid])}"
  system(command)
  20.times do
    break if File.symlink?(files[:pty]) || File.exist?(files[:pty])

    sleep 1
  end
  nil
end

# Stop the bridge for a VM

def stop_osx_console_bridge(values)
  files = osx_console_bridge_files(values)
  return nil unless File.exist?(files[:pid])

  Process.kill('TERM', File.read(files[:pid]).to_i) rescue nil
  File.delete(files[:pid])
  File.delete(files[:pty]) if File.symlink?(files[:pty]) || File.exist?(files[:pty])
  nil
end
