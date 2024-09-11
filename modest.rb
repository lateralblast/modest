#!/usr/bin/env ruby

# Name:         modest (Multi OS Deployment Engine Server Tool)
# Version:      7.9.4
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
require 'etc'

# Declare array for text output (used for webserver)

values = {}
values['stdout']   = []
values['q_struct'] = {}
values['q_order']  = []

# Handle output

def handle_output(values, text)
  if values['output'].to_s.match(/html/)
    if text == ""
      text = "<br>"
    end
  end
  if values['output'].to_s.match(/text/)
    puts text
  end
  #values['stdout'].push(text)
  return values
end

# If given --verbose switch enable verbose mode early

if ARGV.to_s.match(/verbose/)
  values['verbose'] = true
  values['output'] = "text"
end

class String
  def strip_control_characters
    chars.each_with_object do |char, str|
      str << char unless char.ascii_only? && (char.ord < 32 || char.ord == 127)
    end
  end
  def strip_control_and_extended_characters
    chars.each_with_object do |char, str|
      str << char if char.ascii_only? && char.ord.between?(32, 226)
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

# Load methods

if File.directory?("./methods")
  file_list = Dir.glob("./methods/**/*")
  for file in file_list
    if file =~ /rb$/
      handle_output(values, "Information:\tLoading module #{file}")
      require "#{file}"
    end
  end
end

# Get command line arguments
# Print help if specified none

if !ARGV[0]
  values['output'] = 'text'
  print_help(values)
end

# Check whether we have any single - values

for option in ARGV
  if option.match(/^-[a-z]/)
    puts "Invalid option #{option} in command line"
    exit
  end
end

# Try to make sure we have valid long switches

valid_values = get_valid_values

