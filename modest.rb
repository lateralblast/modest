#!/usr/bin/env ruby
# frozen_string_literal: true

# Name:         modest (Multi OS Deployment Engine Server Tool)
# Version:      8.2.0
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
values['stdout']  = []
values['answers'] = {}
values['order']   = []
values['pkgs']    = {}

# Handle output

def handle_output(values, text)
  text = '<br>' if values['output'].to_s.match(/html/) && (text == '')
  puts text if values['output'].to_s.match(/text/)
  # values['stdout'].push(text)
  nil
end

# Verbose output

def verbose_message(values, text)
  handle_output(values, text) if (values['verbose'] == true) || (values['notice'] == true)
  nil
end

# Warning message

def warning_message(values, text)
  puts "Warning:\t#{text}" if values['silent'] == false
  nil
end

# Information message

def information_message(values, text)
  text = "Information:\t#{text}"
  handle_output(values, text)
  nil
end

# Execute message

def execute_message(values, text)
  text = "Executing:\t#{text}"
  handle_output(values, text)
  nil
end

# If given verbose switch/option enable verbose mode early

if ARGV.to_s.match(/verbose/)
  values['verbose'] = true
  values['output']  = 'text'
end

# If given dryrun switch/option enable dryrun mode early

values['dryrun'] = true if ARGV.to_s.match(/dryrun/)

# String class overrides

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
    to_i(from).to_s(to)
  end
end

# Function to install gems

def install_gem(load_name)
  install_name = case load_name
                 when 'unix_crypt'
                   'unix-crypt'
                 when 'getopt/long'
                   'getopt'
                 when 'capistrano'
                   'rvm-capistrano'
                 when 'net/scp'
                   'net-scp'
                 when 'net/ssh'
                   'net-ssh'
                 when 'terminfo'
                   'ruby-terminfo'
                 else
                   load_name
                 end
  puts "Information:\tInstalling #{install_name}"
  `gem install #{install_name}`
  Gem.clear_paths
  require load_name.to_s
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

['getopt/long', 'builder', 'parseconfig', 'unix_crypt', 'netaddr', 'json',
 'fileutils', 'ssh-config', 'yaml', 'net/ssh', 'net/scp', 'ipaddress'].each do |load_name|
  require load_name.to_s
rescue LoadError
  install_gem(load_name)
end

# Load methods

if File.directory?('./methods')
  file_list = Dir.glob('./methods/**/*')
  file_list.each do |file|
    if file =~ /rb$/
      information_message(values, "Loading module #{file}")
      require file.to_s
    end
  end
end

# Get command line arguments
# Print help if specified none

unless ARGV[0]
  values['output'] = 'text'
  print_help(values)
end

# Check whether we have any single - values

ARGV.each do |option|
  if option.match(/^-[a-z]/)
    puts "Invalid option #{option} in command line"
    exit
  end
end

# Try to make sure we have valid long switches

valid_values = get_valid_values(values)

