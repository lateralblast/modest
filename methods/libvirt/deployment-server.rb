# frozen_string_literal: true

# Deployment server VM (--vm deployment-server).
#
# Builds a KVM VM from the Ubuntu cloud image: a qcow2 overlay on a shared base image, a cloud-init
# seed that adds the operator user, SSH key and a fixed address, an NFS export block for /export on
# the libvirt default network, and a hosts entry on the host. The default network's DHCP pool is
# moved above the fixed address. Delete removes the VM, its overlay, seed and hosts entry, never the
# shared base image, the exports or the DHCP pool.

require 'digest'
require 'fileutils'
require 'tmpdir'

DEPLOYMENT_SERVER_NAME          = 'deployment-server'
DEPLOYMENT_SERVER_IMAGE_DIR     = '/var/lib/libvirt/images'
DEPLOYMENT_SERVER_BASE_NAME     = 'ubuntu-26.04-server-cloudimg-amd64.img'
DEPLOYMENT_SERVER_BASE_URL      = 'https://cloud-images.ubuntu.com/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img'
DEPLOYMENT_SERVER_BASE_SHA      = '5645d0318ad21f643ebb1ac4567514620e9893380b07b0201fda163baa5b7eb5'
DEPLOYMENT_SERVER_NETWORK       = '192.168.122.0/24'
DEPLOYMENT_SERVER_GATEWAY       = '192.168.122.1'
DEPLOYMENT_SERVER_IP            = '192.168.122.10'
DEPLOYMENT_SERVER_POOL_START    = '192.168.122.50'
DEPLOYMENT_SERVER_POOL_END      = '192.168.122.250'
DEPLOYMENT_SERVER_VCPUS         = '2'
DEPLOYMENT_SERVER_MEMORY        = '4096'
DEPLOYMENT_SERVER_DISK_SIZE     = '40G'
DEPLOYMENT_SERVER_EXPORTS       = {
  '/export/isos'    => 'ro',
  '/export/pkgs'    => 'ro',
  '/export/repo'    => 'ro',
  '/export/clients' => 'rw',
  '/export/images'  => 'rw'
}.freeze
DEPLOYMENT_SERVER_EXPORTS_BEGIN = '# BEGIN modest deployment-server'
DEPLOYMENT_SERVER_EXPORTS_END   = '# END modest deployment-server'
DEPLOYMENT_SERVER_ROLE_FILE     = '/etc/modest/role'
DEPLOYMENT_SERVER_ROLE          = 'deployment-server'
DEPLOYMENT_SERVER_HOSTS_BEGIN   = '# BEGIN modest deployment-server'
DEPLOYMENT_SERVER_HOSTS_END     = '# END modest deployment-server'

# Dispatch for --vm deployment-server. Returns values, as handle_action does

def deployment_server_action(values)
  case values['action'].to_s
  when /create/
    create_deployment_server(values)
  when /delete/
    delete_deployment_server(values)
  else
    warning_message(values, "--vm deployment-server supports --action create and delete, not #{values['action']}")
  end
  values
end

# Name of the VM, default deployment-server

def deployment_server_name(values)
  values['name'].to_s.match(/[a-z0-9]/) && values['name'] != values['empty'] ? values['name'] : DEPLOYMENT_SERVER_NAME
end

# Read the operator's public key, from --sshkeyfile or the default key

def deployment_server_ssh_key(values)
  key_file = values['sshkeyfile'].to_s
  unless File.exist?(key_file)
    warning_message(values, "SSH public key file #{key_file} does not exist (use --sshkeyfile)")
    quit(values)
  end
  File.read(key_file).strip
end

# Cloud-init user data: rename the default cloud user to the operator, add the key, no password SSH

def deployment_server_user_data(values)
  <<~CLOUD_CONFIG
    #cloud-config
    system_info:
      default_user:
        name: #{values['user']}
        lock_passwd: true
        gecos: MODEST operator
    ssh_pwauth: false
    ssh_authorized_keys:
      - #{deployment_server_ssh_key(values)}
    packages:
      - etckeeper
      - nfs-common
    write_files:
      - path: #{DEPLOYMENT_SERVER_ROLE_FILE}
        permissions: '0644'
        content: #{DEPLOYMENT_SERVER_ROLE}
  CLOUD_CONFIG
end

# Role marker: cloud-init writes it on the deployment server VM. See on_deployment_server?

def on_deployment_server?
  role_file = DEPLOYMENT_SERVER_ROLE_FILE
  return false unless File.exist?(role_file) && File.read(role_file).strip == DEPLOYMENT_SERVER_ROLE

  %w[kvm qemu].include?(`systemd-detect-virt --vm 2>/dev/null`.strip)
end

# Report whether this machine is the deployment server (--action check --check deployment-server)

def check_deployment_server_role(values)
  information_message(values, 'Checking whether this machine is the deployment server')
  if on_deployment_server?
    information_message(values, "This machine is the deployment server (#{DEPLOYMENT_SERVER_ROLE_FILE} is set and it is a KVM guest)")
  else
    information_message(values, 'This machine is not the deployment server')
  end
  nil