ARGV[0..-1].each do |switch|
  if !valid_values.grep(/--#{switch}/) || switch.match(/^-[a-z,A-Z][a-z,A-Z]/)
    handle_output(values, "Invalid command line option: #{switch}")
    values['output'] = 'text'
    quit(values)
  end
end

# Process values

include Getopt

begin
  values = Long.getopts(
    ['--accelerator', REQUIRED],      # Packer accelerator
    ['--access', REQUIRED],           # AWS Access Key
    ['--acl', REQUIRED],              # AWS ACL
    ['--action', REQUIRED],           # Action (e.g. boot, stop, create, delete, list, etc)
    ['--admingid', REQUIRED],         # Admin user GID for client VM to be created
    ['--admingroup', REQUIRED],       # Admin user Group for client VM to be created
    ['--adminhome', REQUIRED],        # Admin user Home directory for client VM to be created
    ['--adminshell', REQUIRED],       # Admin user shell for client VM to be created
    ['--adminsudo', REQUIRED],        # Admin sudo command for client VM to be created
    ['--adminuid', REQUIRED],         # Admin user UID for client VM to be created
    ['--adminuser', REQUIRED],        # Admin username for client VM to be created
    ['--adminpassword', REQUIRED],    # Client admin password
    ['--aidir', REQUIRED],            # Solaris AI Directory
    ['--aiport', REQUIRED],           # Solaris AI Port
    ['--ami', REQUIRED],              # AWS AMI ID
    ['--arch', REQUIRED],             # Architecture of client or VM (e.g. x86_64)
    ['--audio', REQUIRED],            # Audio
    ['--auditsize', REQUIRED],        # Set audit fs size
    ['--auditfs', REQUIRED],          # Set audit fs
    ['--autostart', BOOLEAN],         # Autostart (KVM)
    ['--autoyastfile', REQUIRED],     # AutoYaST file
    ['--awsuser', REQUIRED],          # AWS User
    ['--baserepodir', REQUIRED],      # Base repository directory
    ['--bename', REQUIRED],           # ZFS BE (Boot Environment) name
    ['--biosdevnames', BOOLEAN],      # Use biosdevnames (e.g. eth0 instead of eno1)
    ['--biostype', REQUIRED],         # BIOS boot type (bios/uefi)
    ['--blkiotune', REQUIRED],        # Block IO tune (KVM)
    ['--boot', REQUIRED],             # Set boot device
    ['--bootfs', REQUIRED],           # Set boot fs
    ['--bootcommand', REQUIRED],      # Packer Boot command
    ['--bootproto', REQUIRED],        # Set boot protocol
    ['--bootsize', REQUIRED],         # Set boot fs size
    ['--bootwait', REQUIRED],         # Packer Boot wait
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
    ['--cloudinitfile', REQUIRED],    # Cloud init config file (KVM)
    ['--command', REQUIRED],          # Run command
    ['--comment', REQUIRED],          # Comment
    ['--configfile', REQUIRED],       # Config file (KVM)
    ['--connect', REQUIRED],          # Connect (KVM)
    ['--console', REQUIRED],          # Select console type (e.g. text, serial, x11) (default is text)
    ['--container', BOOLEAN],         # AWS AMI export container
    ['--containertype', REQUIRED],    # AWS AMI export container
    ['--controller', REQUIRED],       # Specify disk controller
    ['--copykeys', BOOLEAN],          # Copy SSH Keys (default)
    ['--country', REQUIRED],          # Country
    ['--cpu', REQUIRED],              # Type of CPU (e.g. KVM CPU type)
    ['--cputune', REQUIRED],          # CPU tune (KVM)
    ['--create', BOOLEAN],            # Create client / service
    ['--creds', REQUIRED],            # Credentials file
    ['--crypt', REQUIRED],            # Password crypt
    ['--datastore', REQUIRED],        # Datastore to deploy to on remote server
    ['--defaults', BOOLEAN],          # Answer yes to all questions (accept defaults)
    ['--delete', BOOLEAN],            # Delete client / service
    ['--desc', REQUIRED],             # Description
    ['--destory-on-exit', BOOLEAN],   # Destroy on exit (KVM)
    ['--dhcp', BOOLEAN],              # DHCP
    ['--dhcpdfile', REQUIRED],        # DHCP Config file
    ['--dhcpdrange', REQUIRED],       # Set DHCP range
    ['--dir', REQUIRED],              # Directory / Direction
    ['--disk', REQUIRED],             # Disk file
    ['--disk1', REQUIRED],            # Disk file
    ['--disk2', REQUIRED],            # Disk file
    ['--disksize', REQUIRED],         # Packer Disk size
    ['--diskinterface', REQUIRED],    # Disk interface
    ['--dnsmasq', BOOLEAN],           # Update / Check DNSmasq
    ['--diskmode', REQUIRED],         # Disk mode (e.g. thin)
    ['--domainname', REQUIRED],       # Set domain (Used with deploy for VCSA)
    ['--dry-run', BOOLEAN],           # Dryrun flag
    ['--dryrun', BOOLEAN],            # Dryrun flag
    ['--email', REQUIRED],            # AWS ACL email
    ['--empty', REQUIRED],            # Empty / Null value
    ['--enable', REQUIRED],           # Enable flag
    ['--enableethernet', BOOLEAN],    # Enable ethernet flag
    ['--enablevhv', BOOLEAN],         # Enable VHV flag
    ['--enablevnc', BOOLEAN],         # Enable VNC flag
    ['--environment', REQUIRED],      # Environment
    ['--epel', REQUIRED],             # EPEL Mirror
    ['--ethernetdevice', REQUIRED],   # Ethernet device (e.g. e1000)
    ['--events', REQUIRED],           # Events (KVM))
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
    ['--gatewaynode', REQUIRED],      # Gateway Node
    ['--graphics', REQUIRED],         # Graphics (KVM)
    ['--grant', REQUIRED],            # AWS ACL grant
    ['--group', REQUIRED],            # AWS Group Name
    ['--guest', REQUIRED],            # Guest OS
    ['--gwifname', REQUIRED],         # Gateway Interface name
    ['--headless', BOOLEAN],          # Headless mode for builds
    ['--help', BOOLEAN],              # Display usage information
    ['--home', REQUIRED],             # Set home directory
    ['--homefs', REQUIRED],           # Set home fs
    ['--homesize', REQUIRED],         # Set home fs size
    ['--host', REQUIRED],             # Type of host (e.g. Docker)
    ['--hostdev', REQUIRED],          # Host device (KVM)
    ['--hostnet', REQUIRED],          # Host network
    ['--hostonlyip', REQUIRED],       # Hostonly IP
    ['--hosts', REQUIRED],            # Set default hosts resolution entry, eg "files"
    ['--host-device', REQUIRED],      # Host device (e.g. KVM passthough)
    ['--httpbindaddress', REQUIRED],  # Packer HTTP bind address
    ['--httpdirectory', REQUIRED],    # Packer HTTP directory
    ['--httpportmax', REQUIRED],      # Packer HTTP port max
    ['--httpportmin', REQUIRED],      # Packer HTTP port min
    ['--hvm', BOOLEAN],               # HVM (KVM)
    ['--hwversion', REQUIRED],        # VMware Hardware Version
    ['--hwvirtex', REQUIRED],         # hwvirtex (on/off)
    ['--id', REQUIRED],               # AWS Instance ID
    ['--idmap', REQUIRED],            # ID map (KVM)
    ['--ifname', REQUIRED],           # Interface number / name
    ['--imagedir', REQUIRED],         # Base Image Directory
    ['--import', BOOLEAN],            # Import (KVM)
    ['--info', REQUIRED],             # Used with info option
    ['--initrd-inject', REQUIRED],    # Inject initrd (KVM)
    ['--inputfile', REQUIRED],        # Input file (KVM)
    ['--install', REQUIRED],          # Install (KVM)
    ['--installdrivers', BOOLEAN],    # Install Drivers
    ['--installsecurity', BOOLEAN],   # Install Security Updates
    ['--installupdates', BOOLEAN],    # Install Package Updates
    ['--installupgrades', BOOLEAN],   # Install Package Upgrades
    ['--iothreads', REQUIRED],        # IO threads (KVM)
    ['--ip', REQUIRED],               # IP Address of client
    ['--ipfamily', REQUIRED],         # IP family (e.g. IPv4 or IPv6)
    ['--ips', REQUIRED],              # IP Addresses of client
    ['--isochecksum', REQUIRED],      # Packer ISO checksum
    ['--isodir', REQUIRED],           # ISO Directory
    ['--isourl', REQUIRED],           # Packer ISO URL
    ['--ldomdir', REQUIRED],          # Base LDom Directory
    ['--jsonfile', REQUIRED],         # JSON file
    ['--karch', REQUIRED],            # Solaris Jumpstart karch
    ['--kernel', REQUIRED],           # Kernel
    ['--key', REQUIRED],              # AWS Key Name
    ['--keydir', REQUIRED],           # AWS Key Dir
    ['--keyfile', REQUIRED],          # AWS Keyfile
    ['--keymap', REQUIRED],           # Key map
    ['--keyname', REQUIRED],          # AWS Key name (defaults to region)
    ['--kickstartfile', REQUIRED],    # Kickstart file
    ['--kvmgid', REQUIRED],           # Set KVM gid
    ['--kvmgroup', REQUIRED],         # Set KVM group
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
    ['--mouse', REQUIRED],            # Mouse
    ['--name', REQUIRED],             # Client / AWS Name
    ['--nameserver', REQUIRED],       # Delete client or VM
    ['--net', REQUIRED],              # Default Solaris Network (Solaris 11)
    ['--netbootdir', REQUIRED],       # Netboot directory (Solaris 11 tftpboot directory)
    ['--netbridge', REQUIRED],        # Packer Net bridge
    ['--netdevice', REQUIRED],        # Packer Net device
    ['--netmask', REQUIRED],          # Set netmask
    ['--network', REQUIRED],          # Network (KVM)
    ['--networkfile', REQUIRED],      # Network config file (KVM)
    ['--nic', REQUIRED],              # Default NIC
    ['--noautoconsole', BOOLEAN],     # No autoconsole (KVM)
    ['--noboot', BOOLEAN],            # Create VM/configs but don't boot
    ['--nobuild', BOOLEAN],           # Create VM/configs but don't build
    ['--nokeys', BOOLEAN],            # Don't copy SSH Keys
    ['--noreboot', BOOLEAN],          # Don't reboot as part of post script (used for troubleshooting)
    ['--nosudo', BOOLEAN],            # Use sudo
    ['--nosuffix', BOOLEAN],          # Don't add suffix to AWS AMI names
    ['--novncdir', REQUIRED],         # NoVNC directory
    ['--number', REQUIRED],           # Number of AWS instances
    ['--object', REQUIRED],           # AWS S3 object
    ['--opencsw', REQUIRED],          # OpenCSW Mirror / Repo
    ['--options', REQUIRED],          # Options
    ['--os-info', REQUIRED],          # OS Info
    ['--os-type', REQUIRED],          # OS Type
    ['--os-variant', REQUIRED],       # OS Variant
    ['--output', REQUIRED],           # Output format (e.g. text/html)
    ['--outputdirectory', REQUIRED],  # Packer output directory
    ['--outputfile', REQUIRED],       # Output file (KVM)
    ['--packages', REQUIRED],         # Specify additional packages to install
    ['--packer', REQUIRED],           # Packer binary
    ['--packersshport', REQUIRED],    # Packer binary
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
    ['--postscript', REQUIRED],       # Post install script
    ['--preseedfile', REQUIRED],      # Preseed file
    ['--prefix', REQUIRED],           # AWS S3 prefix
    ['--preservesources', BOOLEAN],   # Preserve Sources List
    ['--print-xml', REQUIRED],        # Print XML (KVM)
    ['--proto', REQUIRED],            # Protocol
    ['--publisher', REQUIRED],        # Set publisher information (Solaris AI)
    ['--publisherhost', REQUIRED],    # Publisher host
    ['--publisherport', REQUIRED],    # Publisher port
    ['--publisherurl', REQUIRED],     # Publisher URL
    ['--pxe', BOOLEAN],               # PXE (KVM)
    ['--pxebootdir', REQUIRED],       # PXE boot dir
    ['--qemu-commandline', REQUIRED], # Qemu commandline (KVM)
    ['--reboot', BOOLEAN],            # Reboot as part of post script
    ['--redirdev', REQUIRED],         # Redirdev (KVM)
    ['--release', REQUIRED],          # OS Release
    ['--region', REQUIRED],           # AWS Region
    ['--repo', REQUIRED],             # Set repository
    ['--repodir', REQUIRED],          # Base Repository Directory
    ['--resource', REQUIRED],         # Resource (KVM)
    ['--restart', BOOLEAN],           # Re-start VM
    ['--rng', REQUIRED],              # RNG (KVM)
    ['--rootdisk', REQUIRED],         # Set root device to install to
    ['--rootfs', REQUIRED],           # Set root fs
    ['--rootpassword', REQUIRED],     # Client root password
    ['--rootsize', REQUIRED],         # Set root device size in M
    ['--rootuser', REQUIRED],         # Set root user name
    ['--rpoolname', REQUIRED],        # Solaris rpool name
    ['--rtcuseutc', REQUIRED],        # rtcuseutc
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
    ['--shutdowncommand', REQUIRED],  # Packer Shutdown command
    ['--shutdowntimeout', REQUIRED],  # Packer Shutdown timeout
    ['--sitename', REQUIRED],         # Sitename for VCSA
    ['--smartcard', REQUIRED],        # Smartcard (KVM)
    ['--snapshot', REQUIRED],         # AWS snapshot
    ['--socker', REQUIRED],           # Socket file
    ['--sound', REQUIRED],            # Sound (KVM)
    ['--splitvols', BOOLEAN],         # Split volumes, e.g. seperate /, /var, etc
    ['--sshkeyfile', REQUIRED],       # SSH Keyfile
    ['--sshpassword', REQUIRED],      # Packer SSH Port min
    ['--sshport', REQUIRED],          # SSH Port
    ['--sshportmax', REQUIRED],       # Packer SSH Port max
    ['--sshportmin', REQUIRED],       # Packer SSH Port min
    ['--sshusername', REQUIRED],      # Packer SSH Port min
    ['--sshpty', BOOLEAN],            # Packer SSH PTY
    ['--ssopassword', REQUIRED],      # SSO password
    ['--stack', REQUIRED],            # AWS CF Stack
    ['--start', BOOLEAN],             # Start VM
    ['--stop', BOOLEAN],              # Stop VM
    ['--strict', BOOLEAN],            # Ignore SSH keys
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
    ['--virtiofile', REQUIRED],       # VirtIO driver file/cdrom
    ['--virtualdevice', REQUIRED],    # Virtual disk device (e.g. lsilogic)
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
    ['--vmtype',  REQUIRED],          # VM type
    ['--vmxfile', REQUIRED],          # VMX file
    ['--vnc', BOOLEAN],               # Enable VNC mode
    ['--vncpassword', REQUIRED],      # VNC password
    ['--vsock',  REQUIRED],           # vSock (KVM)
    ['--vswitch',  REQUIRED],         # vSwitch
    ['--vtxvpid',  REQUIRED],         # vtxvpid
    ['--vtxux',  REQUIRED],           # vtxux
    ['--wait', REQUIRED],             # Wait (KVM)
    ['--winshell', REQUIRED],         # Packer Windows remote action shell (e.g. winrm)
    ['--winrminsecure', BOOLEAN],     # Packer winrm insecure
    ['--winrmport', REQUIRED],        # Packer winrm port
    ['--winrmusessl', BOOLEAN],       # Packer winrm use SSL
    ['--watchdog', REQUIRED],         # Watchdog (KVM)
    ['--workdir', REQUIRED],          # Base Work Directory
    ['--yes', REQUIRED],              # Answer yes to questions
    ['--zone', REQUIRED],             # Zone file
    ['--zonedir', REQUIRED],          # Base Zone Directory
    ['--zpool', REQUIRED]             # Boot zpool name
  )
rescue
  values['output'] = 'text'
  values['stdout'] = []
  print_help(values)
  quit(values)
end

# Handle values switch

if values['options'].to_s.match(/[a-z]/)
  if values['options'].to_s.match(/\,/)
    options = values['options'].to_s.split(",")
  else
    options = [ values['options'].to_s ]
  end
  options.each do |item|
    values[item] = true
  end
end

if values['dryrun'] = true
  values['dry-run'] = true
end

# Handle alternate values

[ "list", "create", "delete", "start", "stop", "restart", "build" ].each do |switch|
  if values[switch] == true
    values['action'] = switch
  end
end

if values['netbridge']
  values['bridge'] = values['netbridge']
end

if values['disksize']
  values['size'] = values['disksize']
end

# Handle import

if values['import'] == true
  if values['vm']
    if not values['vm'].to_s.match(/kvm/)
      values['action'] = "import"
    end
  else
    values['action'] = "import"
  end
end

# Set up question associative array

values['q_struct'] = {}
values['q_order']  = []

values['i_struct'] = {}
values['i_order']  = []

values['u_struct'] = {}
values['u_order']  = []

values['g_struct'] = {}
values['g_order']  = []

# Handle method switch

if values['method'] != values['empty']
  values['method'] = values['method'].downcase
  values['method'] = values['method'].gsub(/vsphere/, "vs")
  values['method'] = values['method'].gsub(/jumpstart/, "js")
  values['method'] = values['method'].gsub(/kickstart/, "ks")
  values['method'] = values['method'].gsub(/preseed/, "ps")
  values['method'] = values['method'].gsub(/cloudinit|cloudconfig|subiquity/, "ci")
end

# Set up some initital defaults

values['stdout']  = []

# Print help before anything if required

if values['help']
  values['output'] = 'text'
  print_help(values)
  quit(values)
end

# Print version

if values['version']
  values['output'] = 'text'
  print_version(values)
  quit(values)
end

# Get defaults

defaults = {}
(values, defaults) = set_defaults(values, defaults)
defaults['stdout']  = []

# Check valid values

raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
raw_params.each do |raw_param|
  if raw_param.match(/\[/) && !raw_param.match(/^raw_params/)
    raw_param   = raw_param.split(/--/)[1].split(/'/)[0]
    valid_param = "valid-"+raw_param
    if values[raw_param]
      if defaults[valid_param]
        test_value = values[raw_param][0]
        if test_value.match(/\,/)
          test_value = test_value.split(",")[0]
        end
        if !defaults[valid_param].to_s.downcase.match(/#{test_value.downcase}/)
          handle_output(defaults, "Warning:\tOption --#{raw_param} has an invalid value: #{values[raw_param]}")
          handle_output(defaults, "Information:\tValid values for --#{raw_param} are: \n #{defaults[valid_param].to_s}")
          quit(defaults)
        end
      end
    end
  end
end

# If we've been given a file try to get os and other insformation from file

if values['file'].to_s.match(/[A-Z]|[a-z]|[0-9]/) && !values['action'].to_s.match(/list/)
  values['sudo'] = defaults['sudo']
  values['host-os-uname'] = defaults['host-os-uname']
  if !values['mountdir']
    values['mountdir'] = defaults['mountdir']
  end
  if !values['output']
    values['output'] = defaults['output']
  end
  values['executehost'] = defaults['executehost']
  if values['file'] != defaults['empty']
    values = get_install_service_from_file(values)
  end
end

# Set SSH port

values = set_ssh_port(values)

# Reset defaults based on updated values

defaults = reset_defaults(values, defaults)

# Process values based on defaults

raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
raw_params.each do |raw_param|
  if raw_param.match(/\[/) && !raw_param.match(/stdout|^raw_params/)
    raw_param = raw_param.split(/--/)[1].split(/'/)[0]
    if !values[raw_param]
      if defaults[raw_param].to_s.match(/[A-Z]|[a-z]|[0-9]/)
        values[raw_param] = defaults[raw_param]
      else
        values[raw_param] = defaults['empty']
      end
    end
    if values['verbose'] == true
      values['output'] = "text"
      handle_output(values, "Information:\tSetting option #{raw_param} to #{values[raw_param]}")
    end
  end
end

# Do a final check through defaults

defaults.each do |param, value|
  if !values[param]
    values[param] = defaults[param]
    if values['verbose'] == true
      values['output'] = "text"
      handle_output(values, "Information:\tSetting option #{param} to #{values[param]}")
    end
  end
  if values['action'] == "info"
    if values['info'].match(/os/)
      if param.match(/^os/)
        values['verbose'] = true
        handle_output(values, "Information:\tParameter #{param} is #{values[param]}")
        values['verbose'] = false
      end
    end
  end
end

# Check some actions - We may be able to process without action switch

[ "info", "check" ].each do |action|
  if values['action'] == values['empty']
    if values[action] != values['empty']
      values['action'] = action
    end
  end
end

# Do some more checks

if values['vm'] != values['empty']
  if values['action'].to_s.match(/create/)
    if values['dhcp'] == false
      if values['file'] != values['empty']
        if values['type'] != "service"
          if values['ip'] == values['empty']
            if !values['vmnetwork'].to_s.match(/nat/)
              handle_output(values, "Warning:\tNo IP specified and DHCP not specified")
              quit(values)
            end
          end
        end
      end
    end
  end
end

# Set some local configuration values like DHCP files etc

values = set_local_config(values)

# Clean up values

values = cleanup_values(values, defaults)

# Create required directories

check_dir_exists(values, values['workdir'])
[ values['isodir'], values['repodir'], values['imagedir'], values['pkgdir'], values['clientdir'] ].each do |dir_name|
  check_zfs_fs_exists(values, dir_name)
end

# Handle setup

if values['setup'] != values['empty']
  if !File.exist?(values['setup'])
    handle_output(values, "Warning:\tSetup script '#{values['setup']}' not found")
    quit(values)
  end
end

# Handle IPs option

if values['ips']
  if values['ips'].to_s.match(/[0-9]/)
    values['ip'] = values['ips']
  end
end

# If delete action chosen, check a client or service name is specified

if values['action'].to_s.match(/delete/)
  if values['name'] == values['empty'] && values['service'] == values['empty']
    handle_output(values, "Warning:\tNo service of client name specified")
    quit(values)
  end
end

# If using AWS check for and load AWS CLI gem
# Removed this from the default check as it takes a long time to install

if values['vm']
  if values['vm'].to_s.match(/aws/)
    begin
      require 'aws-sdk'
    rescue LoadError
      install_gem("aws-sdk")
    end
  end
end

# Check directory permissions perms by default

if values['action'].to_s.match(/check/) && values['check'].to_s.match(/perm|dir/)
  check_perms(values)
  quit(values)
end

# Handle base ISO dir when dir option set

if values['action'] == "list" && values['type'].to_s.match(/iso|img|image/) && values['dir']
  values['isodir'] = values['dir']
end

# Make sure a VM type is set for ansible

if values['type'].to_s.match(/ansible|packer/)
  if values['vm'] == values['empty']
    handle_output(values, "Warning:\tNo VM type specified")
    quit(values)
  end
end

# Check packer is installed and is latest version

if values['type'].to_s.match(/packer/)
  values = check_packer_is_installed(values)
end

# Prime HTML

if values['output'].to_s.match(/html/)
  values['stdout'].push("<html>")
  values['stdout'].push("<head>")
  values['stdout'].push("<title>#{values['scriptname']}</title>")
  values['stdout'].push("</head>")
  values['stdout'].push("<body>")
end

# Handle keyfile switch

if values['keyfile'] != values['empty']
  if !File.exist?(values['keyfile'])
    handle_output(values, "Warning:\tKey file #{values['keyfile']} does not exist")
    if values['action'].to_s.match(/create/) and !option['type'].to_s.match(/key/)
      quit(values)
    end
  end
end

# Handle sshkeyfile switch

if values['sshkeyfile'] != values['empty']
  if !File.exist?(values['sshkeyfile'])
    handle_output(values, "Warning:\tSSH Key file #{values['sshkeyfile']} does not exist")
    if values['action'].to_s.match(/create/)
      check_ssh_keys(values)
    end
  end
end

# Handle AWS credentials

if values['vm'] != values['empty']
  if values['vm'].to_s.match(/aws/)
    if values['creds']
      values['access'], values['secret'] = get_aws_creds(values)
    else
      if ENV['AWS_ACCESS_KEY']
        values['access'] = ENV['AWS_ACCESS_KEY']
      end
      if ENV['AWS_SECRET_KEY']
        values['secret'] = ENV['AWS_SECRET_KEY']
      end
      if !values['secret'] || !values['access']
        values['access'], values['secret'] = get_aws_creds(values)
      end
    end
    if values['access'] == values['empty'] || values['secret'] == values['empty']
      handle_output(values, "Warning:\tAWS Access and Secret Keys not found")
      quit(values)
    else
      if !File.exist?(values['creds'])
        create_aws_creds_file(values)
      end
    end
  end
end

# Handle client name switch

if values['name'] != values['empty']
  check_hostname(values)
  if values['verbose'] == true
    handle_output(values, "Information:\tSetting client name to #{values['name']}")
  end
end

# If specified admin set admin user

if values['adminuser'] == values['empty']
  if values['action']
    if values['action'].to_s.match(/connect|ssh/)
      if values['vm']
        if values['vm'].to_s.match(/aws/)
          values['adminuser'] = values['awsuser']
        else
          values['adminuser'] = %x[whoami].chomp
        end
      else
        if values['id']
          values['adminuser'] = values['awsuser']
        else
          values['adminuser'] = %x[whoami].chomp
        end
      end
    end
  else
    values['adminuser'] = %x[whoami].chomp
  end
end

# Change VM disk size

if values['size'] != values['empty']
  values['size'] = values['size']
  if !values['size'].to_s.match(/G$/)
    values['size'] = values['size'] + "G"
  end
end

# Get MAC address if specified

if values['mac'] != values['empty']
  if !values['vm']
    values['vm'] = "none"
  end
  values['mac'] = check_install_mac(values)
  if values['verbose'] == true
     handle_output(values, "Information:\tSetting client MAC address to #{values['mac']}")
  end
else
  values['mac'] = ""
end

# Handle architecture switch

 if values['arch'] != values['empty']
   values['arch'] = values['arch'].downcase
   if values['arch'].to_s.match(/sun4u|sun4v/)
     values['arch'] = "sparc"
   end
   if values['os-type'].to_s.match(/vmware/)
     values['arch'] = "x86_64"
   end
   if values['os-type'].to_s.match(/bsd/)
     values['arch'] = "i386"
   end
 end

# Handle install shell

if values['shell'] == values['empty']
  if values['os-type'].to_s.match(/win/)
    values['shell'] = "winrm"
  else
    values['shell'] = "ssh"
  end
end

# Handle vm switch

if values['vm'] != values['empty']
  values['vm'] = values['vm'].gsub(/virtualbox/, "vbox")
  values['vm'] = values['vm'].gsub(/mp/, "multipass")
  if values['vm'].to_s.match(/aws/)
    if values['service'] == values['empty']
      values['service'] = $default_aws_type
    end
  end
end

# Handle share switch

if values['share'] != values['empty']
  if !File.directory?(values['share'])
    handle_output(values, "Warning:\tShare point #{values['share']} doesn't exist")
    quit(values)
  end
  if values['mount'] == values['empty']
    values['mount'] = File.basename(values['share'])
  end
  if values['verbose'] == true
    handle_output(values, "Information:\tSharing #{values['share']}")
    handle_output(values, "Information:\tSetting mount point to #{values['mount']}")
  end
end

# Get Timezone

if values['timezone'] == values['empty']
  if values['os-type'] != values['empty']
    if values['os-type'].to_s.match(/win/)
     values['timezone'] = values['time']
    else
      values['timezone'] = values['timezone']
    end
  end
end

# Handle clone switch

if values['clone'] == values['empty']
  if values['action'] == "snapshot"
    clone_date = %x[date].chomp.downcase.gsub(/ |:/, "_")
    values['clone'] = values['name'] + "-" + clone_date
  end
  if values['verbose'] == true && values['clone']
    handle_output(values, "Information:\tSetting clone name to #{values['clone']}")
  end
end

# Handle option size

if !values['size'] == values['empty']
  if values['type'].to_s.match(/vcsa/)
    if !values['size'].to_s.match(/[0-9]/)
      values['size'] = $default_vcsa_size
    end
  end
else
  if !values['vm'].to_s.match(/aws/) && !values['type'].to_s.match(/cloud|cf|stack/)
    if values['type'].to_s.match(/vcsa/)
      values['size'] = $default_vcsa_size
    else
      values['size'] = values['size']
    end
  end
end

# Try to determine install method when given just a file/ISO

if values['file'] != values['empty']
  if values['vm'] == "vbox" && values['file'] == "tools"
    values['file'] = values['vboxadditions']
  end
  if !values['action'].to_s.match(/download/)
    if !File.exist?(values['file']) && !values['file'].to_s.match(/^http/)
      handle_output(values, "Warning:\tFile #{values['file']} does not exist")
      if !values['test'] == true
        quit(values)
      end
    end
  end
  if values['action'].to_s.match(/deploy/)
    if values['type'] == values['empty']
      values['type'] = get_install_type_from_file(values)
    end
  end
  if values['file'] != values['empty'] && values['action'].to_s.match(/create|add/)
    if values['method'] == values['empty']
      values['method'] = get_install_method_from_iso(values)
      if values['method'] == nil
        handle_output(values, "Could not determine install method")
        quit(values)
      end
    end
    if values['type'] == values['empty']
      values['type'] = get_install_type_from_file(values)
      if values['verbose'] == true
        handle_output(values, "Information:\tSetting install type to #{values['type']}")
      end
    end
  end
end

# Handle values and parameters

if values['param'] != values['empty']
  if !values['action'].to_s.match(/get/)
    if !values['value']
      handle_output(values, "Warning:\tSetting a parameter requires a value")
      quit(values)
    else
      if !values['value']
        handle_output(values, "Warning:\tSetting a parameter requires a value")
        quit(values)
      end
    end
  end
end

if values['value'] != values['empty']
  if values['param'] == values['empty']
    handle_output(values, "Warning:\tSetting a value requires a parameter")
    quit(values)
  end
end

# Handle LDoms

if values['method'] != values['empty']
  if values['method'].to_s.match(/dom/)
    if values['method'].to_s.match(/cdom/)
      values['mode'] = "server"
      values['vm']   = "cdom"
      if values['verbose'] == true
        handle_output(values, "Information:\tSetting mode to server")
        handle_output(values, "Information:\tSetting vm to cdrom")
      end
    else
      if values['method'].to_s.match(/gdom/)
        values['mode'] = "client"
        values['vm']   = "gdom"
        if values['verbose'] == true
          handle_output(values, "Information:\tSetting mode to client")
          handle_output(values, "Information:\tSetting vm to gdom")
        end
      else
        if values['method'].to_s.match(/ldom/)
          if values['name'] != values['empty']
            values['method'] = "gdom"
            values['vm']     = "gdom"
            values['mode']   = "client"
            if values['verbose'] == true
              handle_output(values, "Information:\tSetting mode to client")
              handle_output(values, "Information:\tSetting method to gdom")
              handle_output(values, "Information:\tSetting vm to gdom")
            end
          else
            handle_output(values, "Warning:\tCould not determine whether to run in server of client mode")
            quit(values)
          end
        end
      end
    end
  else
    if values['mode'].to_s.match(/client/)
      if values['vm'] != values['empty']
        if values['method'].to_s.match(/ldom|gdom/)
          values['vm'] = "gdom"
        end
      end
    else
      if values['mode'].to_s.match(/server/)
        if values['vm'] != values['empty']
          if values['method'].to_s.match(/ldom|cdom/)
            values['vm'] = "cdom"
          end
        end
      end
    end
  end
else
  if values['mode'] != values['empty']
    if values['vm'].to_s.match(/ldom/)
      if values['mode'].to_s.match(/client/)
        values['vm']     = "gdom"
        values['method'] = "gdom"
        if values['verbose'] == true
          handle_output(values, "Information:\tSetting method to gdom")
          handle_output(values, "Information:\tSetting vm to gdom")
        end
      end
      if values['mode'].to_s.match(/server/)
        values['vm']     = "cdom"
        values['method'] = "cdom"
        if values['verbose'] == true
          handle_output(values, "Information:\tSetting method to cdom")
          handle_output(values, "Information:\tSetting vm to cdom")
        end
      end
    end
  end
end

# Handle Packer and VirtualBox not supporting hostonly or bridged network

if !values['vmnetwork'].to_s.match(/nat/)
  if values['vm'].to_s.match(/virtualbox|vbox/)
    if values['type'].to_s.match(/packer/) || values['method'].to_s.match(/packer/) && !values['action'].to_s.match(/delete|import/)
      handle_output(values, "Warning:\tPacker has a bug that causes issues with Hostonly and Bridged network on VirtualBox")
      handle_output(values, "Warning:\tTo deal with this an addition port may be added to the SSH daemon config file")
    end
  end
end

# Set default host only Information

if !values['vm'] == values['empty']
  if values['vmnetwork'] == "hostonly" || values['vmnetwork'] == values['empty']
    values['vmnetwork'] = "hostonly"
    values = set_hostonly_info(values)
  end
end

# Check action when set to build or import

if values['action'].to_s.match(/build|import/)
  if values['type'] == values['empty']
    handle_output(values, "Information:\tSetting Install Service to Packer")
    values['type'] = "packer"
  end
  if values['vm'] == values['empty']
    if values['name'] == values['empty']
      handle_output(values, "Warning:\tNo client name specified")
      quit(values)
    end
    values['vm'] = get_client_vm_type_from_packer(values)
  end
  if values['vm'] == values['empty']
    handle_output(values, "Warning:\tVM type not specified")
    quit(values)
  else
    if !values['vm'].to_s.match(/vbox|fusion|aws|kvm|parallels|qemu/)
      handle_output(values, "Warning:\tInvalid VM type specified")
      quit(values)
    end
  end
end

if values['ssopassword'] != values['empty']
  values['adminpassword'] = values['ssopassword']
end

# Get Netmask

if values['netmask'] == values['empty']
  if values['type'].to_s.match(/vcsa/)
    values['netmask'] = $default_cidr
  end
end

# # Handle deploy

if values['action'].to_s.match(/deploy/)
  if values['type'] == values['empty']
    values['type'] = "esx"
  end
  if values['type'].to_s.match(/esx|vcsa/)
    if values['serverpassword'] == values['empty']
      values['serverpassword'] = values['rootpassword']
    end
    check_ovftool_exists
    if values['type'].to_s.match(/vcsa/)
      if values['file'] == values['empty']
        handle_output(values, "Warning:\tNo deployment image file specified")
        quit(values)
      end
      check_password(values)
      check_password(values)
    end
  end
end

# Handle console switch

if values['console'] != values['empty']
  case values['console']
  when /x11/
    values['text'] = false
  when /serial/
    values['serial'] = true
    values['text']   = true
  when /headless/
    values['headless'] = true
  else
    values['text'] = true
  end
else
  values['console'] = "text"
  values['text']    = false
end

# Handle list option for action switch

if values['action'].to_s.match(/list|info/)
  if values['file'] && !values['file'] == values['empty']
    describe_file(values)
    quit(values)
  else
    if values['vm'] == values['empty'] && values['service'] == values['empty'] && values['method'] == values['empty'] && values['type'] == values['empty'] && values['mode'] == values['empty']
      handle_output(values, "Warning:\tNo type or service specified")
    end
  end
end

# Handle action switch

if values['action'] != values['empty']
  if values['action'].to_s.match(/delete/) && values['service'] == values['empty']
    if values['vm'] == values['empty'] && values['type'] != values['empty']
      values['vm'] = get_client_vm_type_from_packer(values)
    else
      if values['type'] != values['empty'] && values['vm'] == values['empty']
        if values['type'].to_s.match(/packer/)
          if values['name'] != values['empty']
            values['vm'] = get_client_vm_type_from_packer(values)
          end
        end
      end
    end
  end
  if values['action'].to_s.match(/migrate|deploy/)
    if values['action'].to_s.match(/deploy/)
      if values['type'].to_s.match(/vcsa/)
        values['vm'] = "fusion"
      else
        values['type'] =get_install_type_from_file(values)
        if values['type'].to_s.match(/vcsa/)
          values['vm'] = "fusion"
        end
      end
    end
    if values['vm'] == values['empty']
      handle_output(values, "Information:\tVirtualisation method not specified, setting virtualisation method to VMware")
      values['vm'] = "vm"
    end
    if values['server'] == values['empty'] || values['ip'] == values['empty']
      handle_output(values, "Warning:\tRemote server hostname or IP not specified")
      quit(values)
    end
  end
end

# Get additional information from install file if required

if values['type'].to_s.match(/vcsa|packer/)
  if values['service'] == values['empty'] || values['os-type'] == values['empty'] || values['method'] == values['empty'] || values['release'] == values['empty'] || values['arch'] == values['empty'] || values['label'] == values['empty']
    if values['file'] != values['empty']
      values = get_install_service_from_file(values)
    end
  end
end

# Handle install service switch

if values['service'] != values['empty']
  if values['verbose'] == true
    handle_output(values, "Information:\tSetting install service to #{values['service']}")
  end
  if values['type'].to_s.match(/^packer$/)
    check_packer_is_installed(values)
    values['mode']    = "client"
    if values['method'] == values['empty'] && values['os-type'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/) && !values['vm'].to_s.match(/aws/)
      handle_output(values, "Warning:\tNo OS, or Install Method specified for build type #{values['service']}")
      quit(values)
    end
    if values['vm'] == values['empty'] && !values['action'].to_s.match(/list/)
      handle_output(values, "Warning:\tNo VM type specified for build type #{values['service']}")
      quit(values)
    end
    if values['name'] == values['empty'] && !values['action'].to_s.match(/list/) && !values['vm'].to_s.match(/aws/)
      handle_output(values, "Warning:\tNo Client name specified for build type #{values['service']}")
      quit(values)
    end
    if values['file'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/) && !values['vm'].to_s.match(/aws/)
      handle_output(values, "Warning:\tNo ISO file specified for build type #{values['service']}")
      quit(values)
    end
    if !values['ip'].to_s.match(/[0-9]/) && !values['action'].to_s.match(/build|list|import|delete/) && !values['vm'].to_s.match(/aws/)
      if values['vmnetwork'].to_s.match(/hostonly/)
        values = set_hostonly_info(values)
        handle_output(values, "Information:\tNo IP Address specified, setting to #{values['ip']} ")
      else
        handle_output(values, "Warning:\tNo IP Address specified ")
      end
    end
    if !values['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/) && !values['action'].to_s.match(/build|list|import|delete/)
      handle_output(values, "Warning:\tNo MAC Address specified")
      handle_output(values, "Information:\tGenerating MAC Address")
      if values['vm'] != values['empty']
        if values['vm'] != values['empty']
          values['mac'] = generate_mac_address(values)
        else
          values['mac'] = generate_mac_address(values)
        end
      else
        values['mac'] = generate_mac_address(values)
      end
    end
  end
else
  if values['type'].to_s.match(/vcsa|packer/)
    if values['type'].to_s.match(/^packer$/)
      check_packer_is_installed(values)
      values['mode'] = "client"
      if values['method'] == values['empty'] && values['os-type'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/)
        handle_output(values, "Warning:\tNo OS, or Install Method specified for build type #{values['service']}")
        quit(values)
      end
      if values['vm'] == values['empty'] && !values['action'].to_s.match(/list/)
        handle_output(values, "Warning:\tNo VM type specified for build type #{values['service']}")
        quit(values)
      end
      if values['name'] == values['empty'] && !values['action'].to_s.match(/list/)
        handle_output(values, "Warning:\tNo Client name specified for build type #{values['service']}")
        quit(values)
      end
      if values['file'] == values['empty'] && !values['action'].to_s.match(/build|list|import|delete/)
        handle_output(values, "Warning:\tNo ISO file specified for build type #{values['service']}")
        quit(values)
      end
      if !values['ip'].to_s.match(/[0-9]/) && !values['action'].to_s.match(/build|list|import|delete/) && !values['vmnetwork'].to_s.match(/nat/)
        if values['vmnetwork'].to_s.match(/hostonly/)
          values = set_hostonly_info(values)
          handle_output(values, "Information:\tNo IP Address specified, setting to #{values['ip']} ")
        else
          handle_output(values, "Warning:\tNo IP Address specified ")
          quit(values)
        end
      end
      if !values['mac'].to_s.match(/[0-9]|[A-F]|[a-f]/) && !values['action'].to_s.match(/build|list|import|delete/)
        handle_output(values, "Warning:\tNo MAC Address specified")
        handle_output(values, "Information:\tGenerating MAC Address")
        if values['vm'] == values['empty']
          values['vm'] = "none"
        end
        values['mac'] = generate_mac_address(values)
      end
    end
  else
    values['service'] = ""
  end
end

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

if values['action'].to_s.match(/import/)
  if values['file'] == values['empty'] && values['service'] == values['empty'] && !values['type'].to_s.match(/packer/)
    vm_types  = [ "fusion", "vbox" ]
    exists    = []
    vm_exists = ""
    vm_type   = ""
    vm_types.each do |vm_type|
      exists = check_packer_vm_image_exists(values, vm_type)
      if exists[0].to_s.match(/yes/)
        values['type'] = "packer"
        values['vm']   = vm_type
        vm_exists      = "yes"
      end
    end
    if !vm_exists.match(/yes/)
      handle_output(values, "Warning:\tNo install file, type or service specified")
      quit(values)
    end
  end
end

# Handle release switch

if values['release'].to_s.match(/[0-9]/)
  if values['type'].to_s.match(/packer/) && values['action'].to_s.match(/build|delete|import/)
    values['release'] = ""
  else
    if values['vm'] == values['empty']
      values['vm'] = "none"
    end
    if values['vm'].to_s.match(/zone/) && values['host-os-unamer'].match(/10|11/) && !values['release'].to_s.match(/10|11/)
      handle_output(values, "Warning:\tInvalid release number: #{values['release']}")
      quit(values)
    end
#    if !values['release'].to_s.match(/[0-9]/) || values['release'].to_s.match(/[a-z,A-Z]/)
#      puts "Warning:\tInvalid release number: " + values['release']
#      quit(values)
#    end
  end
else
  if values['vm'].to_s.match(/zone/)
    values['release'] = values['host-os-unamer']
  else
    values['release'] = values['empty']
  end
end
if values['verbose'] == true && values['release']
  handle_output(values, "Information:\tSetting Operating System version to #{values['release']}")
end

# Handle empty OS option

if values['os-type'] == values['empty']
  if values['vm'] != values['empty']
    if values['action'].to_s.match(/add|create/)
      if values['method'] == values['empty']
        if !values['vm'].to_s.match(/ldom|cdom|gdom|aws|mp|multipass/) && !values['type'].to_s.match(/network/)
          handle_output(values, "Warning:\tNo OS or install method specified when creating VM")
          quit(values)
        end
      end
    end
  end
end

# Handle memory switch

if values['memory'] == values['empty']
  if values['vm'] != values['empty']
    if values['os-type'].to_s.match(/vs|esx|vmware|vsphere/) || values['method'].to_s.match(/vs|esx|vmware|vsphere/)
      values['memory'] = "4096"
    end
    if values['os-type'] != values['empty']
      if values['os-type'].to_s.match(/sol/)
        if values['release'].to_i > 9
          values['memory'] = "2048"
        end
      end
    else
      if values['method'] == "ai"
        values['memory'] = "2048"
      end
    end
  end
end

# Get/set publisher port (Used for configuring AI server)

if values['host-os-uname'].to_s.match(/SunOS/) and !values['publisher'] == values['empty']
  if values['mode'].to_s.match(/server/) || values['type'].to_s.match(/service/)
    values['publisherhost'] = values['publisher']
    if values['publisherhost'].to_s.match(/:/)
      (values['publisherhost'], values['publisherport']) = values['publisherhost'].split(/:/)
    end
    handle_output(values, "Information:\tSetting publisher host to #{values['publisherhost']}")
    handle_output(values, "Information:\tSetting publisher port to #{values['publisherport']}")
  else
    if values['mode'] == "server" || values['file'].to_s.match(/repo/)
      if values['host-os-uname'] == "SunOS"
        values['mode'] = "server"
        values = check_local_config(values)
        values['publisherhost'] = values['hostip']
        values['publisherport'] = $default_ai_port
        if values['verbose'] == true
          handle_output(values, "Information:\tSetting publisher host to #{values['publisherhost']}")
          handle_output(values, "Information:\tSetting publisher port to #{values['publisherport']}")
        end
      end
    else
      if values['vm'] == values['empty']
        if values['action'].to_s.match(/create/)
          values['mode'] = "server"
          values = check_local_config(values)
        end
      else
        values['mode'] = "client"
        values = check_local_config(values)
      end
      values['publisherhost'] = values['hostip']
    end
  end
end

# If service is set, but method and os isn't specified, try to set method from service name

if values['service'] != values['empty'] && values['method'] == values['empty'] && values['os-type'] == values['empty']
  values['method'] = get_install_method_from_service(values)
else
  if values['method'] == values['empty'] && values['os-type'] == values['empty']
    values['method'] = get_install_method_from_service(values)
  end
end

# Handle VM switch

if values['vm'] != values['empty']
  values['mode'] = "client"
  values = check_local_config(values)
  case values['vm']
  when /parallels/
    values['status'] = check_parallels_is_installed(values)
    handle_vm_install_status(values)
    values['vm']   = "parallels"
    values['sudo'] = false
    values['size'] = values['size'].gsub(/G/, "000")
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      values['hostonlyip'] = "10.211.55.1"
      values['vmgateway']  = "10.211.55.1"
    else
      values['hostonlyip'] = "192.168.55.1"
      values['vmgateway']  = "192.168.55.1"
    end
  when /multipass|mp/
    values['vm'] = "multipass"
    if values['os-name'].to_s.match(/Darwin/)
      values = check_vbox_is_installed(values)
      values['hostonlyip'] = "192.168.64.1"
      values['vmgateway']  = "192.168.64.1"
    end
    check_multipass_is_installed(values)
  when /virtualbox|vbox/
    values = check_vbox_is_installed(values)
    handle_vm_install_status(values)
    values['vm']   = "vbox"
    values['sudo'] = false
    values['size'] = values['size'].gsub(/G/, "000")
    values['hostonlyip'] = "192.168.56.1"
    values['vmgateway']  = "192.168.56.1"
  when /kvm/
    values['status'] = check_kvm_is_installed(values)
    handle_vm_install_status(values)
    values['hostonlyip'] = "192.168.122.1"
    values['vmgateway']  = "192.168.122.1"
  when /vmware|fusion/
    handle_vm_install_status(values)
    check_fusion_vm_promisc_mode(values)
    values['sudo'] = false
    values['vm']   = "fusion"
  when /zone|container|lxc/
    if values['host-os-uname'].to_s.match(/SunOS/)
      values['vm'] = "zone"
    else
      values['vm'] = "lxc"
    end
  when /ldom|cdom|gdom/
    if $os_arch.downcase.match(/sparc/) && values['host-os-uname'].to_s.match(/SunOS/)
      if values['release'] == values['empty']
        values['release']   = values['host-os-unamer']
      end
      if values['host-os-unamer'].match(/10|11/)
        if values['mode'].to_s.match(/client/)
          values['vm'] = "gdom"
        end
        if values['mode'].to_s.match(/server/)
          values['vm'] = "cdom"
        end
      else
        handle_output(values, "Warning:\tLDoms require Solaris 10 or 11")
      end
    else
      handle_output(values, "Warning:\tLDoms require Solaris on SPARC")
      quit(values)
    end
  end
  if !values['valid-vm'].to_s.downcase.match(/#{values['vm'].to_s}/) && !values['action'].to_s.match(/list/)
    print_valid_list(values, "Warning:\tInvalid VM type", values['valid-vm'])
  end
  if values['verbose'] == true
    handle_output(values, "Information:\tSetting VM type to #{values['vm']}")
  end
else
  values['vm'] = "none"
end

if values['vm'] != values['empty'] || values['method'] != values['empty']
  if values['model'] != values['empty']
    values['model'] = values['model'].downcase
  else
    if values['arch'].to_s.match(/i386|x86|x86_64|x64|amd64/)
      values['model'] = "vmware"
    else
      values['model'] = ""
    end
  end
  if values['verbose'] == true && values['model']
    handle_output(values, "Information:\tSetting model to #{values['model']}")
  end
end

# Check OS switch

if values['os-type'] == values['empty'] || values['method'] == values['empty'] || values['release'] == values['empty'] || values['arch'] == values['empty']
  if !values['file'] == values['empty']
    values = get_install_service_from_file(values)
  end
end

if values['os-type'] != values['empty']
  case values['os-type']
  when /suse|sles/
    values['method'] = "ay"
  when /vsphere|esx|vmware/
    values['method'] = "vs"
  when /kickstart|redhat|rhel|fedora|sl|scientific|ks|centos/
    values['method'] = "ks"
  when /ubuntu|debian/
    if values['file'].to_s.match(/cloudimg/)
      values['method'] = "ci"
    else
      values['method'] = "ps"
    end
  when /purity/
    values['method'] = "ps"
    if values['memory'].to_s.match(/#{values['memory']}/)
      values['vcpus'] = "2"
      if values['release'].to_s.match(/^5\.2/)
        values['memory'] = "12288"
      else
        values['memory'] = "8192"
      end
      values['memory'] = values['memory']
      values['vcpus']  = values['vcpus']
    end
  when /sol/
    if values['release'].to_i < 11
      values['method'] = "js"
    else
      values['method'] = "ai"
    end
  end
end

# Handle install method switch

if values['method'] != values['empty']
  case values['method']
  when /cloud/
    info_examples     = "ci"
    values['method'] = "ci"
  when /suse|sles|yast|ay/
    info_examples     = "ay"
    values['method'] = "ay"
    when /autoinstall|ai/
    info_examples     = "ai"
    values['method'] = "ai"
  when /kickstart|redhat|rhel|fedora|sl_|scientific|ks|centos/
    info_examples     = "ks"
    values['method'] = "ks"
  when /jumpstart|js/
    info_examples     = "js"
    values['method'] = "js"
  when /preseed|debian|ubuntu|purity/
    info_examples     = "ps"
    values['method'] = "ps"
  when /vsphere|esx|vmware|vs/
    info_examples     = "vs"
    values['method'] = "vs"
    values['controller'] = "ide"
  when /bsd|xb/
    info_examples     = "xb"
    values['method'] = "xb"
  end
end

# Try to determine install method if only specified OS

if values['method'] == values['empty'] && !values['action'].to_s.match(/delete|running|reboot|restart|halt|shutdown|boot|stop|deploy|migrate|show|connect/)
  case values['os-type']
  when /sol|sunos/
    if values['release'].to_s.match(/[0-9]/)
      if values['release'] == "11"
        values['method'] = "ai"
      else
        values['method'] = "js"
      end
    end
  when /ubuntu|debian/
    values['method'] = "ps"
  when /suse|sles/
    values['method'] = "ay"
  when /redhat|rhel|scientific|sl|centos|fedora|vsphere|esx/
    values['method'] = "ks"
  when /bsd/
    values['method'] = "xb"
  when /vmware|esx|vsphere/
    values['method'] = "vs"
    configure_vmware_esxi_defaults
  when "windows"
    values['method'] = "pe"
  else
    if !values['action'].to_s.match(/list|info|check/)
      if !values['action'].to_s.match(/add|create/) && values['vm'] == values['empty']
        print_valid_list(values, "Warning:\tInvalid OS specified", values['valid-os'])
      end
    end
  end
end

# Handle gateway if not empty

if values['vmgateway'] != values['empty']
  values['vmgateway'] = values['vmgateway']
else
  if values['vmnetwork'] == "hostonly"
  end
end

# Do a check to see if we are running Packer and trying to install Windows with network in non NAT mode

if values['type'].to_s.match(/packer/) && values['os-type'].to_s.match(/win/)
  if !values['vmnetwork'].to_s.match(/nat/)
    handle_output(values, "Warning:\tPacker only supports installing Windows with a NAT network")
    handle_output(values, "Information:\tSetting network to NAT mode")
    values['vmnetwork'] = "nat"
  end
  values['shell'] = "winrm"
end

# Handle VM named none

if values['action'].to_s.match(/create/) && values['name'] == "none" && values['mode'] != "server" and values['type'] != "service"
  handle_output(values, "Warning:\tInvalid client name")
  quit(values)
end

# Check we have a setup file for purity

if values['os-type'] == "purity"
  if values['setup'] == values['empty']
    handle_output(values, "Warning:\tNo setup file specified")
    quit(values)
  end
end

# Handle action switch

def handle_action(values)
  if values['action'] != values['empty']
    case values['action']
    when /convert/
      if values['vm'].to_s.match(/kvm|qemu/)
        convert_kvm_image(values)
      end
    when /check/
      if values['check'].to_s.match(/dnsmasq/)
        check_dnsmasq(values)
      end
      if values['vm'].to_s.match(/kvm/)
        check_kvm_permissions(values)
      end
      if values['type'].to_s.match(/bridge/) && values['vm'].to_s.match(/kvm/)
        check_kvm_network_bridge(values)
      end
      if values['mode'].to_s.match(/server/)
        values = check_local_config(values)
      end
      if values['mode'].to_s.match(/osx/)
        check_osx_dnsmasq(values)
        check_osx_tftpd(values)
        check_osx_dhcpd(values)
      end
      if values['vm'].to_s.match(/fusion|vbox|kvm/)
        check_vm_network(values)
      end
      if values['check'].to_s.match(/dhcp/)
        check_dhcpd_config(values)
      end
      if values['check'].to_s.match(/tftp/)
        check_tftpd_config(values)
      end
    when /execute|shell/
      if values['type'].to_s.match(/docker/) or values['vm'].to_s.match(/docker/)
        execute_docker_command(values)
      end
      if values['vm'].to_s.match(/mp|multipass/)
        execute_multipass_command(values)
      end
    when /screen/
      if values['vm'] != values['empty']
        get_vm_screen(values)
      end
    when /vnc/
      if values['vm'] != values['empty']
        vnc_to_vm(values)
      end
    when /status/
      if values['vm'] != values['empty']
        status = get_vm_status(values)
      end
    when /set|put/
      if values['type'].to_s.match(/acl/)
        if values['bucket'] != values['empty']
          set_aws_s3_bucket_acl(values)
        end
      end
    when /upload|download/
      if values['bucket'] != values['empty']
        if values['action'].to_s.match(/upload/)
          upload_file_to_aws_bucket(values)
        else
          download_file_from_aws_bucket(values)
        end
      end
    when /display|view|show|prop|get|billing/
      if values['type'].to_s.match(/acl|url/) || values['action'].to_s.match(/acl|url/)
        if values['bucket'] != values['empty']
          show_aws_s3_bucket_acl(values)
        else
          if values['type'].to_s.match(/url/) || values['action'].to_s.match(/url/)
            show_s3_bucket_url(values)
          else
            get_aws_billing(values)
          end
        end
      else
        if values['name'] != values['empty']
          if values['vm'] != values['empty']
            show_vm_config(values)
          else
            get_client_config(values)
          end
        end
      end
    when /help/
      print_help(values)
    when /version/
      print_version
    when /info|usage|help/
      if values['file'] != values['empty']
        describe_file(values)
      else
        print_examples(values)
      end
    when /show/
      if values['vm'] != values['empty']
        show_vm_config(values)
      end
    when /list/
      if values['file'] != values['empty']
        describe_file(values)
      end
      case values['type']
      when /service/
        list_services(values)
      when /network/
        show_vm_network(values)
      when /ssh/
        list_user_ssh_config(values)
      when /image|ami/
        list_images(values)
      when /packer|ansible/
        list_clients(values)
        return values
      when /inst/
        if values['vm'].to_s.match(/docker/)
          list_docker_instances(values)
        else
          list_aws_instances(values)
        end
      when /bucket/
        list_aws_buckets(values)
      when /object/
        list_aws_bucket_objects(values)
      when /snapshot/
        if values['vm'].to_s.match(/aws/)
          list_aws_snapshots(values)
        else
          list_vm_snapshots(values)
        end
      when /key/
        list_aws_key_pairs(values)
      when /stack|cloud|cf/
        list_aws_cf_stacks(values)
      when /securitygroup/
        list_aws_security_groups(values)
      else
        if values['vm'].to_s.match(/docker/)
          if values['type'].to_s.match(/instance/)
            list_docker_instances(values)
          else
            list_docker_images(values)
          end
          return values
        end
        if values['type'].to_s.match(/service/) || values['mode'].to_s.match(/server/)
          if values['method'] != values['empty']
            list_services(values)
          else
            list_all_services(values)
          end
          return values
        end
        if values['type'].to_s.match(/iso/)
          if values['method'] != values['empty']
            list_isos(values)
          else
            list_os_isos(values)
          end
          return values
        end
        if values['mode'].to_s.match(/client/) || values['type'].to_s.match(/client/)
          values['mode'] = "client"
          check_local_config(values)
          if values['service'] != values['empty']
            if values['service'].to_s.match(/[a-z]/)
              list_clients(values)
            end
          end
          if values['vm'] != values['empty']
            if values['vm'].to_s.match(/[a-z]/)
              if values['type'] == values['empty']
                if values['file'] != values['empty']
                  describe_file(values)
                else
                  list_vms(values)
                end
              end
            end
          end
          return values
        end
        if values['method'] != values['empty'] && values['vm'] == values['empty']
          list_clients(values)
          return values
        end
        if values['type'].to_s.match(/ova/)
          list_ovas
          return values
        end
        if values['vm'] != values['empty'] && values['vm'] != values['empty']
          if values['type'].to_s.match(/snapshot/)
            list_vm_snapshots(values)
          else
            list_vm(values)
          end
          return values
        end
      end
    when /delete|remove|terminate/
      if values['name'] == values['empty'] && values['service'] == values['empty']
        handle_output(values, "Warning:\tNo service of client name specified")
        quit(values)
      end
      if values['type'].to_s.match(/network|snapshot/) && values['vm'] != values['empty']
        if values['type'].to_s.match(/network/)
          delete_vm_network(values)
        else
          delete_vm_snapshot(values)
        end
        return values
      end
      if values['type'].to_s.match(/ssh/)
        delete_user_ssh_config(values)
        return values
      end
      if values['name'] != values['empty']
        if values['vm'].to_s.match(/docker/)
          delete_docker_image(values)
          return values
        end
        if values['service'] == values['empty'] && values['vm'] == values['empty']
          if values['vm'] == values['empty']
            values['vm'] = get_client_vm_type(values)
            if values['vm'].to_s.match(/vbox|fusion|parallels|mp|multipass/)
              values['sudo'] = false
              delete_vm(values)
            else
              handle_output(values, "Warning:\tNo VM, client or service specified")
              handle_output(values, "Available services")
              list_all_services(values)
            end
          end
        else
          if values['vm'].to_s.match(/fusion|vbox|parallels|aws|kvm/)
            if values['type'].to_s.match(/packer|ansible/)
              unconfigure_client(values)
            else
              if values['type'].to_s.match(/snapshot/)
                if values['name'] != values['empty'] && values['snapshot'] != values['empty']
                  delete_vm_snapshot(values)
                else
                  handle_output(values, "Warning:\tClient name or snapshot not specified")
                end
              else
                delete_vm(values)
              end
            end
          else
            if values['vm'].to_s.match(/ldom|gdom/)
              unconfigure_gdom(values)
            else
              if values['vm'].to_s.match(/mp|multipass/)
                delete_multipass_vm(values)
                return values
              else
                remove_hosts_entry(values)
                remove_dhcp_client(values)
                if values['yes'] == true
                  delete_client_dir(values)
                end
              end
            end
          end
        end
      else
        if values['type'].to_s.match(/instance|snapshot|key|stack|cf|cloud|securitygroup|iprule|sg|ami|image/) || values['id'].to_s.match(/[0-9]|all/)
          case values['type']
          when /instance/
            values = delete_aws_vm(values)
          when /ami|image/
            if values['vm'].to_s.match(/docker/)
              delete_docker_image(values)
            else
              delete_aws_image(values)
            end
          when /snapshot/
            if values['vm'].to_s.match(/aws/)
              delete_aws_snapshot(values)
            else
              if values['snapshot'] == values['empty']
                handle_output(values, "Warning:\tNo snapshot name specified")
                if values['name'] == values['empty']
                  handle_output(values, "Warning:\tNo client name specified")
                  list_all_vm_snapshots(values)
                else
                  list_vm_snapshots(values)
                end
              else
                if values['name'] == values['empty'] && values['snapshot'] == values['empty']
                  handle_output(values, "Warning:\tNo client or snapshot name specified")
                  return values
                else
                  delete_vm_snapshot(values)
                end
              end
            end
          when /key/
            values = delete_aws_key_pair(values)
          when /stack|cf|cloud/
            delete_aws_cf_stack(values)
          when /securitygroup/
            delete_aws_security_group(values)
          when /iprule/
            if values['ports'].to_s.match(/[0-9]/)
              if values['ports'].to_s.match(/\./)
                ports = []
                values['ports'].split(/\./).each do |port|
                  ports.push(port)
                end
                ports = ports.uniq
              else
                port  = values['ports']
                ports = [ port ]
              end
              ports.each do |port|
                values['from'] = port
                values['to']   = port
                remove_rule_from_aws_security_group(values)
              end
            else
              remove_rule_from_aws_security_group(values)
            end
          else
            if values['ami'] != values['empty']
              delete_aws_image(values)
            else
              handle_output(values, "Warning:\tNo #{values['vm']} type, instance or image specified")
            end
          end
          return values
        end
        if values['type'].to_s.match(/packer|docker/)
          unconfigure_client(values)
        else
          if values['service'] != values['empty']
            if values['method'] == values['empty']
              unconfigure_server(values)
            else
              unconfigure_server(values)
            end
          end
        end
      end
    when /build/
      if values['type'].to_s.match(/packer/)
        if values['vm'].to_s.match(/aws/)
          build_packer_aws_config(values)
        else
          build_packer_config(values)
        end
      end
      if values['type'].to_s.match(/ansible/)
        if values['vm'].to_s.match(/aws/)
          build_ansible_aws_config(values)
        else
          build_ansible_config(values)
        end
      end
    when /add|create/
      if values['type'].to_s.match(/dnsmasq/)
        add_dnsmasq_entry(values)
        return values
      end
      if values['vm'].to_s.match(/mp|multipass/)
        configure_multipass_vm(values)
        return values
      end
      if values['type'] == values['empty'] && values['vm'] == values['empty'] && values['service'] == values['empty']
        handle_output(values, "Warning:\tNo service type or VM specified")
        return values
      end
    if values['type'].to_s.match(/service/) && !values['service'].to_s.match(/[a-z]/) && !values['service'] == values['empty']
        handle_output(values, "Warning:\tNo service name specified")
        return values
      end
      if values['file'] == values['empty']
        values['mode'] = "client"
      end
      if values['type'].to_s.match(/network/) && values['vm'] != values['empty']
        add_vm_network(values)
        return values
      end
      if values['type'].to_s.match(/ami|image|key|cloud|cf|stack|securitygroup|iprule|sg/)
        case values['type']
        when /ami|image/
          create_aws_image(values)
        when /key/
          values = create_aws_key_pair(values)
        when /cf|cloud|stack/
          configure_aws_cf_stack(values)
        when /securitygroup/
          create_aws_security_group(values)
        when /iprule/
          if values['ports'].to_s.match(/[0-9]/)
            if values['ports'].to_s.match(/\./)
              ports = []
              values['ports'].split(/\./).each do |port|
                ports.push(port)
              end
              ports = ports.uniq
            else
              port  = values['ports']
              ports = [ port ]
            end
            ports.each do |port|
              values['from'] = port
              values['to']   = port
              add_rule_to_aws_security_group(values)
            end
          else
            add_rule_to_aws_security_group(values)
          end
        end
        return values
      end
      if values['vm'].to_s.match(/aws/)
        case values['type']
        when /packer/
          configure_packer_aws_client(values)
        when /ansible/
          configure_ansible_aws_client(values)
        else
          if values['key'] == values['empty'] && values['group'] == values['empty']
            handle_output(values, "Warning:\tNo Key Pair or Security Group specified")
            return values
          else
            values = configure_aws_client(values)
          end
        end
        return values
      end
      if values['type'].to_s.match(/docker/)
        configure_docker_client(values)
        return values
      end
      if values['vm'].to_s.match(/kvm/)
        values = configure_kvm_client(values)
        return values
      end
      if values['vm'] == values['empty'] && values['method'] == values['empty'] && values['type'] == values['empty'] && !values['mode'].to_s.match(/server/)
        handle_output(values, "Warning:\tNo VM, Method or specified")
      end
      if values['mode'].to_s.match(/server/) || values['type'].to_s.match(/service/) && values['file'] != values['empty'] && values['vm'] == values['empty'] && !values['type'].to_s.match(/packer/) && !values['service'].to_s.match(/packer/)
        values['mode'] = "server"
        values = check_local_config(values)
        if values['host-os'].to_s.match(/Docker/)
          configure_docker_server(values)
        end
        if values['method'] == "none"
          if values['service'] != "none"
            values['method'] = get_method_from_service(values)
          end
        end
        configure_server(values)
      else
        if values['vm'].to_s.match(/fusion|vbox|kvm|mp|multipass/)
          check_vm_network(values)
        end
        if values['name'] != values['empty']
          if values['service'] != values['empty'] || values['type'].to_s.match(/packer/)
            if values['method'] == values['empty']
              values['method'] = get_install_method(values)
            end
            if !values['type'].to_s.match(/packer/) && values['vm'] == values['empty']
              check_dhcpd_config(values)
            end
            if !values['vmnetwork'].to_s.match(/nat/) && !values['action'].to_s.match(/add/)
              if !values['type'].to_s.match(/pxe/)
                check_install_ip(values)
              end
              check_install_mac(values)
            end
            if values['type'].to_s.match(/packer/)
              if values['yes'] == true
                if values['vm'] == values['empty']
                  values['vm'] = get_client_vm_type(values)
                  if values['vm'].to_s.match(/vbox|fusion|parallels/)
                    values['sudo'] = false
                    delete_vm(values)
                    unconfigure_client(values)
                  end
                else
                  values['sudo'] = false
                  delete_vm(values)
                  unconfigure_client(values)
                end
              end
              configure_client(values)
            else
              if values['vm'] == values['empty']
                if values['method'] == values['empty']
                  if values['ip'].to_s.match(/[0-9]/)
                    values['mode'] = "client"
                    values = check_local_config(values)
                    add_hosts_entry(values)
                  end
                  if values['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
                    values['service'] = ""
                    add_dhcp_client(values)
                  end
                else
                  if values['model'] == values['empty']
                    values['model'] = "vmware"
                    values['slice'] = "4192"
                  end
                  values['mode'] = "server"
                  values = check_local_config(values)
                  if !values['mac'].to_s.match(/[0-9]/)
                    values['mac'] = generate_mac_address(values)
                  end
                  configure_client(values)
                end
              else
                if values['vm'].to_s.match(/fusion|vbox|parallels/) && !values['action'].to_s.match(/add/)
                  create_vm(values)
                end
                if values['vm'].to_s.match(/zone|lxc|gdom/)
                  eval"[configure_#{values['vm']}(values)]"
                end
                if values['vm'].to_s.match(/cdom/)
                  configure_cdom(values)
                end
              end
            end
          else
            if values['vm'].to_s.match(/fusion|vbox|parallels/)
              create_vm(values)
            end
            if values['vm'].to_s.match(/zone|lxc|gdom/)
              eval"[configure_#{values['vm']}(values)]"
            end
            if values['vm'].to_s.match(/cdom/)
              configure_cdom(values)
            end
            if values['vm'] == values['empty']
              if values['ip'].to_s.match(/[0-9]/)
                values['mode'] = "client"
                values = check_local_config(values)
                add_hosts_entry(values)
              end
              if values['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
                values['service'] = ""
                add_dhcp_client(values)
              end
            end
          end
        else
          if values['mode'].to_s.match(/server/)
            if values['method'].to_s.match(/ai/)
              configure_ai_server(values)
            else
              handle_output(values, "Warning:\tNo install method specified")
            end
          else
            handle_output(values, "Warning:\tClient or service name not specified")
          end
        end
      end
    when /^boot$|^stop$|^halt$|^shutdown$|^suspend$|^resume$|^start$|^destroy$/
      values['mode']   = "client"
      values['action'] = values['action'].gsub(/start/, "boot")
      values['action'] = values['action'].gsub(/halt/, "stop")
      values['action'] = values['action'].gsub(/shutdown/, "stop")
      if values['vm'].to_s.match(/aws/)
        values = boot_aws_vm(values)
        return values
      end
      if values['name'] != values['empty'] && values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval"[#{values['action']}_#{values['vm']}_vm(values)]"
      else
        if values['name'] != values['empty'] && values['vm'] == values['empty']
          values['vm'] = get_client_vm_type(values)
          values = check_local_config(values)
          if values['vm'].to_s.match(/vbox|fusion|parallels/)
            values['sudo'] = false
          end
          if values['vm'] != values['empty']
            control_vm(values)
          end
        else
          if values['name'] != values['empty']
            for vm_type in values['valid-vm']
              values['vm'] = vm_type
              exists = check_vm_exists(values)
              if exists == "yes"
                control_vm(values)
              end
            end
          else
            if values['name'] == values['empty']
              handle_output(values, "Warning:\tClient name not specified")
            end
          end
        end
      end
    when /restart|reboot/
      if values['service'] != values['empty']
        eval"[restart_#{values['service']}]"
      else
        if values['vm'] == values['empty'] && values['name'] != values['empty']
          values['vm'] = get_client_vm_type(values)
        end
        if values['vm'].to_s.match(/aws/)
          values = reboot_aws_vm(values)
          return values
        end
        if values['vm'] != values['empty']
          if values['name'] != values['empty']
            stop_vm(values)
            boot_vm(values)
          else
            handle_output(values, "Warning:\tClient name not specified")
          end
        else
          if values['name'] != values['empty']
            for vm_type in values['valid-vm']
              values['vm'] = vm_type
              exists = check_vm_exists(values)
              if exists == "yes"
                stop_vm(values)
                boot_vm(values)
                return values
              end
            end
          else
            handle_output(values, "Warning:\tInstall service or VM type not specified")
          end
        end
      end
    when /import/
      if values['file'] == values['empty']
        if values['type'].to_s.match(/packer/)
          import_packer_vm(values)
        end
      else
        if values['vm'].to_s.match(/fusion|vbox|kvm/)
          if values['file'].to_s.match(/ova/)
            if !values['vm'].to_s.match(/kvm/)
              set_ovfbin
            end
            import_ova(values)
          else
            if values['file'].to_s.match(/vmdk/)
              import_vmdk(values)
            end
          end
        end
      end
    when /export/
      if values['vm'].to_s.match(/fusion|vbox/)
        eval"[export_#{values['vm']}_ova(values)]"
      end
      if values['vm'].to_s.match(/aws/)
        export_aws_image(values)
      end
    when /clone|copy/
      if values['clone'] != values['empty'] && values['name'] != values['empty']
        eval"[clone_#{values['vm']}_vm(values)]"
      else
        handle_output(values, "Warning:\tClient name or clone name not specified")
      end
    when /running|stopped|suspended|paused/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval"[list_#{values['action']}_#{values['vm']}_vms]"
      end
    when /crypt/
      values['crypt'] = get_password_crypt(values)
      handle_output(values, "")
    when /post/
      eval"[execute_#{values['vm']}_post(values)]"
    when /change|modify/
      if values['name'] != values['empty']
        if values['memory'].to_s.match(/[0-9]/)
          eval"[change_#{values['vm']}_vm_mem(values)]"
        end
        if values['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
          eval"[change_#{values['vm']}_vm_mac(values)]"
        end
      else
        handle_output(values, "Warning:\tClient name not specified")
      end
    when /attach/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval"[attach_file_to_#{values['vm']}_vm(values)]"
      end
    when /detach/
      if values['vm'] != values['empty'] && values['name'] != values['empty'] && values['vm'] != values['empty']
        eval"[detach_file_from_#{values['vm']}_vm(values)]"
      else
        handle_output(values, "Warning:\tClient name or virtualisation platform not specified")
      end
    when /share/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval"[add_shared_folder_to_#{values['vm']}_vm(values)]"
      end
    when /^snapshot|clone/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        if values['name'] != values['empty']
          eval"[snapshot_#{values['vm']}_vm(values)]"
        else
          handle_output(values, "Warning:\tClient name not specified")
        end
      end
    when /migrate/
      eval"[migrate_#{values['vm']}_vm(values)]"
    when /deploy/
      if values['type'].to_s.match(/vcsa/)
        set_ovfbin
        values['file'] = handle_vcsa_ova(values)
        deploy_vcsa_vm(values)
      else
        eval"[deploy_#{values['vm']}_vm(values)]"
      end
    when /restore|revert/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        if values['name'] != values['empty']
          eval"[restore_#{values['vm']}_vm_snapshot(values)]"
        else
          handle_output(values, "Warning:\tClient name not specified")
        end
      end
    when /set/
      if values['vm'] != values['empty']
        eval"[set_#{values['vm']}_value(values)]"
      end
    when /get/
      if values['vm'] != values['empty']
        eval"[get_#{values['vm']}_value(values)]"
      end
    when /console|serial|connect|ssh/
      if values['vm'].to_s.match(/kvm/)
        connect_to_kvm_vm(values)
      end
      if values['vm'].to_s.match(/mp|multipass/)
        connect_to_multipass_vm((values))
        return values
      end
      if values['vm'].to_s.match(/aws/) || values['id'].to_s.match(/[0-9]/)
        connect_to_aws_vm(values)
        return values
      end
      if values['type'].to_s.match(/docker/)
        connect_to_docker_client(values)
      end
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        if values['name'] != values['empty']
          connect_to_virtual_serial(values)
        else
          handle_output(values, "Warning:\tClient name not specified")
        end
      end
    else
      handle_output(values, "Warning:\tAction #{values['method']}")
    end
  end
  return values
end

if values['name'].to_s.match(/\,/)
  host_list = values['name'].to_s.split(",")
  ip_list   = []
  mac_list  = []
  vcpu_list = []
  mem_list  = []
  disk_list = []
  rel_list  = []
  if values['ip'].to_s.match(/\,/)
    ip_list = values['ip'].to_s.split(",")
  end
  if values['mac'].to_s.match(/\,/)
    mac_list = values['mac'].to_s.split(",")
  end
  if values['memory'].to_s.match(/\,/)
    mem_list = values['memory'].to_s.split(",")
  end
  if values['vcpus'].to_s.match(/\,/)
    vcpus_list = values['vcpus'].to_s.split(",")
  end
  if values['disk'].to_s.match(/\,/)
    disk_list = values['disk'].to_s.split(",")
  end
  if values['release'].to_s.match(/\,/)
    rel_list = values['release'].to_s.split(",")
  end
  host_list.each_with_index do |host_name, counter|
    values['name'] = host_name
    if ip_list[counter]
      values['ip'] = ip_list[counter]
    end
    if mac_list[counter]
      values['mac'] = mac_list[counter]
    else
      values['mac'] = generate_mac_address(values)
    end
    if mem_list[counter]
      values['memory'] = mem_list[counter]
    end
    if vcpu_list[counter]
      values['vcpus'] = vcpus_list[counter]
    end
    if rel_list[counter]
      values['release'] = rel_list[counter]
    end
    if disk_list[counter]
      values['disk'] = disk_list[counter]
    else
      values['disk'] = values['empty']
    end
    handle_action(values)
  end
else
  values = handle_action(values)
end

quit(values)