ARGV.each do |switch|
  next unless !valid_values.grep(/--#{switch}/) || switch.match(/^-[a-z,A-Z][a-z,A-Z]/)

  verbose_message(values, "Invalid command line option: #{switch}")
  values['output'] = 'text'
  quit(values)
end

# Process values

include Getopt

begin
  values = Long.getopts(
    ['--accelerator', REQUIRED],        # Packer accelerator
    ['--access', REQUIRED],             # AWS Access Key
    ['--acl', REQUIRED],                # AWS ACL
    ['--action', REQUIRED],             # Action (e.g. boot, stop, create, delete, list, etc)
    ['--admingid', REQUIRED],           # Admin user GID for client VM to be created
    ['--admingecos', REQUIRED],         # Admin GECOS field
    ['--admingroup', REQUIRED],         # Admin user Group for client VM to be created
    ['--adminhome', REQUIRED],          # Admin user Home directory for client VM to be created
    ['--adminshell', REQUIRED],         # Admin user shell for client VM to be created
    ['--adminsudo', REQUIRED],          # Admin sudo command for client VM to be created
    ['--adminuid', REQUIRED],           # Admin user UID for client VM to be created
    ['--adminuser', REQUIRED],          # Admin username for client VM to be created
    ['--adminpassword', REQUIRED],      # Client admin password
    ['--admincrypt', REQUIRED],         # Password crypt
    ['--aidir', REQUIRED],              # Solaris AI Directory
    ['--aiport', REQUIRED],             # Solaris AI Port
    ['--ami', REQUIRED],                # AWS AMI ID
    ['--arch', REQUIRED],               # Architecture of client or VM (e.g. x86_64)
    ['--autoconsole', BOOLEAN],         # Autoconsole (KVM)
    ['--noautoconsole', BOOLEAN],       # No autoconsole (KVM)
    ['--audio', REQUIRED],              # Audio
    ['--auditsize', REQUIRED],          # Set audit fs size
    ['--auditfs', REQUIRED],            # Set audit fs
    ['--autostart', BOOLEAN],           # Autostart (KVM)
    ['--noautostart', BOOLEAN],         # No autostart (KVM)
    ['--autoyastfile', REQUIRED],       # AutoYaST file
    ['--awsuser', REQUIRED],            # AWS User
    ['--baserepodir', REQUIRED],        # Base repository directory
    ['--bename', REQUIRED],             # ZFS BE (Boot Environment) name
    ['--biosdevnames', BOOLEAN],        # Use biosdevnames (e.g. eth0 instead of eno1)
    ['--nobiosdevnames', BOOLEAN],      # Do not use biosdevnames (e.g. eth0 instead of eno1)
    ['--biostype', REQUIRED],           # BIOS boot type (bios/uefi)
    ['--blkiotune', REQUIRED],          # Block IO tune (KVM)
    ['--boot', REQUIRED],               # Set boot device
    ['--bootfs', REQUIRED],             # Set boot fs
    ['--bootcommand', REQUIRED],        # Packer Boot command
    ['--bootproto', REQUIRED],          # Set boot protocol
    ['--bootsize', REQUIRED],           # Set boot fs size
    ['--bootwait', REQUIRED],           # Packer Boot wait
    ['--bridge', REQUIRED],             # Set bridge
    ['--bucket', REQUIRED],             # AWS S3 bucket
    ['--build', BOOLEAN],               # Build (Packer)
    ['--nobuild', BOOLEAN],             # Do not build (Packer)
    ['--changelog', BOOLEAN],           # Print changelog
    ['--channel', BOOLEAN],             # Channel (KVM)
    ['--nochannel', BOOLEAN],           # No channel (KVM)
    ['--check', REQUIRED],              # Check
    ['--checknat', BOOLEAN],            # Check NAT configuration
    ['--checksum', BOOLEAN],            # Do checksums
    ['--nochecksum', BOOLEAN],          # Do not do checksums
    ['--cidr', REQUIRED],               # CIDR
    ['--client', REQUIRED],             # Client / AWS Name
    ['--clientdir', REQUIRED],          # Base Client Directory
    ['--clientnic', REQUIRED],          # Client NIC
    ['--clock', REQUIRED],              # Clock (KVM)
    ['--clone', REQUIRED],              # Clone name
    ['--cloudfile', REQUIRED],          # Cloud init config image (KVM)
    ['--cloudinitfile', REQUIRED],      # Cloud init config file (KVM)
    ['--command', REQUIRED],            # Run command
    ['--comment', REQUIRED],            # Comment
    ['--configfile', REQUIRED],         # Config file (KVM)
    ['--connect', REQUIRED],            # Connect (KVM)
    ['--console', REQUIRED],            # Select console type (e.g. text, serial, x11) (default is text)
    ['--container', BOOLEAN],           # AWS AMI export container
    ['--containertype', REQUIRED],      # AWS AMI export container
    ['--controller', REQUIRED],         # Specify disk controller
    ['--copykeys', BOOLEAN],            # Copy SSH Keys (default)
    ['--nocopykeys', BOOLEAN],          # Do not copy SSH Keys (default)
    ['--country', REQUIRED],            # Country
    ['--cpu', REQUIRED],                # Type of CPU (e.g. KVM CPU type)
    ['--cputune', REQUIRED],            # CPU tune (KVM)
    ['--cputype', REQUIRED],            # CPU type (KVM)
    ['--creds', REQUIRED],              # Credentials file
    ['--datastore', REQUIRED],          # Datastore to deploy to on remote server
    ['--defaults', BOOLEAN],            # Answer defaults to all questions (accept defaults)
    ['--nodefaults', BOOLEAN],          # Do not answer defaults to all questions (accept defaults)
    ['--delete', BOOLEAN],              # Delete client / service
    ['--nodelete', BOOLEAN],            # Do not delete client / service
    ['--desc', REQUIRED],               # Description
    ['--destroy-on-exit', BOOLEAN],     # Destroy on exit (KVM)
    ['--nodestroy-on-exit', BOOLEAN],   # Do not destroy on exit (KVM)
    ['--dhcp', BOOLEAN],                # DHCP
    ['--nodhcp', BOOLEAN],              # No DHCP
    ['--dhcpdfile', REQUIRED],          # DHCP Config file
    ['--dhcpdrange', REQUIRED],         # Set DHCP range
    ['--dir', REQUIRED],                # Directory / Direction
    ['--disk', REQUIRED],               # Disk file / KVM disk file entry
    ['--disk1', REQUIRED],              # Disk file
    ['--disk2', REQUIRED],              # Disk file
    ['--diskformat', REQUIRED],         # KVM Disk format
    ['--disksize', REQUIRED],           # Packer Disk size
    ['--diskinterface', REQUIRED],      # Disk interface
    ['--dnsmasq', BOOLEAN],             # Update / Check DNSmasq
    ['--nodnsmasq', BOOLEAN],           # No DNSmasq Update / Check
    ['--diskmode', REQUIRED],           # Disk mode (e.g. thin)
    ['--domainname', REQUIRED],         # Set domain (Used with deploy for VCSA)
    ['--dryrun', BOOLEAN],              # Dryrun flag
    ['--nodryrun', BOOLEAN],            # No dryrun flag
    ['--email', REQUIRED],              # AWS ACL email
    ['--empty', REQUIRED],              # Empty / Null value
    ['--enable', REQUIRED],             # Enable flag
    ['--enableethernet', BOOLEAN],      # Enable ethernet flag
    ['--disableethernet', BOOLEAN],     # Disable ethernet flag
    ['--enablevhv', BOOLEAN],           # Enable VHV flag
    ['--disablevhv', BOOLEAN],          # Disable VHV flag
    ['--enablevnc', BOOLEAN],           # Enable VNC flag
    ['--disablevnc', BOOLEAN],          # Disable VNC flag
    ['--environment', REQUIRED],        # Environment
    ['--epel', REQUIRED],               # EPEL Mirror
    ['--ethernetdevice', REQUIRED],     # Ethernet device (e.g. e1000)
    ['--events', REQUIRED],             # Events (KVM))
    ['--exportdir', REQUIRED],          # Export directory
    ['--extra-args', REQUIRED],         # Extra args (KVM)
    ['--features', REQUIRED],          # Features (KVM)
    ['--file', REQUIRED],              # File, eg ISO
    ['--filedir', REQUIRED],            # File / ISO Directory
    ['--files', REQUIRED],              # Set default files resolution entry, eg "dns, files"
    ['--filesystem', REQUIRED],         # Filesystem (KVM)
    ['--finish', REQUIRED],             # Jumpstart finish file
    ['--force',  BOOLEAN],              # Force mode
    ['--noforce', BOOLEAN], # Do not use force mode
    ['--format', REQUIRED],             # AWS / Output disk format (e.g. VMDK, RAW, VHD)
    ['--from', REQUIRED],               # From
    ['--fusiondir', REQUIRED],          # VMware Fusion Directory
    ['--gateway', REQUIRED],            # Gateway IP
    ['--gatewaynode', REQUIRED],        # Gateway Node
    ['--graphics', REQUIRED],           # Graphics (KVM)
    ['--grant', REQUIRED],              # AWS ACL grant
    ['--growpart', BOOLEAN],            # Grow partition
    ['--nogrowpart', BOOLEAN],          # Do not grow partition
    ['--growpartdevice', REQUIRED],     # Grow partition device
    ['--growpartmode', REQUIRED],       # Groe part mode
    ['--group', REQUIRED],              # Group Name (e.g. AWS)
    ['--guest', REQUIRED],              # Guest OS
    ['--gwifname', REQUIRED],           # Gateway Interface name
    ['--headless', BOOLEAN],            # Headless mode for builds
    ['--noheadless', BOOLEAN],          # Do not use headless mode for builds
    ['--help', BOOLEAN],                # Display usage information
    ['--home', REQUIRED],               # Set home directory
    ['--homefs', REQUIRED],             # Set home fs
    ['--homesize', REQUIRED],           # Set home fs size
    ['--host', REQUIRED],               # Type of host (e.g. Docker)
    ['--hostdev', REQUIRED],            # Host device (KVM)
    ['--hostnet', REQUIRED],            # Host network
    ['--hostonlyip', REQUIRED],         # Hostonly IP
    ['--hostname', REQUIRED],           # Hostname
    ['--hosts', REQUIRED],              # Set default hosts resolution entry, eg "files"
    ['--host-device', REQUIRED],        # Host device (e.g. KVM passthough)
    ['--httpbindaddress', REQUIRED],    # Packer HTTP bind address
    ['--httpdirectory', REQUIRED],      # Packer HTTP directory
    ['--httpportmax', REQUIRED],        # Packer HTTP port max
    ['--httpportmin', REQUIRED],        # Packer HTTP port min
    ['--hvm', BOOLEAN],                 # HVM (KVM)
    ['--hwversion', REQUIRED],          # VMware Hardware Version
    ['--hwvirtex', REQUIRED],           # hwvirtex (on/off)
    ['--id', REQUIRED],                 # AWS Instance ID
    ['--idmap', REQUIRED],              # ID map (KVM)
    ['--ifname', REQUIRED],             # Interface number / name
    ['--imagedir', REQUIRED],           # Base Image Directory
    ['--import', BOOLEAN],              # Import (KVM)
    ['--info', REQUIRED],               # Used with info option
    ['--initrd-inject', REQUIRED],      # Inject initrd (KVM)
    ['--inputfile', REQUIRED],          # Input file (KVM)
    ['--install', REQUIRED],            # Install (KVM)
    ['--installdrivers', BOOLEAN],      # Install Drivers
    ['--dontinstalldrivers', BOOLEAN],  # Do not install Drivers
    ['--installsecurity', BOOLEAN],     # Install Security Updates
    ['--donginstallsecurity', BOOLEAN], # Do not install Security Updates
    ['--installupdates', BOOLEAN],      # Install Package Updates
    ['--dontinstallupdates', BOOLEAN],  # Do not install Package Updates
    ['--installupgrades', BOOLEAN],     # Install Package Upgrades
    ['--dontinstallupgrades', BOOLEAN], # Do not install Package Upgrades
    ['--iothreads', REQUIRED],          # IO threads (KVM)
    ['--ip', REQUIRED],                 # IP Address of client
    ['--ipfamily', REQUIRED],           # IP family (e.g. IPv4 or IPv6)
    ['--ips', REQUIRED],                # IP Addresses of client
    ['--isochecksum', REQUIRED],        # Packer ISO checksum
    ['--isodir', REQUIRED],             # ISO Directory
    ['--isourl', REQUIRED],             # Packer ISO URL
    ['--ldomdir', REQUIRED],            # Base LDom Directory
    ['--jsonfile', REQUIRED],           # JSON file
    ['--karch', REQUIRED],              # Solaris Jumpstart karch
    ['--kernel', REQUIRED],             # Kernel
    ['--key', REQUIRED],                # AWS Key Name
    ['--keydir', REQUIRED],             # AWS Key Dir
    ['--keyfile', REQUIRED],            # AWS Keyfile
    ['--keymap', REQUIRED],             # Key map
    ['--keyname', REQUIRED],            # AWS Key name (defaults to region)
    ['--kickstartfile', REQUIRED],      # Kickstart file
    ['--kvmgid', REQUIRED],             # Set KVM gid
    ['--kvmgroup', REQUIRED],           # Set KVM group
    ['--launchSecurity', REQUIRED],     # Launch Security (KVM)
    ['--license', REQUIRED],            # License key (e.g. ESX)
    ['--list', BOOLEAN],                # List items
    ['--livecd', BOOLEAN],              # Specify Live CD (Changes install method)
    ['--locale', REQUIRED],             # Select language/language (e.g. en_US)
    ['--localfs', REQUIRED],            # Set local fs
    ['--localsize', REQUIRED],          # Set local fs size
    ['--lockpassword', BOOLEAN],        # Lock password
    ['--logfs', REQUIRED],              # Set log fs
    ['--logsize', REQUIRED],            # Set log fs size
    ['--lxcdir', REQUIRED],             # Linux Container Directory
    ['--lxcimagedir', REQUIRED],        # Linux Image Directory
    ['--mac', REQUIRED],                # MAC Address
    ['--machine', REQUIRED],            # Solaris Jumpstart Machine file
    ['--masked', BOOLEAN],              # Mask passwords in output (WIP)
    ['--unmasked', BOOLEAN],            # Unmask passwords in output (WIP)
    ['--memballoon', REQUIRED],         # VM memory balloon
    ['--memdev', REQUIRED],             # Memdev (KVM)
    ['--memory', REQUIRED],             # VM memory size
    ['--memorybacking', REQUIRED],      # VM memory backing (KVM)
    ['--memtune', REQUIRED],            # VM memory tune (KVM)
    ['--metadata', REQUIRED],           # Metadata (KVM)
    ['--method', REQUIRED],             # Install method (e.g. Kickstart)
    ['--mirror', REQUIRED],             # Mirror / Repo
    ['--mirrordisk', BOOLEAN],          # Mirror disk as part of post install
    ['--mode', REQUIRED],               # Set mode to client or server
    ['--model', REQUIRED],              # Model
    ['--mountdir', REQUIRED],           # Mount point
    ['--mouse', REQUIRED],              # Mouse
    ['--name', REQUIRED],               # Client / AWS Name
    ['--nameserver', REQUIRED],         # Delete client or VM
    ['--net', REQUIRED],                # Default Solaris Network (Solaris 11)
    ['--netbootdir', REQUIRED],         # Netboot directory (Solaris 11 tftpboot directory)
    ['--netbridge', REQUIRED],          # Packer Net bridge
    ['--netdevice', REQUIRED],          # Packer Net device
    ['--netmask', REQUIRED],            # Set netmask
    ['--network', REQUIRED],            # Network (KVM)
    ['--networkfile', REQUIRED],        # Network config file (KVM)
    ['--nic', REQUIRED],                # Default NIC
    ['--noboot', BOOLEAN],              # Create VM/configs but do not boot
    ['--nobuild', BOOLEAN],             # Create VM/configs but do not build
    ['--noeeys', BOOLEAN],              # Do not copy SSH Keys
    ['--noreboot', BOOLEAN],            # Do not reboot as part of post script (used for troubleshooting)
    ['--nosudo', BOOLEAN],              # Use sudo
    ['--nosuffix', BOOLEAN],            # Do not add suffix to AWS AMI names
    ['--notice', BOOLEAN],              # Print notice messages
    ['--novncdir', REQUIRED],           # NoVNC directory
    ['--number', REQUIRED],             # Number of AWS instances
    ['--object', REQUIRED],             # AWS S3 object
    ['--opencsw', REQUIRED],            # OpenCSW Mirror / Repo
    ['--options', REQUIRED],            # Options
    ['--os-info', REQUIRED],            # OS Info
    ['--os-type', REQUIRED],            # OS Type
    ['--os-variant', REQUIRED],         # OS Variant
    ['--output', REQUIRED],             # Output format (e.g. text/html)
    ['--outputdirectory', REQUIRED],    # Packer output directory
    ['--outputfile', REQUIRED],         # Output file (KVM)
    ['--packages', REQUIRED],           # Specify additional packages to install
    ['--packer', REQUIRED],             # Packer binary
    ['--packersshport', REQUIRED],      # Packer binary
    ['--packerversion', REQUIRED],      # Packer version
    ['--panic', REQUIRED],              # Panic (KVM)
    ['--parallel', REQUIRED],           # Parallel (KVM)
    ['--param', REQUIRED],              # Set a parameter of a VM
    ['--paravirt', BOOLEAN],            # Paravirt (KVM)
    ['--noparavirt', BOOLEAN],          # No paravirt (KVM)
    ['--perms', REQUIRED],              # AWS perms
    ['--pkgdir', REQUIRED],             # Base Package Directory
    ['--pm', REQUIRED],                 # PM (KVM)
    ['--pool', REQUIRED],               # Pool (KVM)
    ['--ports', REQUIRED],              # Port (makes to and from the same in the case of and IP rule)
    ['--post', REQUIRED],               # Post install configuration
    ['--postscript', REQUIRED],         # Post install script
    ['--powerstate', REQUIRED],         # Powermode for cloud-init (e.g. reboot/noreboot)
    ['--preseedfile', REQUIRED],        # Preseed file
    ['--prefix', REQUIRED],             # AWS S3 prefix
    ['--preservesources', BOOLEAN],     # Preserve Sources List
    ['--dontpreservesources', BOOLEAN], # Preserve Sources List
    ['--print-xml', REQUIRED],          # Print XML (KVM)
    ['--proto', REQUIRED],              # Protocol
    ['--publisher', REQUIRED],          # Set publisher information (Solaris AI)
    ['--publisherhost', REQUIRED],      # Publisher host
    ['--publisherport', REQUIRED],      # Publisher port
    ['--publisherurl', REQUIRED],       # Publisher URL
    ['--pxe', BOOLEAN],                 # PXE (KVM)
    ['--nopxe', BOOLEAN],               # No PXE (KVM)
    ['--pxebootdir', REQUIRED],         # PXE boot dir
    ['--qemu-commandline', REQUIRED],   # Qemu commandline (KVM)
    ['--reboot', BOOLEAN],              # Reboot as part of post script
    ['--noreboot', BOOLEAN],            # Do not reboot as part of post script
    ['--dontreboot', BOOLEAN],          # Do not reboot as part of post script
    ['--redirdev', REQUIRED],           # Redirdev (KVM)
    ['--release', REQUIRED],            # OS Release
    ['--region', REQUIRED],             # AWS Region
    ['--repo', REQUIRED],               # Set repository
    ['--repodir', REQUIRED],            # Base Repository Directory
    ['--resource', REQUIRED],           # Resource (KVM)
    ['--restart', BOOLEAN],             # Re-start VM
    ['--norestart', BOOLEAN],           # Do not re-start VM
    ['--dontrestart', BOOLEAN],         # Do not re-start VM
    ['--rng', REQUIRED],                # RNG (KVM)
    ['--rootdisk', REQUIRED],           # Set root device to install to
    ['--rootfs', REQUIRED],             # Set root fs
    ['--rootpassword', REQUIRED],       # Client root password
    ['--rootcrypt', REQUIRED],          # Client root password
    ['--rootsize', REQUIRED],           # Set root device size in M
    ['--rootuser', REQUIRED],           # Set root user name
    ['--rpoolname', REQUIRED],          # Solaris rpool name
    ['--rtcuseutc', REQUIRED],          # rtcuseutc
    ['--rules', REQUIRED],              # Solaris Jumpstart rules file
    ['--scratchfs', REQUIRED],          # Set root fs
    ['--scratchsize', REQUIRED],        # Set root device size in M
    ['--scriptname', REQUIRED],         # Set scriptname
    ['--search', REQUIRED],             # Search string
    ['--seclabel', REQUIRED],           # Seclabel (KVM)
    ['--secret', REQUIRED],             # AWS Secret Key
    ['--serial', BOOLEAN],              # Serial
    ['--noserial', BOOLEAN],            # No Serial
    ['--sharedfolder', REQUIRED],       # Install shell (used for packer, e.g. winrm, ssh)
    ['--shell', REQUIRED],              # Install shell (used for packer, e.g. winrm, ssh)
    ['--size', REQUIRED],               # VM disk size (if used with deploy action, this sets the size of the VM, e.g. tiny)
    ['--server', REQUIRED],             # Server name/IP (allow execution of commands on a remote host, or deploy to)
    ['--serveradmin', REQUIRED],        # Admin username for server to deploy to
    ['--servernetwork', REQUIRED],      # Server network (used when deploying to a remote server)
    ['--servernetmask', REQUIRED],      # Server netmask (used when deploying to a remote server)
    ['--serverpassword', REQUIRED],     # Admin password of server to deploy to
    ['--service', REQUIRED],            # Service name
    ['--setup', REQUIRED],              # Setup script
    ['--share', REQUIRED],              # Shared folder
    ['--shutdowncommand', REQUIRED],    # Packer Shutdown command
    ['--shutdowntimeout', REQUIRED],    # Packer Shutdown timeout
    ['--silent', BOOLEAN],              # Run in silent mode (do not print warning messages)
    ['--sitename', REQUIRED],           # Sitename for VCSA
    ['--smartcard', REQUIRED],          # Smartcard (KVM)
    ['--snapshot', REQUIRED],           # AWS snapshot
    ['--socker', REQUIRED],             # Socket file
    ['--sound', REQUIRED],              # Sound (KVM)
    ['--splitvols', BOOLEAN],           # Split volumes, e.g. seperate /, /var, etc
    ['--nosplitvols', BOOLEAN],         # Do not split volumes, e.g. seperate /, /var, etc
    ['--sshkey', REQUIRED],             # SSH Key
    ['--usesshkey', BOOLEAN],           # Use SSH key
    ['--dontusesshkey', BOOLEAN],       # Do not use SSH key
    ['--sshkeyfile', REQUIRED],         # SSH Keyfile
    ['--sshpassword', REQUIRED],        # Packer SSH Port min
    ['--sshport', REQUIRED],            # SSH Port
    ['--sshportmax', REQUIRED],         # Packer SSH Port max
    ['--sshportmin', REQUIRED],         # Packer SSH Port min
    ['--sshusername', REQUIRED],        # Packer SSH Port min
    ['--sshpty', BOOLEAN],              # Packer SSH PTY
    ['--ssopassword', REQUIRED],        # SSO password
    ['--stack', REQUIRED],              # AWS CF Stack
    ['--start', BOOLEAN],               # Start VM
    ['--dontstart', BOOLEAN],           # Do not start VM
    ['--stop', BOOLEAN],                # Stop VM
    ['--dontstop', BOOLEAN],            # Do not stop VM
    ['--strict', BOOLEAN],              # Ignore SSH keys
    ['--sudo', BOOLEAN],                # Use sudo
    ['--nosudo', BOOLEAN],              # Do not use sudo
    ['--sudoers', REQUIRED],            # Sudoers entry
    ['--sudogroup', REQUIRED],          # Set Sudo group
    ['--suffix', REQUIRED],             # AWS AMI Name suffix
    ['--sysid', REQUIRED],              # Solaris Jumpstart sysid file
    ['--sysinfo', REQUIRED],            # Sysinfo (KVM)
    ['--target', REQUIRED],             # AWS target format (e.g. citrix, vmware, windows)
    ['--techpreview', BOOLEAN],         # Use VMware tech preview if available
    ['--terminal', REQUIRED],           # Terminal type
    ['--tftpdir', REQUIRED],            # TFTP Directory
    ['--time', REQUIRED],               # Set time e.g. Eastern Standard Time
    ['--timeserver', REQUIRED],         # Set NTP server IP / Address
    ['--timezone', REQUIRED],           # Set timezone e.g. Australia/Victoria
    ['--tmpfs', REQUIRED],              # Set tmp fs
    ['--tmpsize', REQUIRED],            # Set tmp fs size
    ['--to', REQUIRED],                 # To
    ['--tpm', REQUIRED],                # TPM (KVM)
    ['--transient', BOOLEAN],           # Transient (KVM)
    ['--notransient', BOOLEAN],         # No transient (KVM)
    ['--trunk', REQUIRED],              # Mirror Trunk (e.g. stable)
    ['--type', REQUIRED],               # Install type (e.g. ISO, client, OVA, Network)
    ['--uid', REQUIRED],                # UID
    ['--unattended', BOOLEAN],          # Unattended (KVM)
    ['--userpassword', REQUIRED],       # User password
    ['--usage', REQUIRED],              # Usage information
    ['--usercrypt', REQUIRED],          # User password crypt
    ['--usrfs', REQUIRED],              # Set usr fs
    ['--usrsize', REQUIRED],            # Set usr fs size
    ['--utc', REQUIRED],                # UTC off/on
    ['--value', REQUIRED],              # Set the value of a parameter
    ['--varfs', REQUIRED],              # Set var fs
    ['--varsize', REQUIRED],            # Set var fs size
    ['--vcpus', REQUIRED],              # Number of CPUs
    ['--verbose', BOOLEAN],             # Verbose mode
    ['--version', BOOLEAN],             # Display version information
    ['--video', BOOLEAN],               # Video (KVM)
    ['--novideo', BOOLEAN],             # No video (KVM)
    ['--virtdir', REQUIRED],            # Base Client / KVM Directory
    ['--virtiofile', REQUIRED],         # VirtIO driver file/cdrom
    ['--virtualdevice', REQUIRED],      # Virtual disk device (e.g. lsilogic)
    ['--virt-type', REQUIRED],          # Virtualisation type (KVM)
    ['--vlanid', REQUIRED],            # VLAN ID
    ['--vm', REQUIRED],                # VM type
    ['--vmdir', REQUIRED],             # VM Directory
    ['--vmdkfile', REQUIRED], # VMDK file
    ['--vmnet', REQUIRED],             # VM Network (e.g. vmnet1 or vboxnet0)
    ['--vmnetdhcp', BOOLEAN],          # VM Network DHCP
    ['--vmgateway', REQUIRED],          # Set VM network gateway
    ['--vmnetwork', REQUIRED],          # Set network type (e.g. hostonly, bridged, nat)
    ['--vmnic', REQUIRED], # VM NIC (e.g. eth0)
    ['--vmtools', REQUIRED],            # Install VM tools or Guest Additions
    ['--vmtype',  REQUIRED],            # VM type
    ['--vmxfile', REQUIRED],            # VMX file
    ['--vncpassword', REQUIRED],        # VNC password
    ['--vsock', REQUIRED], # vSock (KVM)
    ['--vswitch',  REQUIRED],           # vSwitch
    ['--vtxvpid',  REQUIRED],           # vtxvpid
    ['--vtxux', REQUIRED], # vtxux
    ['--wait', REQUIRED],               # Wait (KVM)
    ['--winshell', REQUIRED],           # Packer Windows remote action shell (e.g. winrm)
    ['--winrminsecure', BOOLEAN],       # Packer winrm insecure
    ['--winrmport', REQUIRED],          # Packer winrm port
    ['--winrmusessl', BOOLEAN],         # Packer winrm use SSL
    ['--watchdog', REQUIRED],           # Watchdog (KVM)
    ['--workdir', REQUIRED],            # Base Work Directory
    ['--yes', REQUIRED],                # Answer yes to questions
    ['--zone', REQUIRED],               # Zone file
    ['--zonedir', REQUIRED],            # Base Zone Directory
    ['--zpool', REQUIRED]               # Boot zpool name
  )
rescue StandardError
  values['output'] = 'text'
  values['stdout'] = []
  print_help(values)
  quit(values)
end

# Handle usage

if values['usage'] && (values['usage'] != values['empty'])
  print_usage(values)
  quit(values)
end

# Set up some initital defaults

values['stdout'] = []

# Get defaults

defaults = {}
(values, defaults) = set_defaults(values, defaults)
defaults['stdout'] = []

# Check valid values

raw_params = IO.readlines(defaults['scriptfile']).grep(/REQUIRED|BOOLEAN/).join.split(/\n/)
raw_params.each do |raw_param|
  next unless raw_param.match(/\[/) && !raw_param.match(/^raw_params/)

  raw_param   = raw_param.split(/--/)[1].split(/'/)[0]
  valid_param = "valid-#{raw_param}"
  next unless values[raw_param] && defaults[valid_param]

  test_value = values[raw_param][0]
  test_value = test_value.split(',')[0] if test_value.match(/,/)
  next if defaults[valid_param].to_s.downcase.match(/#{test_value.downcase}/)

  verbose_message(defaults, "Warning:\tOption --#{raw_param} has an invalid value: #{values[raw_param]}")
  verbose_message(defaults,
                  "Information:\tValid values for --#{raw_param} are: \n #{defaults[valid_param]}")
  quit(defaults)
end

# If given verbose switch/option enable verbose mode early

if values['options'].to_s.match(/verbose/)
  values['verbose'] = true
  values['output']  = 'text'
end

# If given dryrun switch/option enable dryrun mode early

values['dryrun'] = true if values['options'].to_s.match(/dryrun/)

# Handle options

if values['options']
  information_message(values, 'Processing options')
  if values['options'].to_s.match(/[a-z]/)
    options = []
    if values['options'].to_s.match(/,/)
      options = values['options'].split(/,/)
    else
      options[0] = values['options']
    end
    options.each do |option|
      information_message(values, "Option #{option} is set to true")
      if option.match(/^no|^disable|^dont|^un/)
        temp_option = option.gsub(/^no|^dont|^un/, '')
        temp_option = temp_option.gsub(/disable/, 'enable')
        information_message(values, "Setting value #{temp_option} to false")
        values[temp_option] = false
      else
        values[option] = true
      end
    end
  end
end

# If we've been given a file try to get os and other insformation from file

values = handle_mount_values(values, defaults)

# Set SSH port

values = set_ssh_port(values)

# Reset defaults based on updated values

defaults = reset_defaults(values, defaults)

# Process values based on defaults

puts values['dhcp']

values = process_values(values, defaults)

# Post process values after handling defaults

values = post_process_values(values)

# Set some local configuration values like DHCP files etc

values = set_local_config(values)

# Clean up values

values = cleanup_values(values, defaults)

# Handle power state values

values = handle_power_state_values(values)

# Hanfle cloud-init values

values = handle_cloud_init_values(values)

# Handle libvirt/KVM values

values = handle_libvirt_values(values)

# Create required directories

check_dir_exists(values, values['workdir'])
[values['isodir'], values['repodir'], values['imagedir'], values['pkgdir'], values['clientdir']].each do |dir_name|
  check_zfs_fs_exists(values, dir_name)
end

# Handle setup

if (values['setup'] != values['empty']) && !File.exist?(values['setup'])
  warning_message(values, "Setup script '#{values['setup']}' not found")
  quit(values)
end

# Handle IPs option

values['ip'] = values['ips'] if values['ips']&.to_s&.match(/[0-9]/)

# If delete action chosen, check a client or service name is specified

if values['action'].to_s.match(/delete/) && values['name'] == values['empty'] && values['service'] == values['empty']
  warning_message(values, 'No service of client name specified')
  quit(values)
end

# If using AWS check for and load AWS CLI gem
# Removed this from the default check as it takes a long time to install

if values['vm']&.to_s&.match(/aws/)
  begin
    require 'aws-sdk'
  rescue LoadError
    install_gem('aws-sdk')
  end
end

# Check directory permissions perms by default

if values['action'].to_s.match(/check/) && values['check'].to_s.match(/perm|dir/)
  check_perms(values)
  quit(values)
end

# Handle base ISO dir when dir option set

values['isodir'] = values['dir'] if values['action'] == 'list' && values['type'].to_s.match(/iso|img|image/) && !values['dir'] == values['empty']

# Make sure a VM type is set for ansible

if values['type'].to_s.match(/ansible|packer/) && (values['vm'] == values['empty'])
  warning_message(values, 'No VM type specified')
  quit(values)
end

# Check packer is installed and is latest version

values = check_packer_is_installed(values) if values['type'].to_s.match(/packer/)

# Prime HTML

if values['output'].to_s.match(/html/)
  values['stdout'].push('<html>')
  values['stdout'].push('<head>')
  values['stdout'].push("<title>#{values['scriptname']}</title>")
  values['stdout'].push('</head>')
  values['stdout'].push('<body>')
end

# Handle SSH key values

values = handle_ssh_key_values(values)

# Handle AWS credentials

values = handle_aws_vm_values(values)

# Handle client name switch

if values['name'] != values['empty']
  check_hostname(values)
  information_message(values, "Setting client name to #{values['name']}") if values['verbose'] == true
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

if (values['param'] != values['empty']) && !values['action'].to_s.match(/get/)
  if !values['value']
    warning_message(values, 'Setting a parameter requires a value')
    quit(values)
  elsif !values['value']
    warning_message(values, 'Setting a parameter requires a value')
    quit(values)
  end
end

if (values['value'] != values['empty']) && (values['param'] == values['empty'])
  warning_message(values, 'Setting a value requires a parameter')
  quit(values)
end

# Handle LDoms

values = handle_ldom_values(values)

# Handle Packer and VirtualBox not supporting hostonly or bridged network

if !values['vmnetwork'].to_s.match(/nat/) && values['vm'].to_s.match(/virtualbox|vbox/) && (values['type'].to_s.match(/packer/) || values['method'].to_s.match(/packer/) && !values['action'].to_s.match(/delete|import/))
  warning_message(values, 'Packer has a bug that causes issues with Hostonly and Bridged network on VirtualBox')
  warning_message(values, 'To deal with this an addition port may be added to the SSH daemon config file')
end

# Set default host only Information

if (!values['vm'] == values['empty']) && (values['vmnetwork'] == 'hostonly' || values['vmnetwork'] == values['empty'])
  values['vmnetwork'] = 'hostonly'
  values = set_hostonly_info(values)
end

# Check network values

values = handle_network_values(values)

# Check action when set to build or import

values = handle_import_build_action(values)

values['adminpassword'] = values['ssopassword'] if values['ssopassword'] != values['empty']

# Get Netmask

values['netmask'] = $default_cidr if (values['netmask'] == values['empty']) && values['type'].to_s.match(/vcsa/)

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

information_message(values, "Setting install service to #{values['service']}") if (values['service'] != values['empty']) && (values['verbose'] == true)

# Make sure a service (e.g. packer) or an install file (e.g. OVA) is specified for an import

values = handle_packer_import_action(values)

# Handle release values

values = handle_release_values(values)

# Handle OS values

values = handle_os_values(values)

# Handle memory values

values = handle_memory_values(values)

# Get/set publisher port (Used for configuring AI server)

values = handle_publisher_values(values)

# If service is set, but method and os is not specified, try to set method from service name

if values['service'] != values['empty'] && values['method'] == values['empty'] && values['os-type'] == values['empty']
  values['method'] = get_install_method_from_service(values)
elsif values['method'] == values['empty'] && values['os-type'] == values['empty']
  values['method'] = get_install_method_from_service(values)
end

# Handle VM switch

values = handle_vm_values(values)

# Check OS switch

values = handle_os_values(values)

# Handle install method

values = handle_install_method(values)

# Do a check to see if we are running Packer and trying to install Windows with network in non NAT mode

if values['type'].to_s.match(/packer/) && values['os-type'].to_s.match(/win/)
  unless values['vmnetwork'].to_s.match(/nat/)
    warning_message(values, 'Packer only supports installing Windows with a NAT network')
    information_message(values, 'Setting network to NAT mode')
    values['vmnetwork'] = 'nat'
  end
  values['shell'] = 'winrm'
end

# Handle VM named none

if values['action'].to_s.match(/create/) && values['name'] == 'none' && values['mode'] != 'server' && (values['type'] != 'service')
  warning_message(values, 'Invalid client name')
  quit(values)
end

# Handle multiple configs in one line if separated by a comma, or handle a sinlge config

if values['name'].to_s.match(/,/)
  host_list = values['name'].to_s.split(',')
  ip_list   = []
  mac_list  = []
  vcpu_list = []
  mem_list  = []
  disk_list = []
  rel_list  = []
  ip_list = values['ip'].to_s.split(',') if values['ip'].to_s.match(/,/)
  mac_list = values['mac'].to_s.split(',') if values['mac'].to_s.match(/,/)
  mem_list = values['memory'].to_s.split(',') if values['memory'].to_s.match(/,/)
  vcpus_list = values['vcpus'].to_s.split(',') if values['vcpus'].to_s.match(/,/)
  disk_list = values['disk'].to_s.split(',') if values['disk'].to_s.match(/,/)
  rel_list = values['release'].to_s.split(',') if values['release'].to_s.match(/,/)
  host_list.each_with_index do |host_name, counter|
    values['name'] = host_name
    values['ip'] = ip_list[counter] if ip_list[counter]
    values['mac'] = (mac_list[counter] || generate_mac_address(values))
    values['memory'] = mem_list[counter] if mem_list[counter]
    values['vcpus'] = vcpus_list[counter] if vcpu_list[counter]
    values['release'] = rel_list[counter] if rel_list[counter]
    values['disk'] = (disk_list[counter] || values['empty'])
    handle_action(values)
  end
else
  values = handle_action(values)
end

quit(values)