end

# Cloud-init network config: a fixed address on the libvirt default network

def deployment_server_network_config
  <<~NETWORK_CONFIG
    version: 2
    ethernets:
      primary:
        match:
          name: "en*"
        addresses:
          - #{DEPLOYMENT_SERVER_IP}/24
        routes:
          - to: default
            via: #{DEPLOYMENT_SERVER_GATEWAY}
        nameservers:
          addresses:
            - #{DEPLOYMENT_SERVER_GATEWAY}
  NETWORK_CONFIG
end

# Make sure the base cloud image is in the libvirt images directory, downloading and checking it if not

def deployment_server_base_image(values)
  base_image = File.join(DEPLOYMENT_SERVER_IMAGE_DIR, DEPLOYMENT_SERVER_BASE_NAME)
  return base_image if File.exist?(base_image)

  if values['dryrun'] == true
    information_message(values, "Dry run: would download #{DEPLOYMENT_SERVER_BASE_URL} to #{base_image}")
    return base_image
  end
  download_file = File.join(Dir.tmpdir, DEPLOYMENT_SERVER_BASE_NAME)
  execute_command(values, "Information:\tDownloading the cloud image", "curl -sSfL -o #{shell_arg(download_file)} #{shell_arg(DEPLOYMENT_SERVER_BASE_URL)}")
  actual_sha = Digest::SHA256.file(download_file).hexdigest
  unless actual_sha == DEPLOYMENT_SERVER_BASE_SHA
    warning_message(values, "Checksum mismatch for #{download_file}: expected #{DEPLOYMENT_SERVER_BASE_SHA}, got #{actual_sha}")
    quit(values)
  end
  execute_command(values, "Information:\tInstalling #{base_image}", "sudo install -o root -g root -m 0644 #{shell_arg(download_file)} #{shell_arg(base_image)}")
  File.delete(download_file) if File.exist?(download_file)
  base_image
end

# Build the cloud-init seed ISO and copy it into the libvirt images directory

def deployment_server_seed(values, name)
  seed_name = "#{name}-seed.iso"
  seed_path = File.join(DEPLOYMENT_SERVER_IMAGE_DIR, seed_name)
  work_dir  = Dir.mktmpdir('modest-seed')
  user_data = File.join(work_dir, 'user-data')
  meta_data = File.join(work_dir, 'meta-data')
  network   = File.join(work_dir, 'network-config')
  seed_file = File.join(work_dir, seed_name)
  File.write(user_data, deployment_server_user_data(values))
  File.write(meta_data, "instance-id: #{name}-1\nlocal-hostname: #{name}\n")
  File.write(network, deployment_server_network_config)
  execute_command(values, "Information:\tBuilding the cloud-init seed",
                  "cloud-localds --network-config=#{shell_arg(network)} #{shell_arg(seed_file)} #{shell_arg(user_data)} #{shell_arg(meta_data)}")
  execute_command(values, "Information:\tInstalling #{seed_path}", "sudo install -o root -g root -m 0644 #{shell_arg(seed_file)} #{shell_arg(seed_path)}")
  seed_path
ensure
  FileUtils.rm_rf(work_dir) if work_dir && File.directory?(work_dir)
end

# Replace the lines between a begin and end marker in a file with body, or remove them when body is
# nil. Lines outside the markers are kept. Returns true when the file was changed

def deployment_server_set_block(values, file, begin_marker, end_marker, body, backup = nil)
  current = File.exist?(file) ? File.read(file) : ''
  kept    = []
  skipping = false
  current.each_line do |line|
    if line.start_with?(begin_marker)
      skipping = true
      next
    end
    if skipping
      skipping = false if line.start_with?(end_marker)
      next
    end
    kept.push(line)
  end
  new_content = if body.nil?
                  kept.join
                else
                  kept.join.rstrip + "\n\n" + ([begin_marker] + body + [end_marker]).join("\n") + "\n"
                end
  return false if new_content == current

  if values['dryrun'] == true
    information_message(values, "Dry run: would change the modest block in #{file}")
    return false
  end
  execute_command(values, "Information:\tSaving #{file} before the first change", "sudo cp -a #{shell_arg(file)} #{shell_arg(backup)}") if backup && !File.exist?(backup)
  work_file = File.join(Dir.tmpdir, "modest-block-#{Process.pid}-#{File.basename(file)}")
  File.write(work_file, new_content)
  execute_command(values, "Information:\tWriting #{file}", "sudo install -o root -g root -m 0644 #{shell_arg(work_file)} #{shell_arg(file)}")
  File.delete(work_file) if File.exist?(work_file)
  true
end

# Write the NFS export block for /export to the libvirt network, then apply the exports

