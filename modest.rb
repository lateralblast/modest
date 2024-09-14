#!/usr/bin/env ruby

# Name:         modest (Multi OS Deployment Engine Server Tool)
# Version:      7.9.8
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
  return
end

# Verbose output

def verbose_output(values, text)
  if values['verbose'] == true or values['notice'] == true
    handle_output(values, text)
  end
  return
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
      verbose_output(values, "Information:\tLoading module #{file}")
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
    verbose_output(values, "Invalid command line option: #{switch}")
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
    ['--admingecos', REQUIRED],       # Admin GECOS field 
    ['--admingroup', REQUIRED],       # Admin user Group for client VM to be created
    ['--adminhome', REQUIRED],        # Admin user Home directory for client VM to be created
    ['--adminshell', REQUIRED],       # Admin user shell for client VM to be created
    ['--adminsudo', REQUIRED],        # Admin sudo command for client VM to be created
    ['--adminuid', REQUIRED],         # Admin user UID for client VM to be created
    ['--adminuser', REQUIRED],        # Admin username for client VM to be created
    ['--adminpassword', REQUIRED],    # Client admin password
    ['--admincrypt', REQUIRED],       # Password crypt
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
    ['--checknat', BOOLEAN],          # Check NAT configuration
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
    ['--group', REQUIRED],            # Group Name (e.g. AWS)
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
    ['--hostname', REQUIRED],         # Hostname
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
    ['--lockpassword', BOOLEAN],      # Lock password
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
    ['--notice', BOOLEAN],            # Print notice messages
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
    ['--rootcrypt', REQUIRED],        # Client root password
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
    ['--sshkey', REQUIRED],           # SSH Key
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
    ['--sudoers', REQUIRED],          # Sudoers entry
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
    ['--userpassword', REQUIRED],     # User password
    ['--usercrypt', REQUIRED],        # User password crypt
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

values = handle_values(values)

# Set up some initital defaults

values['stdout']  = []

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
          verbose_output(defaults, "Warning:\tOption --#{raw_param} has an invalid value: #{values[raw_param]}")
          verbose_output(defaults, "Information:\tValid values for --#{raw_param} are: \n #{defaults[valid_param].to_s}")
          quit(defaults)
        end
      end
    end
  end
end

# If we've been given a file try to get os and other insformation from file

values = handle_mount_values(values)

# Set SSH port

values = set_ssh_port(values)

# Reset defaults based on updated values

defaults = reset_defaults(values, defaults)

# Process values based on defaults

values = process_values(values, defaults)

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
    verbose_output(values, "Warning:\tSetup script '#{values['setup']}' not found")
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
    verbose_output(values, "Warning:\tNo service of client name specified")
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
    verbose_output(values, "Warning:\tNo VM type specified")
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

# Handle SSH key values

values = handle_ssh_key_values(values)

# Handle AWS credentials

values = handles_aws_values(values)

# Handle client name switch

if values['name'] != values['empty']
  check_hostname(values)
  if values['verbose'] == true
    verbose_output(values, "Information:\tSetting client name to #{values['name']}")
  end
end

# If specified admin set admin user

values = handle_admin_user_values(values)

# Handle architecture values

values = handle_arch_values(values)

# Handle install shell

values = handle_install_shell_values(values)

# Handle share switch

values = handle_share_values(values)

# Handle timezone values

values = handle_timezone_values(values)

# Handle clone switch

values = handle_clone_values(values)

# Handle option size

values = handle_size_values(values)

# Try to determine install method when given just a file/ISO

values = handle_file_values(values)

# Handle values and parameters

if values['param'] != values['empty']
  if !values['action'].to_s.match(/get/)
    if !values['value']
      verbose_output(values, "Warning:\tSetting a parameter requires a value")
      quit(values)
    else
      if !values['value']
        verbose_output(values, "Warning:\tSetting a parameter requires a value")
        quit(values)
      end
    end
  end
end

if values['value'] != values['empty']
  if values['param'] == values['empty']
    verbose_output(values, "Warning:\tSetting a value requires a parameter")
    quit(values)
  end
end

# Handle LDoms

values = handle_ldom_values(values)

# Handle Packer and VirtualBox not supporting hostonly or bridged network

if !values['vmnetwork'].to_s.match(/nat/)
  if values['vm'].to_s.match(/virtualbox|vbox/)
    if values['type'].to_s.match(/packer/) || values['method'].to_s.match(/packer/) && !values['action'].to_s.match(/delete|import/)
      verbose_output(values, "Warning:\tPacker has a bug that causes issues with Hostonly and Bridged network on VirtualBox")
      verbose_output(values, "Warning:\tTo deal with this an addition port may be added to the SSH daemon config file")
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

values = handle_import_build_action(values)

if values['ssopassword'] != values['empty']
  values['adminpassword'] = values['ssopassword']
end

# Get Netmask

if values['netmask'] == values['empty']
  if values['type'].to_s.match(/vcsa/)
    values['netmask'] = $default_cidr
  end
end

# Handle deploy action

values = handle_deploy_action(values)

# Handle console values

values = handle_console_values(values)

# Handle list option for action switch

values = handle_list_action(values)

# Handle action switch

values = handle_vm_action(values)

# Handle packer type

values = handle_packer_type(values)

# Handle install service switch

if values['service'] != values['empty']
  if values['verbose'] == true
    verbose_output(values, "Information:\tSetting install service to #{values['service']}")
  end
end

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

values = hacnle_packer_import_action(values)

# Handle release values

values = handle_release_values(values)

# Handle OS values

values = handle_os_values(values)

# Handle memory values

values = handle_memory_values(values)

# Get/set publisher port (Used for configuring AI server)

values = handle_publisher_values(values)

# If service is set, but method and os isn't specified, try to set method from service name

if values['service'] != values['empty'] && values['method'] == values['empty'] && values['os-type'] == values['empty']
  values['method'] = get_install_method_from_service(values)
else
  if values['method'] == values['empty'] && values['os-type'] == values['empty']
    values['method'] = get_install_method_from_service(values)
  end
end

# Handle VM switch

values = handle_vm_values(values)

# Check OS switch

values = handle_os_values(values)

# Handle install method

values = handle_install_method(values)

# Do a check to see if we are running Packer and trying to install Windows with network in non NAT mode

if values['type'].to_s.match(/packer/) && values['os-type'].to_s.match(/win/)
  if !values['vmnetwork'].to_s.match(/nat/)
    verbose_output(values, "Warning:\tPacker only supports installing Windows with a NAT network")
    verbose_output(values, "Information:\tSetting network to NAT mode")
    values['vmnetwork'] = "nat"
  end
  values['shell'] = "winrm"
end

# Handle VM named none

if values['action'].to_s.match(/create/) && values['name'] == "none" && values['mode'] != "server" and values['type'] != "service"
  verbose_output(values, "Warning:\tInvalid client name")
  quit(values)
end

# Handle multiple configs in one line if separated by a comma, or handle a sinlge config

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
