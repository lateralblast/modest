#!/usr/bin/env ruby

# Name:         modest (Multi OS Deployment Engine Server Tool)
# Version:      7.1.7
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Script to automate creation of server configuration for
#               Solaris and other OS

# Additional notes:
#
# - Swapped Dir.exist for File.directory so ruby 2.x is not required
# - Swapped Dir.home for ENV['HOME'] so ruby 2.x is not required

require 'rubygems'
require 'pathname'
require 'fileutils'
require 'ipaddr'
require 'uri'
require 'socket'
require 'net/http'
require 'pp'
require 'open-uri'

class String
  def strip_control_characters
    chars.each_with_object do |char, str|
      str << char unless char.ascii_only? && (char.ord < 32 || char.ord == 127)
    end
  end
  def strip_control_and_extended_characters
    chars.each_with_object do |char, str|
      str << char if char.ascii_only? && char.ord.between?(32,126)
    end
  end
end

class String
  def convert_base(from, to)
    self.to_i(from).to_s(to)
  end
end

def install_gem(load_name)
  case load_name
  when "unix_crypt"
    install_name = "unix-crypt"
  when "getopt/long"
    install_name = "getopt"
  when "capistrano"
    install_name = "rvm-capistrano"
  when "net/scp"
    install_name = "net-scp"
  when "net/ssh"
    install_name = "net-ssh"
  when "terminfo"
    install_name = "ruby-terminfo"
  else
    install_name = load_name
  end
  puts "Information:\tInstalling #{install_name}"
  %x[gem install #{install_name}]
  Gem.clear_paths
  require "#{load_name}"
end

class NegatedRegex < Regexp
  def ===(other)
    !super
  end
end

class Regexp
  def negate
    NegatedRegex.new self
  end
end

# Current unused modules:
#
# "capistrano", "nokogiri", "mechanize", "terminfo"
#

[ "getopt/long", "builder", "parseconfig", "unix_crypt", "netaddr", "json",
  "fileutils", "ssh-config", "yaml", "net/ssh", "net/scp" ].each do |load_name|
  begin
    require "#{load_name}"
  rescue LoadError
    install_gem(load_name)
  end
end

# Declare array for text output (used for webserver)

options = {}
options['stdout']   = []
options['q_struct'] = {}
options['q_order'] = []

# Load methods

if File.directory?("./methods")
  file_list = Dir.entries("./methods")
  for file in file_list
    if file =~ /rb$/
      require "./methods/#{file}"
    end
  end
end

# Get command line arguments
# Print help if specified none

if !ARGV[0]
  options['output'] = 'text'
  print_help(options)
end

# Check whether we have any single - options

for option in ARGV
  if option.match(/^-[a-z]/)
    puts "Invalid option #{option} in command line"
    exit
  end
end

# Try to make sure we have valid long switches

valid_options = get_valid_options

ARGV[0..-1].each do |switch|
  if !valid_options.grep(/--#{switch}/) || switch.match(/^-[a-z,A-Z][a-z,A-Z]/)
    handle_output(options,"Invalid command line option: #{switch}")
    options['output'] = 'text'
    quit(options)
  end
end

# Process options

include Getopt

begin
  options = Long.getopts(
    ['--access', REQUIRED],           # AWS Access Key
    ['--acl', REQUIRED],              # AWS ACL
    ['--action', REQUIRED],           # Action (e.g. boot, stop, create, delete, list, etc)
    ['--admingid', REQUIRED],         # Admin user GID for client VM to be created
    ['--admingroup', REQUIRED],       # Admin user Group for client VM to be created
    ['--adminhome', REQUIRED],        # Admin user Home directory for client VM to be created
    ['--adminshell', REQUIRED],       # Admin user shell for client VM to be created
    ['--adminuid', REQUIRED],         # Admin user UID for client VM to be created
    ['--adminuser', REQUIRED],        # Admin username for client VM to be created
    ['--adminpassword', REQUIRED],    # Client admin password
    ['--auditsize', REQUIRED],        # Set audit fs size
    ['--auditfs', REQUIRED],          # Set audit fs
    ['--aidir', REQUIRED],            # Solaris AI Directory
    ['--aiport', REQUIRED],           # Solaris AI Port 
    ['--ami', REQUIRED],              # AWS AMI ID
    ['--arch', REQUIRED],             # Architecture of client or VM (e.g. x86_64)
    ['--autostart', BOOLEAN],         # Autostart (KVM)
    ['--awsuser', REQUIRED],          # AWS User
    ['--bename', REQUIRED],           # ZFS BE (Boot Environment) name
    ['--baserepodir', REQUIRED],      # Base repository directory
    ['--biosdevnames', BOOLEAN],      # Use biosdevnames (e.g. eth0 instead of eno1)
    ['--biostype', REQUIRED],         # BIOS boot type (bios/uefi)
    ['--blkiotune', REQUIRED],        # Block IO tune (KVM)
    ['--boot', REQUIRED],             # Set boot device
    ['--bootproto', REQUIRED],        # Set boot protocol
    ['--bootfs', REQUIRED],           # Set boot fs 
    ['--bootsize', REQUIRED],         # Set boot fs size
    ['--bridge', REQUIRED],           # Set bridge
    ['--bucket', REQUIRED],           # AWS S3 bucket
    ['--build', BOOLEAN],             # Build (Packer)
    ['--changelog', BOOLEAN],         # Print changelog
    ['--channel', BOOLEAN],           # Channel (KVM)
    ['--check', REQUIRED],            # Check
    ['--checksum', BOOLEAN],          # Do checksums
    ['--cidr', REQUIRED],             # CIDR
    ['--client', REQUIRED],           # Client / AWS Name
    ['--clientdir', REQUIRED],        # Base Client Directory
    ['--clientnic', REQUIRED],        # Client NIC
    ['--clock', REQUIRED],            # Clock (KVM)
    ['--clone', REQUIRED],            # Clone name
    ['--cloudfile', REQUIRED],        # Cloud init config image (KVM)
    ['--command', REQUIRED],          # Run command
    ['--comment', REQUIRED],          # Comment
    ['--configfile', REQUIRED],       # Config file (KVM)
    ['--connect', REQUIRED],          # Connect (KVM)
    ['--console', REQUIRED],          # Select console type (e.g. text, serial, x11) (default is text)
    ['--container', BOOLEAN],         # AWS AMI export container
    ['--containertype', REQUIRED],    # AWS AMI export container
    ['--controller', REQUIRED],       # Specify controller
    ['--copykeys', BOOLEAN],          # Copy SSH Keys (default)
    ['--country', REQUIRED],          # Country
    ['--cpu', REQUIRED],              # Type of CPU (e.g. KVM CPU type)
    ['--cputune', REQUIRED],          # CPU tune (KVM)
    ['--create', BOOLEAN],            # Create client / service
    ['--creds', REQUIRED],            # Credentials file
    ['--crypt', REQUIRED],            # Password crypt
    ['--datastore', REQUIRED],        # Datastore to deploy to on remote server
    ['--desc', REQUIRED],             # Description
    ['--dhcp', BOOLEAN],              # DHCP 
    ['--dhcpdfile', REQUIRED],        # DHCP Config file
    ['--dhcpdrange', REQUIRED],       # Set DHCP range
    ['--defaults', BOOLEAN],          # Answer yes to all questions (accept defaults)
    ['--delete', BOOLEAN],            # Delete client / service
    ['--destory-on-exit', BOOLEAN],   # Destroy on exit (KVM)
    ['--dir', REQUIRED],              # Directory / Direction
    ['--disk', REQUIRED],             # Disk file
    ['--disk1', REQUIRED],            # Disk file
    ['--disk2', REQUIRED],            # Disk file
    ['--diskmode', REQUIRED],         # Disk mode (e.g. thin)
    ['--domainname', REQUIRED],       # Set domain (Used with deploy for VCSA)
    ['--dry-run', BOOLEAN],           # Dryrun flag
    ['--email', REQUIRED],            # AWS ACL email
    ['--epel', REQUIRED],             # EPEL Mirror
    ['--empty', REQUIRED],            # Empty / Null value
    ['--enable', REQUIRED],           # Enable flag
    ['--environment', REQUIRED],      # Environment
    ['--events', REQUIRED],           # Events (KVM)
    ['--exportdir', REQUIRED],        # Export directory
    ['--extra-args', REQUIRED],       # Extra args (KVM)
    ['--features',  REQUIRED],        # Features (KVM)
    ['--file',  REQUIRED],            # File, eg ISO
    ['--filedir', REQUIRED],          # File / ISO Directory
    ['--files', REQUIRED],            # Set default files resolution entry, eg "dns, files"
    ['--filesystem', REQUIRED],       # Filesystem (KVM)
    ['--finish', REQUIRED],           # Jumpstart finish file
    ['--force',  BOOLEAN],            # Force mode
    ['--format', REQUIRED],           # AWS / Output disk format (e.g. VMDK, RAW, VHD)
    ['--from', REQUIRED],             # From
    ['--fusiondir', REQUIRED],        # VMware Fusion Directory
    ['--gateway', REQUIRED],          # Gateway IP
    ['--gwifname', REQUIRED],         # Gateway Interface name
    ['--gatewaynode', REQUIRED],      # Gateway Node
    ['--graphics', REQUIRED],         # Graphics (KVM)
    ['--grant', REQUIRED],            # AWS ACL grant
    ['--group', REQUIRED],            # AWS Group Name
    ['--guest', REQUIRED],            # Guest OS
    ['--headless', BOOLEAN],          # Headless mode for builds
    ['--help', BOOLEAN],              # Display usage information
    ['--home', REQUIRED],             # Set home directory
    ['--homefs', REQUIRED],           # Set home fs
    ['--homesize', REQUIRED],         # Set home fs size
    ['--host', REQUIRED],             # Type of host (e.g. Docker)
    ['--hostnet', REQUIRED],          # Host network
    ['--host-device', REQUIRED],      # Host device (e.g. KVM passthough)
    ['--hostdev', REQUIRED],          # Host device (KVM)
    ['--hostonlyip', REQUIRED],       # Hostonly IP
    ['--hosts', REQUIRED],            # Set default hosts resolution entry, eg "files"
    ['--hvm', BOOLEAN],               # HVM (KVM)
    ['--imagedir', REQUIRED],         # Base Image Directory
    ['--id', REQUIRED],               # AWS Instance ID
    ['--idmap', REQUIRED],            # ID map (KVM) 
    ['--import', BOOLEAN],            # Import (KVM)
    ['--info', REQUIRED],             # Used with info option
    ['--initrd-inject', REQUIRED],    # Inject initrd (KVM)
    ['--inputfile', REQUIRED],        # Input file (KVM)
    ['--install', REQUIRED],          # Install (KVM)
    ['--ifname', REQUIRED],           # Interface number / name
    ['--iothreads', REQUIRED],        # IO threads (KVM)
    ['--ip', REQUIRED],               # IP Address of client
    ['--ipfamily', REQUIRED],         # IP family (e.g. IPv4 or IPv6)
    ['--ips', REQUIRED],              # IP Addresses of client
    ['--isodir', REQUIRED],           # ISO Directory
    ['--ldomdir', REQUIRED],          # Base LDom Directory
    ['--jsonfile', REQUIRED],         # JSON file
    ['--karch', REQUIRED],            # Solaris Jumpstart karch
    ['--key', REQUIRED],              # AWS Key Name
    ['--keydir', REQUIRED],           # AWS Key Dir
    ['--keyfile', REQUIRED],          # AWS Keyfile
    ['--keymap', REQUIRED],           # Key map
    ['--keyname', REQUIRED],          # AWS Key name (defaults to region)
    ['--kvmgroup', REQUIRED],         # Set KVM group
    ['--kvmgid', REQUIRED],           # Set KVM gid
    ['--launchSecurity', REQUIRED],   # Launch Security (KVM)
    ['--license', REQUIRED],          # License key (e.g. ESX)
    ['--list', BOOLEAN],              # List items
    ['--livecd', BOOLEAN],            # Specify Live CD (Changes install method)
    ['--locale', REQUIRED],           # Select language/language (e.g. en_US)
    ['--localfs', REQUIRED],          # Set local fs 
    ['--localsize', REQUIRED],        # Set local fs size
    ['--logfs', REQUIRED],            # Set log fs
    ['--logsize', REQUIRED],          # Set log fs size
    ['--lxcdir', REQUIRED],           # Linux Container Directory
    ['--lxcimagedir', REQUIRED],      # Linux Image Directory
    ['--mac', REQUIRED],              # MAC Address
    ['--machine', REQUIRED],          # Solaris Jumpstart Machine file
    ['--masked', BOOLEAN],            # Mask passwords in output (WIP)
    ['--memballoon', REQUIRED],       # VM memory balloon
    ['--memdev', REQUIRED],           # Memdev (KVM)
    ['--memory', REQUIRED],           # VM memory size
    ['--memorybacking', REQUIRED],    # VM memory backing (KVM)
    ['--memtune', REQUIRED],          # VM memory tune (KVM)
    ['--metadata', REQUIRED],         # Metadata (KVM)
    ['--method', REQUIRED],           # Install method (e.g. Kickstart)
    ['--mirror', REQUIRED],           # Mirror / Repo
    ['--mirrordisk', BOOLEAN],        # Mirror disk as part of post install
    ['--mode', REQUIRED],             # Set mode to client or server
    ['--model', REQUIRED],            # Model
    ['--mountdir', REQUIRED],         # Mount point
    ['--name', REQUIRED],             # Client / AWS Name
    ['--nameserver', REQUIRED],       # Delete client or VM
    ['--net', REQUIRED],              # Default Solaris Network (Solaris 11) 
    ['--netbootdir', REQUIRED],       # Netboot directory (Solaris 11 tftpboot directory)
    ['--netmask', REQUIRED],          # Set netmask
    ['--network', REQUIRED],          # Network (KVM)
    ['--networkfile', REQUIRED],      # Network config file (KVM)
    ['--nic', REQUIRED],              # Default NIC
    ['--noautoconsole', BOOLEAN],     # No autoconsole (KVM)
    ['--nokeys', BOOLEAN],            # Don't copy SSH Keys
    ['--nosudo', BOOLEAN],            # Use sudo
    ['--noreboot', BOOLEAN],          # Don't reboot as part of post script (used for troubleshooting) 
    ['--nobuild', BOOLEAN],           # Create configs but don't build
    ['--reboot', BOOLEAN],            # Reboot as part of post script
    ['--nosuffix', BOOLEAN],          # Don't add suffix to AWS AMI names
    ['--novncdir', REQUIRED],         # NoVNC directory
    ['--number', REQUIRED],           # Number of AWS instances
    ['--object', REQUIRED],           # AWS S3 object
    ['--opencsw', REQUIRED],          # OpenCSW Mirror / Repo
    ['--os-type', REQUIRED],          # OS Type 
    ['--os-variant', REQUIRED],       # OS Variant 
    ['--output', REQUIRED],           # Output format (e.g. text/html)
    ['--outputfile', REQUIRED],       # Output file (KVM)
    ['--packages', REQUIRED],         # Specify additional packages to install
    ['--packer', REQUIRED],           # Packer binary
    ['--packerversion', REQUIRED],    # Packer version
    ['--panic', REQUIRED],            # Panic (KVM)
    ['--parallel', REQUIRED],         # Parallel (KVM)
    ['--param', REQUIRED],            # Set a parameter of a VM
    ['--paravirt', BOOLEAN],          # Paravirt (KVM)
    ['--perms', REQUIRED],            # AWS perms
    ['--pkgdir', REQUIRED],           # Base Package Directory
    ['--pm', REQUIRED],               # PM (KVM)
    ['--ports', REQUIRED],            # Port (makes to and from the same in the case of and IP rule)
    ['--post', REQUIRED],             # Post install configuration
    ['--prefix', REQUIRED],           # AWS S3 prefix
    ['--print-xml', REQUIRED],        # Print XML (KVM)
    ['--proto', REQUIRED],            # Protocol
    ['--publisher', REQUIRED],        # Set publisher information (Solaris AI)
    ['--publisherhost', REQUIRED],    # Publisher host
    ['--publisherport', REQUIRED],    # Publisher port
    ['--publisherurl', REQUIRED],     # Publisher URL
    ['--pxebootdir', REQUIRED],       # PXE boot dir
    ['--pxe', BOOLEAN],               # PXE (KVM)
    ['--qemu-commandline', REQUIRED], # Qemu commandline (KVM)
    ['--redirdev', REQUIRED],         # Redirdev (KVM)
    ['--release', REQUIRED],          # OS Release
    ['--region', REQUIRED],           # AWS Region
    ['--repo', REQUIRED],             # Set repository
    ['--repodir', REQUIRED],          # Base Repository Directory
    ['--restart', BOOLEAN],           # Re-start VM
    ['--resource', REQUIRED],         # Resource (KVM)
    ['--rng', REQUIRED],              # RNG (KVM)
    ['--rootdisk', REQUIRED],         # Set root device to install to
    ['--rootfs', REQUIRED],           # Set root fs
    ['--rootsize', REQUIRED],         # Set root device size in M
    ['--rootuser', REQUIRED],         # Set root user name
    ['--rootpassword', REQUIRED],     # Client root password
    ['--rpoolname', REQUIRED],        # Solaris rpool name
    ['--rules', REQUIRED],            # Solaris Jumpstart rules file
    ['--scratchfs', REQUIRED],        # Set root fs
    ['--scratchsize', REQUIRED],      # Set root device size in M
    ['--scriptname', REQUIRED],       # Set scriptname
    ['--search', REQUIRED],           # Search string
    ['--seclabel', REQUIRED],         # Seclabel (KVM)
    ['--secret', REQUIRED],           # AWS Secret Key
    ['--serial', BOOLEAN],            # Serial
    ['--sharedfolder', REQUIRED],     # Install shell (used for packer, e.g. winrm, ssh)
    ['--shell', REQUIRED],            # Install shell (used for packer, e.g. winrm, ssh)
    ['--size', REQUIRED],             # VM disk size (if used with deploy action, this sets the size of the VM, e.g. tiny)
    ['--server', REQUIRED],           # Server name/IP (allow execution of commands on a remote host, or deploy to)
    ['--serveradmin', REQUIRED],      # Admin username for server to deploy to
    ['--servernetwork', REQUIRED],    # Server network (used when deploying to a remote server)
    ['--servernetmask', REQUIRED],    # Server netmask (used when deploying to a remote server)
    ['--serverpassword', REQUIRED],   # Admin password of server to deploy to
    ['--service', REQUIRED],          # Service name
    ['--setup', REQUIRED],            # Setup script
    ['--share', REQUIRED],            # Shared folder
    ['--sitename', REQUIRED],         # Sitename for VCSA
    ['--smartcard', REQUIRED],        # Smartcard (KVM)
    ['--snapshot', REQUIRED],         # AWS snapshot
    ['--socker', REQUIRED],           # Socket file
    ['--sound', REQUIRED],            # Sound (KVM)
    ['--splitvols', BOOLEAN],         # Split volumes, e.g. seperate /, /var, etc
    ['--sshkeyfile', REQUIRED],       # SSH Keyfile
    ['--sshport', REQUIRED],          # SSH Port
    ['--ssopassword', REQUIRED],      # SSO password
    ['--stack', REQUIRED],            # AWS CF Stack
    ['--start', BOOLEAN],             # Start VM
    ['--strict', BOOLEAN],            # Ignore SSH keys
    ['--stop', BOOLEAN],              # Stop VM
    ['--sudo', BOOLEAN],              # Use sudo
    ['--sudogroup', REQUIRED],        # Set Sudo group
    ['--suffix', REQUIRED],           # AWS AMI Name suffix
    ['--sysid', REQUIRED],            # Solaris Jumpstart sysid file
    ['--sysinfo', REQUIRED],          # Sysinfo (KVM)
    ['--target', REQUIRED],           # AWS target format (e.g. citrix, vmware, windows)
    ['--techpreview', BOOLEAN],       # Test mode
    ['--terminal', REQUIRED],         # Terminal type
    ['--test', BOOLEAN],              # Test mode
    ['--tftpdir', REQUIRED],          # TFTP Directory
    ['--time', REQUIRED],             # Set time e.g. Eastern Standard Time
    ['--timeserver', REQUIRED],       # Set NTP server IP / Address
    ['--timezone', REQUIRED],         # Set timezone e.g. Australia/Victoria
    ['--tmpfs', REQUIRED],            # Set tmp fs
    ['--tmpsize', REQUIRED],          # Set tmp fs size
    ['--to', REQUIRED],               # To
    ['--tpm', REQUIRED],              # TPM (KVM)
    ['--transient', BOOLEAN],         # Transient (KVM)
    ['--trunk', REQUIRED],            # Mirror Trunk (e.g. stable)
    ['--type', REQUIRED],             # Install type (e.g. ISO, client, OVA, Network)
    ['--uid', REQUIRED],              # UID
    ['--unattended', BOOLEAN],        # Unattended (KVM)
    ['--unmasked', BOOLEAN],          # Unmask passwords in output (WIP)
    ['--usrfs', REQUIRED],            # Set usr fs
    ['--usrsize', REQUIRED],          # Set usr fs size
    ['--utc', REQUIRED],              # UTC off/on
    ['--value', REQUIRED],            # Set the value of a parameter
    ['--varfs', REQUIRED],            # Set var fs
    ['--varsize', REQUIRED],          # Set var fs size
    ['--vcpus', REQUIRED],            # Number of CPUs
    ['--verbose', BOOLEAN],           # Verbose mode
    ['--version', BOOLEAN],           # Display version information
    ['--video', BOOLEAN],             # Video (KVM)
    ['--virtdir', REQUIRED],          # Base Client Directory
    ['--virt-type', BOOLEAN],         # Virtualisation type (KVM)
    ['--vlanid',  REQUIRED],          # VLAN ID
    ['--vm',  REQUIRED],              # VM type
    ['--vmdir',  REQUIRED],           # VM Directory
    ['--vmdkfile', REQUIRED],         # VMDK file
    ['--vmnet',  REQUIRED],           # VM Network (e.g. vmnet1 or vboxnet0)
    ['--vmnetdhcp',  BOOLEAN],        # VM Network DHCP
    ['--vmgateway', REQUIRED],        # Set VM network gateway
    ['--vmnetwork', REQUIRED],        # Set network type (e.g. hostonly, bridged, nat)
    ['--vmnic',  REQUIRED],           # VM NIC (e.g. eth0)
    ['--vmtools', REQUIRED],          # Install VM tools or Guest Additions
    ['--vmxfile', REQUIRED],          # VMX file
    ['--vnc', BOOLEAN],               # Enable VNC mode
    ['--vncpassword', REQUIRED],      # VNC password
    ['--vsock',  REQUIRED],           # vSock (KVM)
    ['--vswitch',  REQUIRED],         # vSwitch
    ['--wait', REQUIRED],             # Wait (KVM)
    ['--watchdog', REQUIRED],         # Watchdog (KVM)
    ['--workdir', REQUIRED],          # Base Work Directory
    ['--yes', REQUIRED],              # Answer yes to questions
    ['--zone', REQUIRED],             # Zone file
    ['--zonedir', REQUIRED],          # Base Zone Directory
    ['--zpool', REQUIRED]             # Boot zpool name
  )
rescue
  options['output'] = 'text'
  options['stdout'] = []
  print_help(options)
  quit(options)
end

# Handle alternate options

[ "list", "create", "delete", "start", "stop", "restart", "build" ].each do |switch|
  if options[switch] == true 
    options['action'] = switch
  end
end

# Handle import

if options['import'] == true
  if options['vm']
    if not options['vm'].to_s.match(/kvm/)
      options['action'] = "import" 
    end
  else
    options['action'] = "import" 
  end
end

# Set up question associative array

options['q_struct'] = {}
options['q_order']  = []

options['i_struct'] = {}
options['i_order']  = []

options['u_struct'] = {}
options['u_order']  = []

options['g_struct'] = {}
options['g_order']  = []

# Handle method switch

if options['method'] != options['empty']
  options['method'] = options['method'].downcase
  options['method'] = options['method'].gsub(/vsphere/,"vs")
  options['method'] = options['method'].gsub(/jumpstart/,"js")
  options['method'] = options['method'].gsub(/kickstart/,"ks")
  options['method'] = options['method'].gsub(/preseed/,"ps")
  options['method'] = options['method'].gsub(/cloudinit|cloudconfig|subiquity/,"ci")
end

# Set up some initital defaults

options['stdout']  = []

# Print help before anything if required

if options['help']
  options['output'] = 'text'
  print_help(options)
  quit(options)
end

# Print version

if options['version']
  options['output'] = 'text'
  print_version(options)
  quit(options)
end

# Get defaults

defaults = {}
defaults = set_defaults(options,defaults)
defaults['stdout'] = []

# Check valid values

raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
raw_params.each do |raw_param|
  if raw_param.match(/\[/) && !raw_param.match(/^raw_params/)
    raw_param   = raw_param.split(/--/)[1].split(/'/)[0]
    valid_param = "valid-"+raw_param
    if options[raw_param]
      if defaults[valid_param]
        test_value = options[raw_param][0]
        if test_value.match(/\,/)
          test_value = test_value.split(",")[0]
        end
        if !defaults[valid_param].to_s.downcase.match(/#{test_value.downcase}/)
          handle_output(defaults, "Warning:\tOption --#{raw_param} has an invalid value: #{options[raw_param]}")
          handle_output(defaults, "Information:\tValid values for --#{raw_param} are: \n #{defaults[valid_param].to_s}")
          quit(defaults)
        end
      end
    end
  end
end

# If we've been given a file try to get os and other insformation from file

if options['file'].to_s.match(/[A-Z]|[a-z]|[0-9]/) && !options['action'].to_s.match(/list/)
  options['host-os-name'] = defaults['host-os-name']
  options['sudo']   = defaults['sudo']
  if !options['mountdir']
    options['mountdir'] = defaults['mountdir']
  end
  if !options['output']
    options['output'] = defaults['output']
  end
  options['executehost'] = defaults['executehost']
  if options['file'] != defaults['empty']
    options = get_install_service_from_file(options)
  end
end

# Set SSH port

options = set_ssh_port(options)

# Reset defaults based on updated options

defaults = reset_defaults(options,defaults)

# Process options based on defaults

raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
raw_params.each do |raw_param|
  if raw_param.match(/\[/) && !raw_param.match(/stdout|^raw_params/)
    raw_param = raw_param.split(/--/)[1].split(/'/)[0]
    if !options[raw_param]
      if defaults[raw_param].to_s.match(/[A-Z]|[a-z]|[0-9]/)
        options[raw_param] = defaults[raw_param]
      else
        options[raw_param] = defaults['empty']
      end
    end
    if options['verbose'] == true
      options['output'] = "text"
      handle_output(options,"Information:\tSetting option #{raw_param} to #{options[raw_param]}")
    end
  end
end

# Do a final check through defaults

defaults.each do |param, value|
  if !options[param]
    options[param] = defaults[param]
    if options['verbose'] == true
      options['output'] = "text"
      handle_output(options,"Information:\tSetting option #{param} to #{options[param]}")
    end
  end
  if options['action'] == "info" 
    if options['info'].match(/os/)
      if param.match(/^os/)
        options['verbose'] = true
        handle_output(options,"Information:\tParameter #{param} is #{options[param]}")
        options['verbose'] = false
      end
    end
  end
end

# Check some actions - We may be able to process without action switch

[ "info", "check" ].each do |action|
  if options['action'] == options['empty']
    if options[action] != options['empty']
      options['action'] = action
    end
  end
end

# Do some more checks

if options['vm'] != options['empty']
  if options['action'].to_s.match(/create/)
    if options['dhcp'] == false
      if options['file'] != options['empty']
        if options['type'] != "service"
          if options['ip'] == options['empty']
            if !options['vmnetwork'].to_s.match(/nat/)
              handle_output(options,"Warning:\tNo IP specified and DHCP not specified")
              quit(options)
            end
          end
        end
      end
    end
  end
end

# Set some local configuration options like DHCP files etc

options = set_local_config(options)

# Clean up options

options = cleanup_options(options,defaults)

# Create required directories

check_dir_exists(options,options['workdir'])
[ options['isodir'], options['repodir'], options['imagedir'], options['pkgdir'], options['clientdir'] ].each do |dir_name|
  check_zfs_fs_exists(options,dir_name)
end

# Handle setup

if options['setup'] != options['empty']
  if !File.exist?(options['setup'])
    handle_output(options,"Warning:\tSetup script '#{options['setup']}' not found")
    quit(options)
  end
end

# Handle IPs option

if options['ips']
  if options['ips'].to_s.match(/[0-9]/)
    options['ip'] = options['ips']
  end
end

# If using AWS check for and load AWS CLI gem
# Removed this from the default check as it takes a long time to install

if options['vm']
  if options['vm'].to_s.match(/aws/)
    begin
      require 'aws-sdk'
    rescue LoadError
      install_gem("aws-sdk")
    end
  end
end

# Check directory permissions perms by default

if options['action'].to_s.match(/check/) && options['check'].to_s.match(/perm|dir/) 
  check_perms(options)
  quit(options)
end

# Handle base ISO dir when dir option set

if options['action'] == "list" && options['type'].to_s.match(/iso|img|image/) && options['dir']
  options['isodir'] = options['dir']
end

# Make sure a VM type is set for ansible

if options['type'].to_s.match(/ansible|packer/)
  if options['vm'] == options['empty']
    handle_output(options,"Warning:\tNo VM type specified")
    quit(options)
  end
end

# Check packer is installed and is latest version

if options['type'].to_s.match(/packer/)
  options = check_packer_is_installed(options)
end

# Prime HTML

if options['output'].to_s.match(/html/)
  options['stdout'].push("<html>")
  options['stdout'].push("<head>")
  options['stdout'].push("<title>#{options['scriptname']}</title>")
  options['stdout'].push("</head>")
  options['stdout'].push("<body>")
end

# Handle keyfile switch

if options['keyfile'] != options['empty']
  if !File.exist?(options['keyfile'])
    handle_output(options,"Warning:\tKey file #{options['keyfile']} does not exist")
    if options['action'].to_s.match(/create/) and !option['type'].to_s.match(/key/)
      quit(options)
    end
  end
end

# Handle sshkeyfile switch

if options['sshkeyfile'] != options['empty']
  if !File.exist?(options['sshkeyfile'])
    handle_output(options,"Warning:\tKey file #{options['sshkeyfile']} does not exist")
    if options['action'].to_s.match(/create/) and !option['type'].to_s.match(/key/)
      quit(options)
    end
  end
end

# Handle AWS credentials

if options['vm'] != options['empty']
  if options['vm'].to_s.match(/aws/)
    if options['creds']
      options['access'],options['secret'] = get_aws_creds(options)
    else
      if ENV['AWS_ACCESS_KEY']
        options['access'] = ENV['AWS_ACCESS_KEY']
      end
      if ENV['AWS_SECRET_KEY']
        options['secret'] = ENV['AWS_SECRET_KEY']
      end
      if !options['secret'] || !options['access']
        options['access'],options['secret'] = get_aws_creds(options)
      end
    end
    if options['access'] == options['empty'] || options['secret'] == options['empty']
      handle_output(options,"Warning:\tAWS Access and Secret Keys not found")
      quit(options)
    else
      if !File.exist?(options['creds'])
        create_aws_creds_file(options)
      end
    end
  end
end

# Handle client name switch

if options['name'] != options['empty']
  check_hostname(options)
  if options['verbose'] == true
    handle_output(options,"Setting:\tClient name to #{options['name']}")
  end
end

# If specified admin set admin user

if options['adminuser'] == options['empty']
  if options['action']
    if options['action'].to_s.match(/connect|ssh/)
      if options['vm']
        if options['vm'].to_s.match(/aws/)
          options['adminuser'] = options['awsuser']
        else
          options['adminuser'] = %x[whoami].chomp
        end
      else
        if options['id']
          options['adminuser'] = options['awsuser']
        else
          options['adminuser'] = %x[whoami].chomp
        end
      end
    end
  else
    options['adminuser'] = %x[whoami].chomp
  end
end

# Change VM disk size

if options['size'] != options['empty']
  options['size'] = options['size']
  if !options['size'].to_s.match(/G$/)
    options['size'] = options['size'] + "G"
  end
end

# Get MAC address if specified

if options['mac'] != options['empty']
  if !options['vm']
    options['vm'] = "none"
  end
  options['mac'] = check_install_mac(options)
  if options['verbose'] == true
     handle_output(options,"Information:\tSetting client MAC address to #{options['mac']}")
  end
else
  options['mac'] = ""
end

# Handle architecture switch

 if options['arch'] != options['empty']
   options['arch'] = options['arch'].downcase
   if options['arch'].to_s.match(/sun4u|sun4v/)
     options['arch'] = "sparc"
   end
   if options['os-type'].to_s.match(/vmware/)
     options['arch'] = "x86_64"
   end
   if options['os-type'].to_s.match(/bsd/)
     options['arch'] = "i386"
   end
 end

# Handle install shell

if options['shell'] == options['empty']
  if options['os-type'].to_s.match(/win/)
    options['shell'] = "winrm"
  else
    options['shell'] = "ssh"
  end
end

# Handle vm switch

if options['vm'] != options['empty']
  options['vm'] = options['vm'].gsub(/virtualbox/,"vbox")
  options['vm'] = options['vm'].gsub(/mp/,"multipass")
  if options['vm'].to_s.match(/aws/)
    if options['service'] == options['empty']
      options['service'] = $default_aws_type
    end
  end
end

# Handle share switch

if options['share'] != options['empty']
  if !File.directory?(options['share'])
    handle_output(options,"Warning:\tShare point #{options['share']} doesn't exist")
    quit(options)
  end
  if options['mount'] == options['empty']
    options['mount'] = File.basename(options['share'])
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tSharing #{options['share']}")
    handle_output(options,"Information:\tSetting mount point to #{options['mount']}")
  end
end

# Get Timezone

if options['timezone'] == options['empty']
  if options['os-type'] != options['empty']
    if options['os-type'].to_s.match(/win/)
     options['timezone'] = options['time']
    else
      options['timezone'] = options['timezone']
    end
  end
end

# Handle clone swith

if options['clone'] == options['empty']
  if options['action'] == "snapshot"
    clone_date = %x[date].chomp.downcase.gsub(/ |:/,"_")
    options['clone'] = options['name'] + "-" + clone_date
  end
  if options['verbose'] == true && options['clone']
    handle_output(options,"Information:\tSetting clone name to #{options['clone']}")
  end
end

# Handle option size

if !options['size'] == options['empty']
  if options['type'].to_s.match(/vcsa/)
    if !options['size'].to_s.match(/[0-9]/)
      options['size'] = $default_vcsa_size
    end
  end
else
  if !options['vm'].to_s.match(/aws/) && !options['type'].to_s.match(/cloud|cf|stack/)
    if options['type'].to_s.match(/vcsa/)
      options['size'] = $default_vcsa_size
    else
      options['size'] = options['size']
    end
  end
end

# Try to determine install method when give just an ISO

if options['file'] != options['empty']
  if options['vm'] == "vbox" && options['file'] == "tools"
    options['file'] = options['vboxadditions']
  end
  if !options['action'].to_s.match(/download/)
    if !File.exist?(options['file']) && !options['file'].to_s.match(/^http/)
      handle_output(options,"Warning:\tFile #{options['file']} does not exist")
      if !options['test'] == true
        quit(options)
      end
    end
  end
  if options['action'].to_s.match(/deploy/)
    if options['type'] == options['empty']
      options['type'] = get_install_type_from_file(options)
    end
  end
  if options['file'] != options['empty'] && options['action'].to_s.match(/create|add/)
    if options['method'] == options['empty']
      options['method'] = get_install_method_from_iso(options)
      if options['method'] == nil
        handle_output(options,"Could not determine install method")
        quit(options)
      end
    end
    if options['type'] == options['empty']
      options['type'] = get_install_type_from_file(options)
      if options['verbose'] == true
        handle_output(options,"Information:\tSetting install type to #{options['type']}")
      end
    end
  end
end

# Handle values and parameters

if options['param'] != options['empty']
  if !options['action'].to_s.match(/get/)
    if !options['value']
      handle_output(options,"Warning:\tSetting a parameter requires a value")
      quit(options)
    else
      if !options['value']
        handle_output(options,"Warning:\tSetting a parameter requires a value")
        quit(options)
      end
    end
  end
end

if options['value'] != options['empty']
  if options['param'] == options['empty']
    handle_output(options,"Warning:\tSetting a value requires a parameter")
    quit(options)
  end
end

# Handle LDoms

if options['method'] != options['empty']
  if options['method'].to_s.match(/dom/)
    if options['method'].to_s.match(/cdom/)
      options['mode'] = "server"
      options['vm']   = "cdom"
      if options['verbose'] == true
        handle_output(options,"Information:\tSetting mode to server")
        handle_output(options,"Information:\tSetting vm to cdrom")
      end
    else
      if options['method'].to_s.match(/gdom/)
        options['mode'] = "client"
        options['vm']   = "gdom"
        if options['verbose'] == true
          handle_output(options,"Information:\tSetting mode to client")
          handle_output(options,"Information:\tSetting vm to gdom")
        end
      else
        if options['method'].to_s.match(/ldom/)
          if options['name'] != options['empty']
            options['method'] = "gdom"
            options['vm']     = "gdom"
            options['mode']   = "client"
            if options['verbose'] == true
              handle_output(options,"Information:\tSetting mode to client")
              handle_output(options,"Information:\tSetting method to gdom")
              handle_output(options,"Information:\tSetting vm to gdom")
            end
          else
            handle_output(options,"Warning:\tCould not determine whether to run in server of client mode")
            quit(options)
          end
        end
      end
    end
  else
    if options['mode'].to_s.match(/client/)
      if options['vm'] != options['empty']
        if options['method'].to_s.match(/ldom|gdom/)
          options['vm'] = "gdom"
        end
      end
    else
      if options['mode'].to_s.match(/server/)
        if options['vm'] != options['empty']
          if options['method'].to_s.match(/ldom|cdom/)
            options['vm'] = "cdom"
          end
        end
      end
    end
  end
else
  if options['mode'] != options['empty']
    if options['vm'].to_s.match(/ldom/)
      if options['mode'].to_s.match(/client/)
        options['vm']     = "gdom"
        options['method'] = "gdom"
        if options['verbose'] == true
          handle_output(options,"Information:\tSetting method to gdom")
          handle_output(options,"Information:\tSetting vm to gdom")
        end
      end
      if options['mode'].to_s.match(/server/)
        options['vm']     = "cdom"
        options['method'] = "cdom"
        if options['verbose'] == true
          handle_output(options,"Information:\tSetting method to cdom")
          handle_output(options,"Information:\tSetting vm to cdom")
        end
      end
    end
  end
end

# Handle Packer and VirtualBox not supporting hostonly or bridged network

if !options['vmnetwork'].to_s.match(/nat/)
  if options['vm'].to_s.match(/virtualbox|vbox/)
    if options['type'].to_s.match(/packer/) || options['method'].to_s.match(/packer/) && !options['action'].to_s.match(/delete|import/)
      handle_output(options,"Warning:\tPacker has a bug that causes issues with Hostonly and Bridged network on VirtualBox")
      handle_output(options,"Warning:\tTo deal with this an addition port may be added to the SSH daemon config file")
    end
  end
end

# Set default host only Information

if !options['vm'] == options['empty']
  if options['vmnetwork'] == "hostonly" || options['vmnetwork'] == options['empty'] 
    options['vmnetwork'] = "hostonly"
    options = set_hostonly_info(options)
  end
end

# Check action when set to build or import

if options['action'].to_s.match(/build|import/)
  if options['type'] == options['empty']
    handle_output(options,"Information:\tSetting Install Service to Packer")
    options['type'] = "packer"
  end
  if options['vm'] == options['empty']
    if options['name'] == options['empty']
      handle_output(options,"Warning:\tNo client name specified")
      quit(options)
    end
    options['vm'] = get_client_vm_type_from_packer(options)
  end
  if options['vm'] == options['empty']
    handle_output(options,"Warning:\tVM type not specified")
    quit(options)
  else
    if !options['vm'].to_s.match(/vbox|fusion|aws|kvm|parallels|qemu/)
      handle_output(options,"Warning:\tInvalid VM type specified")
      quit(options)
    end
  end
end

if options['ssopassword'] != options['empty']
  options['adminpassword'] = options['ssopassword']
end

# Get Netmask

if options['netmask'] == options['empty']
  if options['type'].to_s.match(/vcsa/)
    options['netmask'] = $default_cidr
  end
end

# # Handle deploy

if options['action'].to_s.match(/deploy/)
  if options['type'] == options['empty']
    options['type'] = "esx"
  end
  if options['type'].to_s.match(/esx|vcsa/)
    if options['serverpassword'] == options['empty']
      options['serverpassword'] = options['rootpassword']
    end
    check_ovftool_exists
    if options['type'].to_s.match(/vcsa/)
      if options['file'] == options['empty']
        handle_output(options,"Warning:\tNo deployment image file specified")
        quit(options)
      end
      check_password(options)
      check_password(options)
    end
  end
end

# Handle console switch

if options['console'] != options['empty']
  case options['console']
  when /x11/
    options['text'] = false
  when /serial/
    options['serial'] = true
    options['text']   = true
  when /headless/
    options['headless'] = true
  else
    options['text'] = true
  end
else
  options['console'] = "text"
  options['text']    = false
end

# Handle list option for action switch

if options['action'].to_s.match(/list|info/)
  if options['file'] && !options['file'] == options['empty']
    describe_file(options)
    quit(options)
  else
    if options['vm'] == options['empty'] && options['service'] == options['empty'] && options['method'] == options['empty'] && options['type'] == options['empty'] && options['mode'] == options['empty']
      handle_output(options,"Warning:\tNo type or service specified")
    end
  end
end

# Handle action switch

if options['action'] != options['empty']
  if options['action'].to_s.match(/delete/) && options['service'] == options['empty']
    if options['vm'] == options['empty'] && options['type'] != options['empty']
      options['vm'] = get_client_vm_type_from_packer(options)
    else
      if options['type'] != options['empty'] && options['vm'] == options['empty']
        if options['type'].to_s.match(/packer/)
          if options['name'] != options['empty']
            options['vm'] = get_client_vm_type_from_packer(options)
          end
        end
      end
    end
  end
  if options['action'].to_s.match(/migrate|deploy/)
    if options['action'].to_s.match(/deploy/)
      if options['type'].to_s.match(/vcsa/)
        options['vm'] = "fusion"
      else
        options['type']   =get_install_type_from_file(options)
        if options['type'].to_s.match(/vcsa/)
          options['vm'] = "fusion"
        end
      end
    end
    if options['vm'] == options['empty']
      handle_output(options,"Information:\tVirtualisation method not specified, setting virtualisation method to VMware")
      options['vm'] = "vm"
    end
    if options['server'] == options['empty'] || options['ip'] == options['empty']
      handle_output(options,"Warning:\tRemote server hostname or IP not specified")
      quit(options)
    end
  end
end

# Get additional information from install file if required

if options['type'].to_s.match(/vcsa|packer/)
  if options['service'] == options['empty'] || options['os-type'] == options['empty'] || options['method'] == options['empty'] || options['release'] == options['empty'] || options['arch'] == options['empty'] || options['label'] == options['empty']
    if options['file'] != options['empty']
      options = get_install_service_from_file(options)
    end
  end
end

# Handle install service switch

if options['service'] != options['empty']
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting install service to #{options['service']}")
  end
  if options['type'].to_s.match(/^packer$/)
    check_packer_is_installed(options)
    options['mode']    = "client"
    if options['method'] == options['empty'] && options['os-type'] == options['empty'] && !options['action'].to_s.match(/build|list|import|delete/) && !options['vm'].to_s.match(/aws/)
      handle_output(options,"Warning:\tNo OS, or Install Method specified for build type #{options['service']}")
      quit(options)
    end
    if options['vm'] == options['empty'] && !options['action'].to_s.match(/list/)
      handle_output(options,"Warning:\tNo VM type specified for build type #{options['service']}")
      quit(options)
    end
    if options['name'] == options['empty'] && !options['action'].to_s.match(/list/) && !options['vm'].to_s.match(/aws/)
      handle_output(options,"Warning:\tNo Client name specified for build type #{options['service']}")
      quit(options)
    end
    if options['file'] == options['empty'] && !options['action'].to_s.match(/build|list|import|delete/) && !options['vm'].to_s.match(/aws/)
      handle_output(options,"Warning:\tNo ISO file specified for build type #{options['service']}")
      quit(options)
    end
    if !options['ip'].to_s.match(/[0-9]/) && !options['action'].to_s.match(/build|list|import|delete/) && !options['vm'].to_s.match(/aws/)
      if options['vmnetwork'].to_s.match(/hostonly/)
        options = set_hostonly_info(options)
        handle_output(options,"Information:\tNo IP Address specified, setting to #{options['ip']} ")
      else
        handle_output(options,"Warning:\tNo IP Address specified ")
      end
    end
    if !options['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/) && !options['action'].to_s.match(/build|list|import|delete/)
      handle_output(options,"Warning:\tNo MAC Address specified")
      handle_output(options,"Information:\tGenerating MAC Address")
      if options['vm'] != options['empty']
        if options['vm'] != options['empty']
          options['mac'] = generate_mac_address(options)
        else
          options['mac'] = generate_mac_address(options)
        end
      else
        options['mac'] = generate_mac_address(options)
      end
    end
  end
else
  if options['type'].to_s.match(/vcsa|packer/)
    if options['type'].to_s.match(/^packer$/)
      check_packer_is_installed(options)
      options['mode'] = "client"
      if options['method'] == options['empty'] && options['os-type'] == options['empty'] && !options['action'].to_s.match(/build|list|import|delete/)
        handle_output(options,"Warning:\tNo OS, or Install Method specified for build type #{options['service']}")
        quit(options)
      end
      if options['vm'] == options['empty'] && !options['action'].to_s.match(/list/)
        handle_output(options,"Warning:\tNo VM type specified for build type #{options['service']}")
        quit(options)
      end
      if options['name'] == options['empty'] && !options['action'].to_s.match(/list/)
        handle_output(options,"Warning:\tNo Client name specified for build type #{options['service']}")
        quit(options)
      end
      if options['file'] == options['empty'] && !options['action'].to_s.match(/build|list|import|delete/)
        handle_output(options,"Warning:\tNo ISO file specified for build type #{options['service']}")
        quit(options)
      end
      if !options['ip'].to_s.match(/[0-9]/) && !options['action'].to_s.match(/build|list|import|delete/) && !options['vmnetwork'].to_s.match(/nat/)
        if options['vmnetwork'].to_s.match(/hostonly/)
          options = set_hostonly_info(options)
          handle_output(options,"Information:\tNo IP Address specified, setting to #{options['ip']} ")
        else
          handle_output(options,"Warning:\tNo IP Address specified ")
          quit(options)
        end
      end
      if !options['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/) && !options['action'].to_s.match(/build|list|import|delete/)
        handle_output(options,"Warning:\tNo MAC Address specified")
        handle_output(options,"Information:\tGenerating MAC Address")
        if options['vm'] == options['empty']
          options['vm'] = "none"
        end
        options['mac'] = generate_mac_address(options)
      end
    end
  else
    options['service'] = ""
  end
end

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

if options['action'].to_s.match(/import/)
  if options['file'] == options['empty'] && options['service'] == options['empty'] && !options['type'].to_s.match(/packer/)
    vm_types       = [ "fusion", "vbox" ]
    exists         = []
    vm_exists      = ""
    vm_type        = ""
    vm_types.each do |vm_type|
      exists = check_packer_vm_image_exists(options,vm_type)
      if exists[0].to_s.match(/yes/)
        options['type'] = "packer"
        options['vm']   = vm_type
        vm_exists      = "yes"
      end
    end
    if !vm_exists.match(/yes/)
      handle_output(options,"Warning:\tNo install file, type or service specified")
      quit(options)
    end
  end
end

# Handle release switch

if options['release'].to_s.match(/[0-9]/)
  if options['type'].to_s.match(/packer/) && options['action'].to_s.match(/build|delete|import/)
    options['release'] = ""
  else
    if options['vm'] == options['empty']
      options['vm'] = "none"
    end
    if options['vm'].to_s.match(/zone/) && options['host-os-release'].match(/10|11/) && !options['release'].to_s.match(/10|11/)
      handle_output(options,"Warning:\tInvalid release number: #{options['release']}")
      quit(options)
    end
#    if !options['release'].to_s.match(/[0-9]/) || options['release'].to_s.match(/[a-z,A-Z]/)
#      puts "Warning:\tInvalid release number: " + options['release']
#      quit(options)
#    end
  end
else
  if options['vm'].to_s.match(/zone/)
    options['release'] = options['host-os-release']
  else
    options['release'] = options['empty']
  end
end
if options['verbose'] == true && options['release']
  handle_output(options,"Information:\tSetting Operating System version to #{options['release']}")
end

# Handle empty OS option

if options['os-type'] == options['empty']
  if options['vm'] != options['empty']
    if options['action'].to_s.match(/add|create/)
      if options['method'] == options['empty']
        if !options['vm'].to_s.match(/ldom|cdom|gdom|aws|mp|multipass/) && !options['type'].to_s.match(/network/)
          handle_output(options,"Warning:\tNo OS or install method specified when creating VM")
          quit(options)
        end
      end
    end
  end
end

# Handle memory switch

if options['memory'] == options['empty']
  if options['vm'] != options['empty']
    if options['os-type'].to_s.match(/vs|esx|vmware|vsphere/) || options['method'].to_s.match(/vs|esx|vmware|vsphere/)
      options['memory'] = "4096"
    end
    if options['os-type'] != options['empty']
      if options['os-type'].to_s.match(/sol/)
        if options['release'].to_i > 9
          options['memory'] = "2048"
        end
      end
    else
      if options['method'] == "ai"
        options['memory'] = "2048"
      end
    end
  end
end

# Get/set publisher port (Used for configuring AI server)

if options['host-os-name'].to_s.match(/SunOS/) and !options['publisher'] == options['empty']
  if options['mode'].to_s.match(/server/) || options['type'].to_s.match(/service/)
    options['publisherhost'] = options['publisher']
    if options['publisherhost'].to_s.match(/:/)
      (options['publisherhost'],options['publisherport']) = options['publisherhost'].split(/:/)
    end
    handle_output(options,"Information:\tSetting publisher host to #{options['publisherhost']}")
    handle_output(options,"Information:\tSetting publisher port to #{options['publisherport']}")
  else
    if options['mode'] == "server" || options['file'].to_s.match(/repo/)
      if options['host-os-name'] == "SunOS"
        options['mode'] = "server"
        options = check_local_config(options)
        options['publisherhost'] = options['hostip']
        options['publisherport'] = $default_ai_port
        if options['verbose'] == true
          handle_output(options,"Information:\tSetting publisher host to #{options['publisherhost']}")
          handle_output(options,"Information:\tSetting publisher port to #{options['publisherport']}")
        end
      end
    else
      if options['vm'] == options['empty']
        if options['action'].to_s.match(/create/)
          options['mode'] = "server"
          options = check_local_config(options)
        end
      else
        options['mode'] = "client"
        options = check_local_config(options)
      end
      options['publisherhost'] = options['hostip']
    end
  end
end

# If service is set, but method and os isn't specified, try to set method from service name

if options['service'] != options['empty'] && options['method'] == options['empty'] && options['os-type'] == options['empty']
  options['method'] = get_install_method_from_service(options)
else
  if options['method'] == options['empty'] && options['os-type'] == options['empty']
    options['method'] = get_install_method_from_service(options)
  end
end

# Handle VM switch

if options['vm'] != options['empty']
  options['mode'] = "client"
  options = check_local_config(options)
  case options['vm']
  when /parallels/
    options['status'] = check_parallels_is_installed(options)
    handle_vm_install_status(options)
    options['vm']  = "parallels"
    options['sudo'] = false
    options['size'] = options['size'].gsub(/G/,"000")
    if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      options['hostonlyip'] = "10.211.55.1"
      options['vmgateway']  = "10.211.55.1"
    else
      options['hostonlyip'] = "192.168.55.1"
      options['vmgateway']  = "192.168.55.1"
    end
  when /multipass|mp/
    options['vm'] = "multipass"
    if options['os-name'].to_s.match(/Darwin/)
      options = check_vbox_is_installed(options)
      options['hostonlyip'] = "192.168.64.1"
      options['vmgateway']  = "192.168.64.1"
    end
    check_multipass_is_installed(options)
  when /virtualbox|vbox/
    options = check_vbox_is_installed(options)
    handle_vm_install_status(options)
    options['vm']   = "vbox"
    options['sudo'] = false
    options['size'] = options['size'].gsub(/G/,"000")
    options['hostonlyip'] = "192.168.56.1"
    options['vmgateway']  = "192.168.56.1"
  when /kvm/
    options['status'] = check_kvm_is_installed(options)
    handle_vm_install_status(options)
    options['hostonlyip'] = "192.168.122.1"
    options['vmgateway']  = "192.168.122.1"
  when /vmware|fusion/
    handle_vm_install_status(options)
    check_fusion_vm_promisc_mode(options)
    options['sudo']  = false
    options['vm']    = "fusion"
  when /zone|container|lxc/
    if options['host-os-name'].to_s.match(/SunOS/)
      options['vm'] = "zone"
    else
      options['vm'] = "lxc"
    end
  when /ldom|cdom|gdom/
    if $os_arch.downcase.match(/sparc/) && options['host-os-name'].to_s.match(/SunOS/)
      if options['release'] == options['empty']
        options['release']   = options['host-os-release']
      end
      if options['host-os-release'].match(/10|11/)
        if options['mode'].to_s.match(/client/)
          options['vm'] = "gdom"
        end
        if options['mode'].to_s.match(/server/)
          options['vm'] = "cdom"
        end
      else
        handle_output(options,"Warning:\tLDoms require Solaris 10 or 11")
      end
    else
      handle_output(options,"Warning:\tLDoms require Solaris on SPARC")
      quit(options)
    end
  end
  if !options['valid-vm'].to_s.downcase.match(/#{options['vm'].to_s}/) && !options['action'].to_s.match(/list/)
    print_valid_list(options,"Warning:\tInvalid VM type",options['valid-vm'])
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting VM type to #{options['vm']}")
  end
else
  options['vm'] = "none"
end

if options['vm'] != options['empty'] || options['method'] != options['empty']
  if options['model'] != options['empty']
    options['model'] = options['model'].downcase
  else
    if options['arch'].to_s.match(/i386|x86|x86_64|x64|amd64/)
      options['model'] = "vmware"
    else
      options['model'] = ""
    end
  end
  if options['verbose'] == true && options['model']
    handle_output(options,"Information:\tSetting model to #{options['model']}")
  end
end

# Check OS switch

if options['os-type'] == options['empty'] || options['method'] == options['empty'] || options['release'] == options['empty'] || options['arch'] == options['empty']
  if !options['file'] == options['empty']
    options = get_install_service_from_file(options)  
  end
end

if options['os-type'] != options['empty']
  case options['os-type']
  when /suse|sles/
    options['method'] = "ay"
  when /vsphere|esx|vmware/
    options['method'] = "vs"
  when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
    options['method'] = "ks"
  when /ubuntu|debian/
    if options['file'].to_s.match(/cloudimg/)
      options['method'] = "ci"
    else
      options['method'] = "ps"
    end
  when /purity/
    options['method'] = "ps"
    if options['memory'].to_s.match(/#{options['memory']}/)
      options['vcpus'] = "2"
      if options['release'].to_s.match(/^5\.2/)
        options['memory'] = "12288"
      else
        options['memory'] = "8192"
      end
      options['memory'] = options['memory']
      options['vcpus']  = options['vcpus']
    end
  when /sol/
    if options['release'].to_i < 11
      options['method'] = "js"
    else
      options['method'] = "ai"
    end
  end
end

# Handle install method switch

if options['method'] != options['empty']
  case options['method']
  when /cloud/
    info_examples     = "ci"
    options['method'] = "ci"
  when /suse|sles|yast|ay/
    info_examples     = "ay"
    options['method'] = "ay"
    when /autoinstall|ai/
    info_examples     = "ai"
    options['method'] = "ai"
  when /kickstart|redhat|rhel|fedora|sl_|scientific|ks|centos/
    info_examples     = "ks"
    options['method'] = "ks"
  when /jumpstart|js/
    info_examples     = "js"
    options['method'] = "js"
  when /preseed|debian|ubuntu|purity/
    info_examples     = "ps"
    options['method'] = "ps"
  when /vsphere|esx|vmware|vs/
    info_examples     = "vs"
    options['method'] = "vs"
    if options['memory'] == options['memory']
      options['memory'] = "4096"
    end
    if options['vcpus'] == options['vcpus']
      options['vcpus'] = "2"
    end
    options['controller']= "ide"
  when /bsd|xb/
    info_examples     = "xb"
    options['method'] = "xb"
  end
end

# Try to determine install method if only specified OS

if options['method'] == options['empty'] && !options['action'].to_s.match(/delete|running|reboot|restart|halt|shutdown|boot|stop|deploy|migrate|show|connect/)
  case options['os-type']
  when /sol|sunos/
    if options['release'].to_s.match(/[0-9]/)
      if options['release'] == "11"
        options['method'] = "ai"
      else
        options['method'] = "js"
      end
    end
  when /ubuntu|debian/
    options['method'] = "ps"
  when /suse|sles/
    options['method'] = "ay"
  when /redhat|rhel|scientific|sl|centos|fedora|vsphere|esx/
    options['method'] = "ks"
  when /bsd/
    options['method'] = "xb"
  when /vmware|esx|vsphere/
    options['method'] = "vs"
    configure_vmware_esxi_defaults
  when "windows"
    options['method'] = "pe"
  else
    if !options['action'].to_s.match(/list|info|check/)
      if !options['action'].to_s.match(/add|create/) && options['vm'] == options['empty']
        print_valid_list(options,"Warning:\tInvalid OS specified",options['valid-os'])
      end
    end
  end
end

# Handle gateway if not empty

if options['vmgateway'] != options['empty']
  options['vmgateway'] = options['vmgateway']
else
  if options['vmnetwork'] == "hostonly"
  end
end

# Do a check to see if we are running Packer and trying to install Windows with network in non NAT mode

if options['type'].to_s.match(/packer/) && options['os-type'].to_s.match(/win/)
  if !options['vmnetwork'].to_s.match(/nat/)
    handle_output(options,"Warning:\tPacker only supports installing Windows with a NAT network")
    handle_output(options,"Information:\tSetting network to NAT mode")
    options['vmnetwork'] = "nat"
  end
  options['shell'] = "winrm"
end

# Handle VM named none

if options['action'].to_s.match(/create/) && options['name'] == "none" && options['mode'] != "server" and options['type'] != "service"
  handle_output(options,"Warning:\tInvalid client name")
  quit(options)
end

# Check we have a setup file for purity

if options['os-type'] == "purity"
  if options['setup'] == options['empty']
    handle_output(options,"Warning:\tNo setup file specified")
    quit(options)
  end
end

# Handle action switch

if options['action'] != options['empty']
  case options['action']
  when /convert/
    if options['vm'].to_s.match(/kvm|qemu/)
      convert_kvm_image(options)
    end
  when /check/
    if options['mode'].to_s.match(/server/)
      options = check_local_config(options)
    end
    if options['mode'].to_s.match(/osx/)
      check_osx_dnsmasq(options)
      check_osx_tftpd(options)
      check_osx_dhcpd(options)
    end
    if options['vm'].to_s.match(/fusion|vbox|kvm/)
      check_vm_network(options)
    end
    if options['check'].to_s.match(/dhcp/)
      check_dhcpd_config(options)
    end
    if options['check'].to_s.match(/tftp/)
      check_tftpd_config(options)
    end
  when /execute|shell/
    if options['type'].to_s.match(/docker/) or options['vm'].to_s.match(/docker/)
      execute_docker_command(options)
    end
    if options['vm'].to_s.match(/mp|multipass/)
      execute_multipass_command(options)
    end
  when /screen/
    if options['vm'] != options['empty']
      get_vm_screen(options)
    end
  when /vnc/
    if options['vm'] != options['empty']
      vnc_to_vm(options)
    end
  when /status/
    if options['vm'] != options['empty']
      status = get_vm_status(options)
    end
  when /set|put/
    if options['type'].to_s.match(/acl/)
      if options['bucket'] != options['empty']
        set_aws_s3_bucket_acl(options)
      end
    end
  when /upload|download/
    if options['bucket'] != options['empty']
      if options['action'].to_s.match(/upload/)
        upload_file_to_aws_bucket(options)
      else
        download_file_from_aws_bucket(options)
      end
    end
  when /display|view|show|prop|get|billing/
    if options['type'].to_s.match(/acl|url/) || options['action'].to_s.match(/acl|url/)
      if options['bucket'] != options['empty']
        show_aws_s3_bucket_acl(options)
      else
        if options['type'].to_s.match(/url/) || options['action'].to_s.match(/url/)
          show_s3_bucket_url(options)
        else
          get_aws_billing(options)
        end
      end
    else
      if options['name'] != options['empty']
        if options['vm'] != options['empty']
          show_vm_config(options)
        else
          get_client_config(options)
        end
      end
    end
  when /help/
    print_help(options)
  when /version/
    print_version
  when /info|usage|help/
    if options['file'] != options['empty']
      describe_file(options)
    else
      print_examples(options)
    end
  when /show/
    if options['vm'] != options['empty']
      show_vm_config(options)
    end
  when /list/
    if options['file'] != options['empty']
      describe_file(options)
    end
    case options['type']
    when /service/
      list_services(options)
    when /network/
      show_vm_network(options)
    when /ssh/
      list_user_ssh_config(options)
    when /image|ami/
      list_images(options)
    when /packer|ansible/
      list_clients(options)
      quit(options)
    when /inst/
      if options['vm'].to_s.match(/docker/)
        list_docker_instances(options)
      else
        list_aws_instances(options)
      end
    when /bucket/
      list_aws_buckets(options)
    when /object/
      list_aws_bucket_objects(options)
    when /snapshot/
      if options['vm'].to_s.match(/aws/)
        list_aws_snapshots(options)
      else
        list_vm_snapshots(options)
      end
    when /key/
      list_aws_key_pairs(options)
    when /stack|cloud|cf/
      list_aws_cf_stacks(options)
    when /securitygroup/
      list_aws_security_groups(options)
    else
      if options['vm'].to_s.match(/docker/)
        if options['type'].to_s.match(/instance/)
          list_docker_instances(options)
        else
          list_docker_images(options)
        end
        quit(options)
      end
      if options['type'].to_s.match(/service/) || options['mode'].to_s.match(/server/)
        if options['method'] != options['empty']
          list_services(options)
        else
          list_all_services(options)
        end
        quit(options)
      end
      if options['type'].to_s.match(/iso/)
        if options['method'] != options['empty']
          list_isos(options)
        else
          list_os_isos(options)
        end
        quit(options)
      end
      if options['mode'].to_s.match(/client/) || options['type'].to_s.match(/client/)
        options['mode'] = "client"
        check_local_config(options)
        if options['service'] != options['empty']
          if options['service'].to_s.match(/[a-z]/)
            list_clients(options)
          end
        end
        if options['vm'] != options['empty']
          if options['vm'].to_s.match(/[a-z]/)
            if options['type'] == options['empty']
              if options['file'] != options['empty']
                describe_file(options)
              else
                list_vms(options)
              end
            end
          end
        end
        quit(options)
      end
      if options['method'] != options['empty'] && options['vm'] == options['empty']
        list_clients(options)
        quit(options)
      end
      if options['type'].to_s.match(/ova/)
        list_ovas
        quit(options)
      end
      if options['vm'] != options['empty'] && options['vm'] != options['empty']
        if options['type'].to_s.match(/snapshot/)
          list_vm_snapshots(options)
        else
          list_vm(options)
        end
        quit(options)
      end
    end
  when /delete|remove|terminate/
    if options['type'].to_s.match(/network|snapshot/) && options['vm'] != options['empty']
      if options['type'].to_s.match(/network/)
        delete_vm_network(options)
      else
        delete_vm_snapshot(options)
      end
      quit(options)
    end
    if options['type'].to_s.match(/ssh/)
      delete_user_ssh_config(options)
      quit(options)
    end
    if options['name'] != options['empty']
      if options['vm'].to_s.match(/docker/)
        delete_docker_image(options)
        quit(options)
      end
      if options['service'] == options['empty'] && options['vm'] == options['empty']
        if options['vm'] == options['empty']
          options['vm'] = get_client_vm_type(options)
          if options['vm'].to_s.match(/vbox|fusion|parallels|mp|multipass/)
            options['sudo'] = false
            delete_vm(options)
          else
            handle_output(options,"Warning:\tNo VM, client or service specified")
            handle_output(options,"Available services")
            list_all_services(options)
          end
        end
      else
        if options['vm'].to_s.match(/fusion|vbox|parallels|aws|kvm/)
          if options['type'].to_s.match(/packer|ansible/)
            unconfigure_client(options)
          else
            if options['type'].to_s.match(/snapshot/)
              if options['name'] != options['empty'] && options['snapshot'] != options['empty']
                delete_vm_snapshot(options)
              else
                handle_output(options,"Warning:\tClient name or snapshot not specified")
              end
            else
              delete_vm(options)
            end
          end
        else
          if options['vm'].to_s.match(/ldom|gdom/)
            unconfigure_gdom(options)
          else
            if options['vm'].to_s.match(/mp|multipass/)
              delete_multipass_vm(options)
              quit(options)
            else
              remove_hosts_entry(options)
              remove_dhcp_client(options)
              if options['yes'] == true
                delete_client_dir(options)
              end
            end
          end
        end
      end
    else
      if options['type'].to_s.match(/instance|snapshot|key|stack|cf|cloud|securitygroup|iprule|sg|ami|image/) || options['id'].to_s.match(/[0-9]|all/)
        case options['type']
        when /instance/
          options = delete_aws_vm(options)
        when /ami|image/
          if options['vm'].to_s.match(/docker/)
            delete_docker_image(options)
          else
            delete_aws_image(options)
          end
        when /snapshot/
          if options['vm'].to_s.match(/aws/)
            delete_aws_snapshot(options)
          else
            if options['snapshot'] == options['empty']
              handle_output(options,"Warning:\tNo snapshot name specified")
              if options['name'] == options['empty']
                handle_output(options,"Warning:\tNo client name specified")
                list_all_vm_snapshots(options)
              else
                list_vm_snapshots(options)
              end
            else
              if options['name'] == options['empty'] && options['snapshot'] == options['empty']
                handle_output(options,"Warning:\tNo client or snapshot name specified")
                quit(options)
              else
                delete_vm_snapshot(options)
              end
            end
          end
        when /key/
          options = delete_aws_key_pair(options)
        when /stack|cf|cloud/
          delete_aws_cf_stack(options)
        when /securitygroup/
          delete_aws_security_group(options)
        when /iprule/
          if options['ports'].to_s.match(/[0-9]/)
            if options['ports'].to_s.match(/\./)
              ports = []
              options['ports'].split(/\./).each do |port|
                ports.push(port)
              end
              ports = ports.uniq
            else
              port  = options['ports']
              ports = [ port ]
            end
            ports.each do |port|
              options['from'] = port
              options['to']   = port
              remove_rule_from_aws_security_group(options)
            end
          else
            remove_rule_from_aws_security_group(options)
          end
        else
          if options['ami'] != options['empty']
            delete_aws_image(options)
          else
            handle_output(options,"Warning:\tNo #{options['vm']} type, instance or image specified")
          end
        end
        quit(options)
      end
      if options['type'].to_s.match(/packer|docker/)
        unconfigure_client(options)
      else
        if options['service'] != options['empty']
          if options['method'] == options['empty']
            unconfigure_server(options)
          else
            unconfigure_server(options)
          end
        end
      end
    end
  when /build/
    if options['type'].to_s.match(/packer/)
      if options['vm'].to_s.match(/aws/)
        build_packer_aws_config(options)
      else
        build_packer_config(options)
      end
    end
    if options['type'].to_s.match(/ansible/)
      if options['vm'].to_s.match(/aws/)
        build_ansible_aws_config(options)
      else
        build_ansible_config(options)
      end
    end
  when /add|create/
    if options['vm'].to_s.match(/mp|multipass/)
      configure_multipass_vm(options)
      quit(options)
    end
    if options['type'] == options['empty'] && options['vm'] == options['empty'] && options['service'] == options['empty']
      handle_output(options,"Warning:\tNo service type or VM specified")
      quit(options)
    end
    if options['type'].to_s.match(/service/) && !options['service'].to_s.match(/[a-z]/) && !options['service'] == options['empty']
      handle_output(options,"Warning:\tNo service name specified")
      quit(options)
    end
    if options['file'] == options['empty']
      options['mode'] = "client"
    end
    if options['type'].to_s.match(/network/) && options['vm'] != options['empty']
      add_vm_network(options)
      quit(options)
    end
    if options['type'].to_s.match(/ami|image|key|cloud|cf|stack|securitygroup|iprule|sg/)
      case options['type']
      when /ami|image/
        create_aws_image(options)
      when /key/
        options = create_aws_key_pair(options)
      when /cf|cloud|stack/
        configure_aws_cf_stack(options)
      when /securitygroup/
        create_aws_security_group(options)
      when /iprule/
        if options['ports'].to_s.match(/[0-9]/)
          if options['ports'].to_s.match(/\./)
            ports = []
            options['ports'].split(/\./).each do |port|
              ports.push(port)
            end
            ports = ports.uniq
          else
            port  = options['ports']
            ports = [ port ]
          end
          ports.each do |port|
            options['from'] = port
            options['to']   = port
            add_rule_to_aws_security_group(options)
          end
        else
          add_rule_to_aws_security_group(options)
        end
      end
      quit(options)
    end
    if options['vm'].to_s.match(/aws/)
      case options['type']
      when /packer/
        configure_packer_aws_client(options)
      when /ansible/
        configure_ansible_aws_client(options)
      else
        if options['key'] == options['empty'] && options['group'] == options['empty']
          handle_output(options,"Warning:\tNo Key Pair or Security Group specified")
          quit(options)
        else
          options = configure_aws_client(options)
        end
      end
      quit(options)
    end
    if options['type'].to_s.match(/docker/)
      configure_docker_client(options)
      quit(options)
    end
    if options['vm'].to_s.match(/kvm/)
      configure_kvm_client(options)
      quit(options)
    end
    if options['vm'] == options['empty'] && options['method'] == options['empty'] && options['type'] == options['empty'] && !options['mode'].to_s.match(/server/)
      handle_output(options,"Warning:\tNo VM, Method or specified")
    end
    if options['mode'].to_s.match(/server/) || options['type'].to_s.match(/service/) && options['file'] != options['empty'] && options['vm'] == options['empty'] && !options['type'].to_s.match(/packer/) && !options['service'].to_s.match(/packer/)
      options['mode'] = "server"
      options = check_local_config(options)
      if options['host-os'].to_s.match(/Docker/)
        configure_docker_server(options)
      end
      if options['method'] == "none"
        if options['service'] != "none"
          options['method'] = get_method_from_service(options)
        end
      end
      configure_server(options)
    else
      if options['vm'].to_s.match(/fusion|vbox|kvm|mp|multipass/)
        check_vm_network(options)
      end
      if options['name'] != options['empty']
        if options['service'] != options['empty'] || options['type'].to_s.match(/packer/)
          if options['method'] == options['empty']
            options['method'] = get_install_method(options)
          end
          if !options['type'].to_s.match(/packer/) && options['vm'] == options['empty']
            check_dhcpd_config(options)
          end
          if !options['vmnetwork'].to_s.match(/nat/) && !options['action'].to_s.match(/add/)
            if !options['type'].to_s.match(/pxe/)
              check_install_ip(options)
            end
            check_install_mac(options)
          end
          if options['type'].to_s.match(/packer/)
            if options['yes'] == true
              if options['vm'] == options['empty']
                options['vm'] = get_client_vm_type(options)
                if options['vm'].to_s.match(/vbox|fusion|parallels/)
                  options['sudo'] = false
                  delete_vm(options)
                  unconfigure_client(options)
                end
              else
                options['sudo'] = false
                delete_vm(options)
                unconfigure_client(options)
              end
            end
            configure_client(options)
          else
            if options['vm'] == options['empty']
              if options['method'] == options['empty']
                if options['ip'].to_s.match(/[0-9]/)
                  options['mode'] = "client"
                  options = check_local_config(options)
                  add_hosts_entry(options)
                end
                if options['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
                  options['service'] = ""
                  add_dhcp_client(options)
                end
              else
                if options['model'] == options['empty']
                  options['model'] = "vmware"
                  options['slice'] = "4192"
                end
                options['mode'] = "server"
                options = check_local_config(options)
                if !options['mac'].to_s.match(/[0-9]/)
                  options['mac'] = generate_mac_address(options)
                end
                configure_client(options)
              end
            else
              if options['vm'].to_s.match(/fusion|vbox|parallels/) && !options['action'].to_s.match(/add/)
                create_vm(options)
              end
              if options['vm'].to_s.match(/zone|lxc|gdom/)
                eval"[configure_#{options['vm']}(options)]"
              end
              if options['vm'].to_s.match(/cdom/)
                configure_cdom(options)
              end
            end
          end
        else
          if options['vm'].to_s.match(/fusion|vbox|parallels/)
            create_vm(options)
          end
          if options['vm'].to_s.match(/zone|lxc|gdom/)
            eval"[configure_#{options['vm']}(options)]"
          end
          if options['vm'].to_s.match(/cdom/)
            configure_cdom(options)
          end
          if options['vm'] == options['empty']
            if options['ip'].to_s.match(/[0-9]/)
              options['mode'] = "client"
              options = check_local_config(options)
              add_hosts_entry(options)
            end
            if options['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
              options['service'] = ""
              add_dhcp_client(options)
            end
          end
        end
      else
        if options['mode'].to_s.match(/server/)
          if options['method'].to_s.match(/ai/)
            configure_ai_server(options)
          else
            handle_output(options,"Warning:\tNo install method specified")
          end
        else
          handle_output(options,"Warning:\tClient or service name not specified")
        end
      end
    end
  when /^boot$|^stop$|^halt$|^shutdown$|^suspend$|^resume$|^start$|^destroy$/
    options['mode']   = "client"
    options['action'] = options['action'].gsub(/start/,"boot")
    options['action'] = options['action'].gsub(/halt/,"stop")
    options['action'] = options['action'].gsub(/shutdown/,"stop")
    if options['vm'].to_s.match(/aws/)
      options = boot_aws_vm(options)
      quit(options)
    end
    if options['name'] != options['empty'] && options['vm'] != options['empty'] && options['vm'] != options['empty']
      eval"[#{options['action']}_#{options['vm']}_vm(options)]"
    else
      if options['name'] != options['empty'] && options['vm'] == options['empty']
        options['vm'] = get_client_vm_type(options)
        options = check_local_config(options)
        if options['vm'].to_s.match(/vbox|fusion|parallels/)
          options['sudo'] = false
        end
        if options['vm'] != options['empty']
          control_vm(options)
        end
      else
        if options['name'] != options['empty']
          for vm_type in options['valid-vm']
            options['vm'] = vm_type
            exists = check_vm_exists(options)
            if exists == "yes"
              control_vm(options)
            end
          end
        else
          if options['name'] == options['empty']
            handle_output(options,"Warning:\tClient name not specified")
          end
        end
      end
    end
  when /restart|reboot/
    if options['service'] != options['empty']
      eval"[restart_#{options['service']}]"
    else
      if options['vm'] == options['empty'] && options['name'] != options['empty']
        options['vm'] = get_client_vm_type(options)
      end
      if options['vm'].to_s.match(/aws/)
        options = reboot_aws_vm(options)
        quit(options)
      end
      if options['vm'] != options['empty']
        if options['name'] != options['empty']
          stop_vm(options)
          boot_vm(options)
        else
          handle_output(options,"Warning:\tClient name not specified")
        end
      else
        if options['name'] != options['empty']
          for vm_type in options['valid-vm']
            options['vm'] = vm_type
            exists = check_vm_exists(options)
            if exists == "yes"
              stop_vm(options)
              boot_vm(options)
              quit(options)
            end
          end
        else
          handle_output(options,"Warning:\tInstall service or VM type not specified")
        end
      end
    end
  when /import/
    if options['file'] == options['empty']
      if options['type'].to_s.match(/packer/)
        import_packer_vm(options)
      end
    else
      if options['vm'].to_s.match(/fusion|vbox|kvm/)
        if options['file'].to_s.match(/ova/)
          if !options['vm'].to_s.match(/kvm/)
            set_ovfbin
          end
          import_ova(options)
        else
          if options['file'].to_s.match(/vmdk/)
            import_vmdk(options)
          end
        end
      end
    end
  when /export/
    if options['vm'].to_s.match(/fusion|vbox/)
      eval"[export_#{options['vm']}_ova(options)]"
    end
    if options['vm'].to_s.match(/aws/)
      export_aws_image(options)
    end
  when /clone|copy/
    if options['clone'] != options['empty'] && options['name'] != options['empty']
      eval"[clone_#{options['vm']}_vm(options)]"
    else
      handle_output(options,"Warning:\tClient name or clone name not specified")
    end
  when /running|stopped|suspended|paused/
    if options['vm'] != options['empty'] && options['vm'] != options['empty']
      eval"[list_#{options['action']}_#{options['vm']}_vms]"
    end
  when /crypt/
    options['crypt'] = get_password_crypt(options)
    handle_output(options,"")
  when /post/
    eval"[execute_#{options['vm']}_post(options)]"
  when /change|modify/
    if options['name'] != options['empty']
      if options['memory'].to_s.match(/[0-9]/)
        eval"[change_#{options['vm']}_vm_mem(options)]"
      end
      if options['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
        eval"[change_#{options['vm']}_vm_mac(options)]"
      end
    else
      handle_output(options,"Warning:\tClient name not specified")
    end
  when /attach/
    if options['vm'] != options['empty'] && options['vm'] != options['empty']
      eval"[attach_file_to_#{options['vm']}_vm(options)]"
    end
  when /detach/
    if options['vm'] != options['empty'] && options['name'] != options['empty'] && options['vm'] != options['empty']
      eval"[detach_file_from_#{options['vm']}_vm(options)]"
    else
      handle_output(options,"Warning:\tClient name or virtualisation platform not specified")
    end
  when /share/
    if options['vm'] != options['empty'] && options['vm'] != options['empty']
      eval"[add_shared_folder_to_#{options['vm']}_vm(options)]"
    end
  when /^snapshot|clone/
    if options['vm'] != options['empty'] && options['vm'] != options['empty']
      if options['name'] != options['empty']
        eval"[snapshot_#{options['vm']}_vm(options)]"
      else
        handle_output(options,"Warning:\tClient name not specified")
      end
    end
  when /migrate/
    eval"[migrate_#{options['vm']}_vm(options)]"
  when /deploy/
    if options['type'].to_s.match(/vcsa/)
      set_ovfbin
      options['file'] = handle_vcsa_ova(options)
      deploy_vcsa_vm(options)
    else
      eval"[deploy_#{options['vm']}_vm(options)]"
    end
  when /restore|revert/
    if options['vm'] != options['empty'] && options['vm'] != options['empty']
      if options['name'] != options['empty']
        eval"[restore_#{options['vm']}_vm_snapshot(options)]"
      else
        handle_output(options,"Warning:\tClient name not specified")
      end
    end
  when /set/
    if options['vm'] != options['empty']
      eval"[set_#{options['vm']}_value(options)]"
    end
  when /get/
    if options['vm'] != options['empty']
      eval"[get_#{options['vm']}_value(options)]"
    end
  when /console|serial|connect|ssh/
    if options['vm'].to_s.match(/kvm/)
      connect_to_kvm_vm(options)
    end
    if options['vm'].to_s.match(/aws/) || options['id'].to_s.match(/[0-9]/)
      connect_to_aws_vm(options)
      quit(options)
    end
    if options['type'].to_s.match(/docker/)
      connect_to_docker_client(options)
    end
    if options['vm'] != options['empty'] && options['vm'] != options['empty']
      if options['name'] != options['empty']
        connect_to_virtual_serial(options)
      else
        handle_output(options,"Warning:\tClient name not specified")
      end
    end
  else
    handle_output(options,"Warning:\tAction #{options['method']}")
  end
end

quit(options)