def deployment_server_exports(values)
  body = DEPLOYMENT_SERVER_EXPORTS.map { |path, mode| "#{path} #{DEPLOYMENT_SERVER_NETWORK}(#{mode},sync,no_subtree_check,root_squash)" }
  changed = deployment_server_set_block(values, '/etc/exports', DEPLOYMENT_SERVER_EXPORTS_BEGIN, DEPLOYMENT_SERVER_EXPORTS_END, body, '/etc/exports.before-modest')
  if changed
    execute_command(values, 'Information:\tApplying NFS exports', 'sudo exportfs -ra')
  else
    information_message(values, 'NFS exports for the deployment server are already in place')
  end
  nil
end

# Put the deployment server's fixed address in the host's hosts file

def deployment_server_hosts(values, name, add)
  body = add ? ["#{DEPLOYMENT_SERVER_IP} #{name}"] : nil
  deployment_server_set_block(values, '/etc/hosts', DEPLOYMENT_SERVER_HOSTS_BEGIN, DEPLOYMENT_SERVER_HOSTS_END, body, '/etc/hosts.before-modest')
  nil
end

# Move the default network's DHCP pool so that the fixed address is outside it

def deployment_server_dhcp_pool(values)
  xml   = `virsh net-dumpxml default 2>/dev/null`
  range = xml.match(/<range start='([^']+)' end='([^']+)'\/>/)
  if range.nil?
    warning_message(values, 'The default libvirt network has no DHCP range to change')
    return nil
  end
  return nil if range[1] == DEPLOYMENT_SERVER_POOL_START && range[2] == DEPLOYMENT_SERVER_POOL_END

  old_range = "<range start='#{range[1]}' end='#{range[2]}'/>"
  new_range = "<range start='#{DEPLOYMENT_SERVER_POOL_START}' end='#{DEPLOYMENT_SERVER_POOL_END}'/>"
  execute_command(values, "Information:\tMoving the DHCP pool of the default network to #{DEPLOYMENT_SERVER_POOL_START}-#{DEPLOYMENT_SERVER_POOL_END}",
                  "virsh net-update default delete ip-dhcp-range #{shell_arg(old_range)} --live --config")
  execute_command(values, 'Information:\tAdding the new DHCP pool', "virsh net-update default add-last ip-dhcp-range #{shell_arg(new_range)} --live --config")
  nil
end

# Create the deployment server VM

def create_deployment_server(values)
  name = deployment_server_name(values)
  information_message(values, "Creating deployment server VM #{name}")
  existing = `virsh dominfo #{shell_arg(name)} 2>/dev/null`
  if existing.match(/Name:\s+#{name}/)
    warning_message(values, "VM #{name} already exists. Delete it with --action delete --vm deployment-server first")
    quit(values)
  end
  base_image = deployment_server_base_image(values)
  overlay    = File.join(DEPLOYMENT_SERVER_IMAGE_DIR, "#{name}.qcow2")
  deployment_server_dhcp_pool(values)
  deployment_server_exports(values)
  deployment_server_hosts(values, name, true)
  seed_path  = deployment_server_seed(values, name)
  execute_command(values, "Information:\tCreating disk #{overlay}",
                  "sudo qemu-img create -f qcow2 -F qcow2 -b #{shell_arg(base_image)} #{shell_arg(overlay)} #{DEPLOYMENT_SERVER_DISK_SIZE}")
  virt_install = "virt-install --name #{shell_arg(name)} --memory #{DEPLOYMENT_SERVER_MEMORY} --vcpus #{DEPLOYMENT_SERVER_VCPUS} " \
                 "--cpu host-passthrough --import " \
                 "--disk path=#{shell_arg(overlay)},format=qcow2,bus=virtio " \
                 "--disk path=#{shell_arg(seed_path)},device=cdrom,readonly=on " \
                 '--network network=default,model=virtio --os-variant generic ' \
                 '--graphics none --console pty,target_type=serial --noautoconsole'
  execute_command(values, "Information:\tStarting VM #{name}", virt_install)
  information_message(values, "Connect with: ssh #{values['user']}@#{DEPLOYMENT_SERVER_IP}")
  nil
end

# Delete the deployment server VM. Removes only its own overlay, seed and hosts entry. The base image,
# the NFS exports and the DHCP pool are shared and are kept

def delete_deployment_server(values)
  name    = deployment_server_name(values)
  overlay = File.join(DEPLOYMENT_SERVER_IMAGE_DIR, "#{name}.qcow2")
  seed    = File.join(DEPLOYMENT_SERVER_IMAGE_DIR, "#{name}-seed.iso")
  execute_command(values, "Information:\tStopping VM #{name}", "virsh destroy #{shell_arg(name)}")
  execute_command(values, "Information:\tUndefining VM #{name}", "virsh undefine #{shell_arg(name)}")
  execute_command(values, "Information:\tRemoving #{overlay} and #{seed}", "sudo rm -f #{shell_arg(overlay)} #{shell_arg(seed)}")
  deployment_server_hosts(values, name, false)
  nil
end
