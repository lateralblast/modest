# Changelog

All notable changes to this project are documented in this file, generated from the original
`modest.changelog` and `webserver.changelog` files. Entries are grouped by component and listed
newest first.

## modest.rb

### [8.2.2] - 2026-09-28
- Fixed operator-precedence bugs (`!x == values['empty']` always evaluating false) that silently disabled --dir, --outputfile, --size, --publisher, --file, --mac, and hostonly network default handling
- Fixed per-host --vcpus assignment when creating multiple hosts in one command (--name a,b), which previously never applied due to a variable name mismatch

### [8.2.1] - 2026-09-28
- Converted modest.changelog/webserver.changelog to a standard CHANGELOG.md and wired up --changelog to print it

### [8.2.0] - 2025-06-07
- Initial code cleanup based on rubocop recommendations

### [8.1.9] - 2024-10-01
- Improved dryrun mode

### [8.1.8] - 2024-10-01
- Documentation update

### [8.1.7] - 2024-10-01
- Bug fixes and documentation updates

### [8.1.6] - 2024-10-01
- Added additional checking for IP and MAC addresses

### [8.1.5] - 2024-09-30
- Bug fixes and code cleanup

### [8.1.4] - 2024-09-27
- Improved values processing

### [8.1.3] - 2024-09-27
- Improved defaults handling

### [8.1.2] - 2024-09-27
- Improved options handing

### [8.1.1] - 2024-09-26
- Bug fixes

### [8.1.0] - 2024-09-26
- Bug fixes

### [8.0.9] - 2024-09-26
- Some code cleanup

### [8.0.8] - 2024-09-25
- Command execution improvements

### [8.0.7] - 2024-09-24
- Updates for KVM

### [8.0.6] - 2024-09-24
- Added dryrun handling to file creation

### [8.0.5] - 2024-09-24
- Added some dryrun handling

### [8.0.4] - 2024-09-24
- Code cleanup

### [8.0.3] - 2024-09-23
- Options processing cleanup

### [8.0.2] - 2024-09-22
- Added more KVM cloud-init support

### [8.0.1] - 2024-09-21
- Added code to hadndle options

### [8.0.0] - 2024-09-19
- ISO version determination fixes

### [7.9.9] - 2024-09-19
- Bug fixes

### [7.9.8] - 2024-09-14
- Cleaned up values code more

### [7.9.7] - 2024-09-14
- Cloud-init improvements and code cleanup

### [7.9.6] - 2024-09-12
- Output tweaks

### [7.9.5] - 2024-09-12
- Improvements for MacOS

### [7.9.4] - 2024-09-11
- Added options switch and updated dryrun switch

### [7.9.3] - 2024-09-10
- Updated methods

### [7.9.2] - 2024-09-10
- Added code to enable verbose mode early if given verbose switcho

### [7.9.1] - 2024-09-08
- Inital KVM on MacOS support

### [7.9.0] - 2023-12-02
- Some code cleanup

### [7.8.9] - 2023-12-01
- Default environment clean up and additional Arch Linux support

### [7.8.8] - 2023-12-01
- Cleaned up uname and lsb information

### [7.8.7] - 2023-11-30
- Added initial support to import external preseed, kickstart, cloudinit, and unattended files

### [7.8.6] - 2023-11-30
- Added support for building ESXi 7 and 8 inside KVM with Packer

### [7.8.5] - 2023-11-28
- Added initial Rocky and Alma Linux support

### [7.8.4] - 2023-11-28
- Fixed shutdown command for Packer RHEL builds

### [7.8.3] - 2023-11-28
- Added support for RHEL 9.3

### [7.8.2] - 2023-11-27
- Added more support for Arch Linux

### [7.8.1] - 2023-11-27
- Added initial Arch Linux support for KVM

### [7.8.0] - 2023-11-24
- Fixed Packer Windows on KVM with NAT network

### [7.7.9] - 2023-11-24
- Added check to make sure bridge is active

### [7.7.8] - 2023-11-24
- Fixes for Windows on KVM and Packer

### [7.7.7] - 2023-11-24
- Fixes for Linux on KVM and Packer

### [7.7.6] - 2023-11-24
- Bug fixes

### [7.7.5] - 2023-11-23
- Added code to check KVM network/bridge is created and online

### [7.7.4] - 2023-11-15
- Some cleanup of file/directory permissions check (more needed)

### [7.7.3] - 2023-11-15
- Added check for KVM permissions

### [7.7.2] - 2023-11-14
- Various KVM improvements

### [7.7.1] - 2023-11-13
- Bug fixes

### [7.7.0] - 2023-11-13
- Updated version of Packer

### [7.6.9] - 2023-11-11
- Added VMware Fusion network check to boot option

### [7.6.8] - 2023-11-11
- Added Packer SSH Port switch

### [7.6.7] - 2023-11-11
- Simplified Packer storage config for Ubuntu installation

### [7.6.6] - 2023-11-11
- Improved disk device detection for Packer and VMware Fusion

### [7.6.5] - 2023-11-11
- Fixed IP forwarding for hostonly networks on VMware Fusion

### [7.6.4] - 2023-11-10
- Improvements and fixes for VMware Fusion on MacOS

### [7.6.3] - 2023-11-10
- Code cleanup and more fixes for VMware Fusion on Apple Silicon

### [7.6.2] - 2023-11-08
- Added fix for keyboard not working on Packer and VMware Fusion on Apple Silicon

### [7.6.1] - 2023-11-07
- Fixed guest OS name detection for VMware Fusion on ARM

### [7.6.0] - 2023-11-07
- Updated VMware HW version for VMware Fusion 13.5

### [7.5.9] - 2022-12-04
- More fixes for ARM

### [7.5.8] - 2022-12-04
- Fixes for determining service name for Ubuntu ARM

### [7.5.7] - 2022-12-03
- Updated Ubuntu version checking code

### [7.5.6] - 2022-12-02
- Added initial support for VMware Fusion 13

### [7.5.5] - 2022-10-05
- Added support for calculating VMware HW version for tech preview versions

### [7.5.4] - 2022-06-03
- Multipass post install fixes

### [7.5.3] - 2022-06-02
- More multipass cloudinit tweaks

### [7.5.2] - 2022-05-28
- Added some addition multipass cloudinit support

### [7.5.1] - 2022-05-26
- Added additional dnsmasq functionality

### [7.5.0] - 2022-05-25
- Added additional dnsmasq functionality

### [7.4.9] - 2022-05-25
- Added additional multi config support in one command

### [7.4.8] - 2022-05-22
- KVM and dnsmasq fixes

### [7.4.7] - 2022-05-21
- More multi config fixes

### [7.4.6] - 2022-05-21
- Improved code to do multiple configs in one command

### [7.4.5] - 2022-05-21
- Started adding code to do multiple configs in one command

### [7.4.4] - 2022-05-20
- DNSmasq improvements

### [7.4.3] - 2022-05-20
- KVM network option determination fixes

### [7.4.2] - 2022-05-20
- Improved DNSmasq support

### [7.4.1] - 2022-04-17
- Improved KVM bridge support

### [7.4.0] - 2022-04-17
- Improved iptables and ufw support for KVM

### [7.3.9] - 2022-04-17
- Improved gateway handling/determination

### [7.3.8] - 2022-04-16
- Added code to check KVM bridge config

### [7.3.7] - 2022-04-16
- Added check for KVM network bridge

### [7.3.6] - 2022-04-16
- Added check for network/bridge devices

### [7.3.5] - 2022-04-16
- Added code to connect to KVM VM

### [7.3.4] - 2022-04-16
- Added handling for orphaned VM disks files

### [7.3.3] - 2022-04-15
- Fixes for iptables check

### [7.3.2] - 2022-04-15
- More fixes for KVM

### [7.3.1] - 2022-04-11
- More code cleanup of KVM VM handling

### [7.3.0] - 2022-04-08
- Added some improved handing for KVM VM creation

### [7.2.9] - 2022-04-07
- Updated packer version to 1.8.0

### [7.2.8] - 2022-04-07
- Fixed bug with installing package

### [7.2.7] - 2021-12-03
- Some more code cleanup

### [7.2.6] - 2021-12-02
- Added multipass connect and cleaned up code

### [7.2.5] - 2021-11-17
- Bug fixes

### [7.2.4] - 2021-11-16
- Fixed multipass stop VM

### [7.2.3] - 2021-11-16
- Cleaned up output messages

### [7.2.2] - 2021-11-15
- Cleaned up RPM check

### [7.2.1] - 2021-10-30
- Further cleanup of packer support

### [7.2.0] - 2021-10-30
- Further clean up of Packer support for KVM

### [7.1.9] - 2021-10-30
- Started cleanup of Packer support for KVM

### [7.1.8] - 2021-10-29
- Improved wimlib/wimtools package check

### [7.1.7] - 2021-10-29
- Fixed Packer Windows builds and bridged networking for VMware Fusion

### [7.1.6] - 2021-10-27
- Fixed listing Fusion VMs

### [7.1.5] - 2021-10-23
- Bug fixes for cloud-init

### [7.1.4] - 2021-10-22
- Fixed service list function

### [7.1.3] - 2021-10-22
- Added code to enable console on KVM

### [7.1.2] - 2021-10-20
- Initial cleanup of questions code

### [7.1.1] - 2021-10-18
- Bug fix for default network interface on Multipass

### [7.1.0] - 2021-10-18
- Fixed Multipass cloud init

### [7.0.9] - 2021-10-18
- Added reboot to Multipass cloud init

### [7.0.8] - 2021-10-17
- Fixes for Multipass on Linux

### [7.0.7] - 2021-10-17
- Initial support for Multipass on Linux

### [7.0.6] - 2021-10-17
- Fix for network determination when Multipass and VMware Fusion both installed on MacOS

### [7.0.5] - 2021-10-16
- Added code to check multipass NAT/firewall port redirection

### [7.0.4] - 2021-10-16
- Bugfixes and general cleanup

### [7.0.3] - 2021-10-14
- Added exec support to Multipass

### [7.0.2] - 2021-10-14
- Fixed cloud-init code for Multipass

### [7.0.1] - 2021-10-14
- Bugfixes for default Multipass instance creation

### [7.0.0] - 2021-10-14
- Added function to get Mutipass instance information

### [6.9.9] - 2021-10-14
- Added initial Multipass cloud init support

### [6.9.8] - 2021-10-13
- Added Multipass list routines

### [6.9.7] - 2021-10-13
- Initial Multipass support

### [6.9.6] - 2021-10-06
- More improvements for KVM

### [6.9.5] - 2021-10-06
- Cleaned up KVM package check

### [6.9.4] - 2021-10-06
- Improved KVM defaults determination

### [6.9.3] - 2021-10-05
- Split out KVM client and common code

### [6.9.2] - 2021-10-05
- Improved image listing code

### [6.9.1] - 2021-10-05
- Added basic image listing code for cloud images etc

### [6.9.0] - 2021-10-05
- Added check for AWS credentials when creating credentials file

### [6.8.9] - 2021-10-05
- Fixed bug with KVM client listing

### [6.8.8] - 2021-10-05
- Fix for copying live/subiquity images

### [6.8.7] - 2021-10-05
- More improvements for ISO and service listings

### [6.8.6] - 2021-10-04
- Improvements for ISO and service listings

### [6.8.5] - 2021-10-04
- Fixed service listing for Subiquity

### [6.8.4] - 2021-10-04
- Cleaned up ISO list function

### [6.8.3] - 2021-10-02
- Fixed dhcpd range generation for dhcpd config

### [6.8.2] - 2021-10-01
- Added biosdevnames switch

### [6.8.1] - 2021-09-30
- Subiquity code clean up

### [6.8.0] - 2021-09-30
- More fixes for subiquity post install script

### [6.7.9] - 2021-09-30
- More fixes for subiquity post install script

### [6.7.8] - 2021-09-29
- Fixes for subiquity post install script

### [6.7.7] - 2021-09-29
- Updated subiquitiy post install script

### [6.7.6] - 2021-09-28
- Initial working support for subiquity PXE installs

### [6.7.5] - 2021-09-28
- Updates for post install commands for subiquity

### [6.7.4] - 2021-09-28
- Initial post install commands for subiquity

### [6.7.3] - 2021-09-27
- Fixes for live install PXE boot

### [6.7.2] - 2021-09-27
- Cleaned up NIC question/determination for Ubuntu

### [6.7.1] - 2021-09-27
- Initial support for Ubuntu Live Server automated install

### [6.7.0] - 2021-06-28
- Fixes for TFTP boot

### [6.6.9] - 2021-06-24
- Some code cleanup

### [6.6.8] - 2021-06-20
- Bug fixes

### [6.6.7] - 2021-06-20
- Code cleanup

### [6.6.6] - 2021-06-19
- Initial working UEFI PXE boot for ESX

### [6.6.5] - 2021-06-18
- ESXi UEFI PXE boot config improvements

### [6.6.4] - 2021-06-17
- Added more support for UEFI BIOS

### [6.6.3] - 2021-06-17
- More VMware Fusion improvements

### [6.6.2] - 2021-06-17
- Improved MVware Fusion support

### [6.6.1] - 2021-06-17
- Bug fix

### [6.6.0] - 2021-06-17
- Fixed bugs with listing services

### [6.5.9] - 2021-06-16
- Bug Fixes

### [6.5.8] - 2021-06-15
- KVM improvements

### [6.5.7] - 2021-06-11
- Bug fixes

### [6.5.6] - 2021-06-11
- Improved error checking for questions

### [6.5.5] - 2021-06-10
- Packer KVM improvements

### [6.5.4] - 2021-06-10
- Packer install fixes

### [6.5.3] - 2021-06-10
- Improved handling of some KVM defaults

### [6.5.2] - 2021-06-10
- More KVM improvements

### [6.5.1] - 2021-06-10
- KVM bug fixes

### [6.5.0] - 2021-06-09
- Bug fixes

### [6.4.9] - 2021-06-08
- Removed unused modules causing gem build errors

### [6.4.8] - 2021-05-30
- Some more support for Parallels for Packer

### [6.4.7] - 2021-05-29
- Bug fixes

### [6.4.6] - 2021-05-29
- Initial Parallels support for Packer

### [6.4.5] - 2021-05-29
- Bug fixes

### [6.4.4] - 2021-05-28
- Initial support for Ubuntu LiveCD installer

### [6.4.3] - 2021-05-19
- Initial AWS code cleanup

### [6.4.2] - 2021-05-19
- Bug fixes

### [6.4.1] - 2021-05-19
- Fixes for ESXi install under VMware Fusion

### [6.4.0] - 2021-05-18
- Fixed bug with Kikstart file creation

### [6.3.9] - 2021-05-18
- Updated Windows Eval keys

### [6.3.8] - 2021-05-18
- Fixed some bugs with Packer Windows support

### [6.3.7] - 2021-05-18
- Fixed default hostonly IP calculation for VMware Fusion 12 on MacOS BigSur

### [6.3.6] - 2021-05-17
- Initial packer NAT cleanup (Ubuntu) for VirtualBox

### [6.3.5] - 2021-05-17
- Initial packer NAT cleanup (Ubuntu) for VMware Fusion

### [6.3.4] - 2021-05-06
- Added command line check for incorrect values

### [6.3.3] - 2021-05-05
- Fixes to deal with boot command length

### [6.3.2] - 2021-05-05
- Bug fixes

### [6.3.1] - 2021-05-05
- Bug fixes

### [6.3.0] - 2021-05-04
- Added a wait statement to packer boot command for Ubuntu

### [6.2.9] - 2021-04-21
- Fixed bug with virtualbox network check

### [6.2.8] - 2020-10-23
- Added package checks for apache2, shim, and grubnet packages

### [6.2.7] - 2020-09-29
- Added headless mode for KVM Packer JSON

### [6.2.6] - 2020-09-29
- Updated Packer Ubuntu Preseed post install script and other bug fixes

### [6.2.5] - 2020-09-28
- Fixed packer KVM bridge and disk values

### [6.2.4] - 2020-09-28
- Added bridge check to KVM installation check

### [6.2.3] - 2020-09-28
- Various bug fixes for packer and VMware Workstation on Linux

### [6.2.2] - 2020-09-24
- Various bug fixes for KVM client creation checks

### [6.2.1] - 2020-09-24
- Fixed issue with defaults for packer

### [6.2.0] - 2020-09-15
- Initial support for VMware Fusion 12 and fixes for Packer

### [6.1.9] - 2020-09-07
- Bug fixes

### [6.1.8] - 2020-09-07
- Fixes for create VMware Fusion promiscuous networking file

### [6.1.7] - 2020-09-07
- Fixes for Packer install test

### [6.1.6] - 2020-09-07
- Cleaned up gem module load testing

### [6.1.5] - 2020-08-10
- Improved UEFI grub PXE boot config file creation

### [6.1.4] - 2020-08-03
- Bug fixes

### [6.1.3] - 2020-07-29
- Improved KVM support and option checking

### [6.1.2] - 2020-07-28
- Bug fixes

### [6.1.1] - 2020-07-28
- Bug fixes and more KVM support

### [6.1.0] - 2020-07-15
- Added handling for preseed language setting in Ubuntu 20

### [6.0.9] - 2020-07-11
- Added initial UEFI PXE boot support

### [6.0.8] - 2020-07-08
- Bug fixes

### [6.0.7] - 2020-07-08
- Bug fixes

### [6.0.6] - 2020-06-16
- Fixes for calculation mirror disk id

### [6.0.5] - 2020-06-15
- Fixed rules.ok and machine file generation for Solaris 10

### [6.0.4] - 2020-06-12
- Improved tftp and bootparams processing on Solaris

### [6.0.3] - 2020-06-11
- Improved rootdisk and mirrordisk option handling

### [6.0.2] - 2020-06-10
- Bug fixes

### [6.0.1] - 2020-06-10
- Added gateway switch

### [6.0.0] - 2020-06-10
- Bug fixes

### [5.9.9] - 2020-06-10
- Bug fixes

### [5.9.8] - 2020-06-09
- Fixed bug with Solaris 11 installation manifest

### [5.9.7] - 2020-06-05
- Bug fixes

### [5.9.6] - 2020-04-30
- More tweaks for splitvols switch for LVM layout

### [5.9.5] - 2020-04-30
- More updates for grub config

### [5.9.4] - 2020-04-29
- Fixes for preseed grub config creation

### [5.9.3] - 2020-04-27
- Added linux-generic-hwe-18.04 to Ubuntu 18.04 package list

### [5.9.2] - 2020-04-27
- Bug fixes for preseed PXE post install script execution

### [5.9.1] - 2020-04-26
- Improved gateway determination for preseed PXE

### [5.9.0] - 2020-04-26
- Fixed bugs in preseed PXE boot client configuration

### [5.8.9] - 2020-04-26
- Bug fixes for listing ISO information

### [5.8.8] - 2020-04-25
- Set partition format to GPT for Ubuntu

### [5.8.7] - 2020-04-25
- Added code to split out LVM volumes for Ubuntu

### [5.8.6] - 2020-04-23
- Added support for Ubuntu 20.04 beta

### [5.8.5] - 2020-04-20
- Bug fixes

### [5.8.4] - 2020-04-18
- Fixes for Jumpstart client setup

### [5.8.3] - 2020-04-18
- Fixes for Jumpstart server setup

### [5.8.2] - 2020-04-17
- More fixes for Solaris 11

### [5.8.1] - 2020-04-16
- More fixes for Solaris 11

### [5.8.0] - 2020-04-16
- Added check to make sure DHCP server is not in maintenance mode before running installadm

### [5.7.9] - 2020-04-15
- More Solaris 11 AI install server fixes

### [5.7.8] - 2020-04-15
- Added package list array for MacOS to reduce package checks

### [5.7.7] - 2020-04-14
- Several fixes for Solaris 11 AI install server config

### [5.7.6] - 2020-04-13
- Fixed host IP determination on Solaris

### [5.7.5] - 2020-04-06
- Updates for Solaris 11 Update 4 and Packer

### [5.7.4] - 2020-04-05
- More bug fixes for Solaris 11 Packer builds

### [5.7.3] - 2020-04-05
- Bug fixes for Solaris 11 and Packer

### [5.7.2] - 2020-04-03
- Added check to ensure service name is set

### [5.7.1] - 2020-03-31
- More code cleanup

### [5.7.0] - 2020-03-28
- Fixed AutoYast PXE boot for SLES 12 SP3

### [5.6.9] - 2020-03-28
- Fixed cdrom copy command to deal with dotfiles not being copied

### [5.6.8] - 2020-03-28
- Increased default memory of VM to deal with issues PXE booting

### [5.6.7] - 2020-03-28
- More bug fixes

### [5.6.6] - 2020-03-28
- Fixed SSH copy keys

### [5.6.5] - 2020-03-28
- Started migrating global question struct to values

### [5.6.4] - 2020-03-27
- More bug fixes

### [5.6.3] - 2020-03-27
- Moved to tftpd-hpa due to issues with default tftpd under Linux

### [5.6.2] - 2020-03-27
- More bug fixes

### [5.6.1] - 2020-03-26
- More TFTP fixes

### [5.6.0] - 2020-03-26
- Fixed DHCP config creations

### [5.5.9] - 2020-03-25
- Fixed Fusion VM creation

### [5.5.8] - 2020-03-25
- More bug fixes

### [5.5.7] - 2020-03-24
- More bug fixes

### [5.5.6] - 2020-03-23
- More bug fixes

### [5.5.5] - 2020-03-21
- Bug fixes

### [5.5.4] - 2020-03-21
- Fixed VMware Fusion VM directory determination

### [5.5.3] - 2020-03-21
- Numerous bug fixes

### [5.5.2] - 2020-02-22
- Fixed Packer SLES 12 builds

### [5.5.1] - 2020-02-21
- More fixes for Packer ESXi builds

### [5.5.0] - 2020-02-21
- Fixed ESXi Packer builds

### [5.4.9] - 2020-02-20
- Fixed Packer Ubuntu builds

### [5.4.8] - 2020-02-20
- Start of major rewrite (packer working for RHEL/CentOS Linux and Windows)

### [5.4.7] - 2020-01-31
- Initial support for SLES 15.x

### [5.4.6] - 2020-01-31
- Fixes for SLES 12.x

### [5.4.5] - 2020-01-31
- Added support for CentOS 8.x

### [5.4.4] - 2020-01-30
- Add support for Windows 2019 and other fixes

### [5.4.3] - 2020-01-30
- Fixes for Windows 2016

### [5.4.2] - 2020-01-29
- Improved multiple ethernet interface support

### [5.4.1] - 2020-01-29
- Bug fixes

### [5.4.0] - 2020-01-29
- Added initial capability to input multiple IPs to configure additional interfaces

### [5.3.9] - 2020-01-28
- Improved support for VMware Workstation for Linux

### [5.3.8] - 2020-01-27
- Bug fixes

### [5.3.7] - 2020-01-27
- Added support for Oracle Linux 8.x

### [5.3.6] - 2020-01-27
- Bug fixes

### [5.3.5] - 2020-01-26
- Bug fixes

### [5.3.4] - 2020-01-26
- Fix for RHEL 8.x

### [5.3.3] - 2020-01-17
- Bug fixes

### [5.3.2] - 2020-01-01
- Fixes for KVM packer builds

### [5.3.1] - 2020-01-01
- Added check for uifw allow rule for packer based installs on Ubuntu Linux and other fixes

### [5.3.0] - 2019-12-21
- Added code to add/delete VMware Fusion network interfaces

### [5.2.9] - 2019-12-18
- Various fixes

### [5.2.8] - 2019-12-16
- Added KVM import support for OVAs

### [5.2.7] - 2019-12-11
- Some fixes for headless mode

### [5.2.6] - 2019-12-09
- Added handing for host and hostonly subnet being the same

### [5.2.5] - 2019-11-29
- Bug fixes

### [5.2.4] - 2019-11-28
- Added code to check for orphaned packer VirtualBox VDIs

### [5.2.3] - 2019-11-28
- Fixes for MacOS Catalina support

### [5.2.2] - 2019-11-21
- Fixed bug with Ubuntu sources.list creation

### [5.2.1] - 2019-11-19
- Improved preseed post install

### [5.2.0] - 2019-11-19
- Added root device switch

### [5.1.9] - 2019-11-16
- More Packer JSON fixes

### [5.1.8] - 2019-11-15
- Packer JSON fixes

### [5.1.7] - 2019-11-15
- Updated VMware machine version determination

### [5.1.6] - 2019-11-15
- Bug fixes

### [5.1.5] - 2019-11-14
- Improved default value handing

### [5.1.4] - 2019-11-14
- Fixed listing of ISO files with + in file name

### [5.1.3] - 2019-11-13
- Code cleanup

### [5.1.2] - 2019-11-11
- Additional fixes for Packer and Windows

### [5.1.1] - 2019-11-10
- Bug fixes and improved handling for VirtualBox, Packer and Windows configuration

### [5.1.0] - 2019-11-09
- Bug fixes and improved LVM support in preseed config

### [5.0.9] - 2019-11-07
- Added check for apache2 2.4 config file differences

### [5.0.8] - 2019-11-06
- Bug fixes

### [5.0.7] - 2019-11-06
- Improved ufw and iptables check

### [5.0.6] - 2019-11-06
- Bug fixes

### [5.0.5] - 2019-11-04
- Improved KVM support

### [5.0.4] - 2019-11-03
- Improvements for KVM including import

### [5.0.3] - 2019-11-03
- Fixes for KVM

### [5.0.2] - 2019-11-03
- Added install check for KVM

### [5.0.1] - 2019-11-03
- Added Linux firewall check

### [5.0.0] - 2019-11-02
- Updated hostonly network to VirtualBox/Fusion defaults

### [4.9.9] - 2019-11-02
- Fixes for VirtualBox and Packer

### [4.9.8] - 2019-06-23
- Updated VCSA deployment support for vSphere 6.7

### [4.9.7] - 2019-06-23
- Bug fixes for ESXi TFTP boot config

### [4.9.6] - 2019-06-22
- Added packer support for RHEL 8 release

### [4.9.5] - 2019-06-03
- Minor update to stop exit after checking for VirtualBox

### [4.9.4] - 2019-04-23
- Added support for Ubuntu 19.04

### [4.9.3] - 2019-04-22
- Added support for Red Hat 8.0 beta to Packer

### [4.9.2] - 2019-04-21
- Added VM type detection for import

### [4.9.1] - 2019-04-21
- Fixed Kickstart creation for Packer

### [4.9.0] - 2019-02-09
- Various fixes for CentOS and packer

### [4.8.9] - 2019-02-06
- Improved CentOS 7.x ISO name determination

### [4.8.8] - 2019-01-29
- Initial Windows VMware Workstation support

### [4.8.7] - 2019-01-21
- Initial Windows host support

### [4.8.6] - 2019-01-16
- Updated gem auto installation to only install aws-sdk gem if needed

### [4.8.5] - 2019-01-11
- Improved packet forwarding check for OS X for hostonly networking

### [4.8.4] - 2019-01-11
- Fixed VirtualBox image import for packer VMs

### [4.8.3] - 2019-01-10
- Bug fixes to get Packer working with VirtualBox in hostonly mode

### [4.8.2] - 2019-01-08
- Code cleanup

### [4.8.1] - 2019-01-07
- More bug fixes

### [4.8.1] - 2019-01-05
- More bug fixes

### [4.8.0] - 2019-01-04
- Various bug fixes

### [4.7.9] - 2019-01-04
- Some code cleanup and improved VM gateway determination

### [4.7.8] - 2019-01-03
- Several fixes for VirtualBox on Linux

### [4.7.7] - 2019-01-03
- More initial support for QEMU and KVM and bug fixes

### [4.7.6] - 2018-12-31
- More initial support for QEMU and KVM

### [4.7.5] - 2018-12-31
- Added initial support for QEMU via packer and improved install method detection

### [4.7.4] - 2018-12-31
- Various packer config file creation updates

### [4.7.3] - 2018-12-15
- Fixed bug with domainname in preseed creation

### [4.7.2] - 2018-12-15
- Fixed netmask calculation

### [4.7.1] - 2018-07-08
- Added filedir switch and fixed rpm2cpio and syslinux URLs

### [4.7.0] - 2018-05-20
- Added some Packer support for Solaris 11.4

### [4.6.9] - 2018-05-19
- Added Packer support for Ubuntu 18.04

### [4.6.8] - 2018-01-10
- Added Packer support for Ubuntu 17.10

### [4.6.7] - 2018-01-09
- More fixes for Packer support for SLES

### [4.6.6] - 2018-01-08
- More fixes for Packer support for SLES 12

### [4.6.5] - 2018-01-08
- Fixed Packer support for SLES 12

### [4.6.4] - 2018-01-07
- Improved service name detection for SLES 12

### [4.6.3] - 2018-01-07
- Fixed Packer Fedora support

### [4.6.2] - 2018-01-07
- Improved Packer Fedora support

### [4.6.1] - 2017-06-30
- Various VMware Fusion fixes

### [4.6.0] - 2017-02-07
- Minor AWS fixes

### [4.5.9] - 2017-01-14
- Minor AWS fixes

### [4.5.8] - 2017-01-04
- Fixes and improvements for Solaris 11 Packer Builds

### [4.5.7] - 2017-01-02
- Disabled VMware Tools install on Windows as part of Packer due to failed installation (looks like Packer issue)

### [4.5.6] - 2017-01-01
- Fixes for Packer ESXi builds

### [4.5.5] - 2017-01-01
- Added code to mask secret and access keys in verbose output for AWS

### [4.5.4] - 2016-12-31
- Added code to create simple Ansible based AWS instances

### [4.5.3] - 2016-12-29
- Added headless mode for Packer config and fixed bugs

### [4.5.2] - 2016-12-29
- Minor improvements to docker support

### [4.5.1] - 2016-12-28
- Fixed network determination for Packer and Ubuntu

### [4.5.0] - 2016-12-27
- Fixed code to determine VM type for client if not given

### [4.4.9] - 2016-12-27
- Fixed bug with packer import

### [4.4.8] - 2016-12-27
- More AWS IP rule handling improvements

### [4.4.7] - 2016-12-27
- AWS IP rule handling improvement

### [4.4.6] - 2016-12-27
- Improved AWS instance SSH connection code

### [4.4.5] - 2016-12-27
- Various bug fixes and improvements for AWS instance creation

### [4.4.4] - 2016-12-26
- Bug fixes

### [4.4.3] - 2016-12-26
- Fixed and improved AWS Packer client creation

### [4.4.2] - 2016-12-26
- Fixed AWS listing routines

### [4.4.1] - 2016-12-26
- Bug fixes

### [4.4.0] - 2016-12-26
- Updated Packer version and minor fixes

### [4.3.9] - 2016-12-26
- Minor bug fixes

### [4.3.8] - 2016-12-26
- Further cleanup of command line argument handling

### [4.3.7] - 2016-12-25
- Initial rewrite of command line argument handling

### [4.3.6] - 2016-12-23
- Added code to add and delete EC2 security group rules

### [4.3.5] - 2016-12-23
- Added code to create and delete EC2 security groups

### [4.3.4] - 2016-12-23
- Added code to list EC2 security groups

### [4.3.3] - 2016-12-22
- Fixed handling of types and objects for AWS

### [4.3.2] - 2016-12-22
- Improved command line processing for AWS functions

### [4.3.1] - 2016-12-22
- Added code to generate private and public URLs for AWS S3 bucket objects

### [4.3.0] - 2016-12-21
- Added Stack Status to AWS CF list output

### [4.2.9] - 2016-12-21
- Fixed AWS EC2 SSH connection code

### [4.2.8] - 2016-12-21
- Added initial code to create and delete AWS CF stacks

### [4.2.7] - 2016-12-21
- Added code to list AWS S3 bucket objects and upload contents of a URL to a bucket

### [4.2.6] - 2016-12-20
- Added code to list AWS CF stacks

### [4.2.5] - 2016-12-20
- Added code to download from S3 bucket

### [4.2.4] - 2016-12-20
- Added code to upload file to S3 bucket

### [4.2.3] - 2016-12-19
- Fixed bugs with AWS instance creation

### [4.2.2] - 2016-12-19
- Fixed bug with listing terminated instances

### [4.2.1] - 2016-12-19
- Added code to create ssh config aliases/entries

### [4.2.0] - 2016-12-17
- Added stop/start all AWS instance capability

### [4.1.9] - 2016-12-16
- Added code to create and delete AWS key pairs

### [4.1.8] - 2016-12-16
- Added code to list key pairs

### [4.1.7] - 2016-12-15
- Improved AWS Instance creation code and add AWS connect code

### [4.1.6] - 2016-12-15
- Fixed Packer AWS code and general code cleanup

### [4.1.5] - 2016-12-14
- Added code to list and delete AWS snapshots

### [4.1.4] - 2016-12-12
- Added code to get ACLs on AWS bucket

### [4.1.3] - 2016-12-12
- Added code to list AWS buckets

### [4.1.2] - 2016-12-12
- Added code to create an AMI from an Instance

### [4.1.1] - 2016-12-11
- Added code to create and terminate AWS instances

### [4.0.9] - 2016-12-09
- Added code to restart AWS instances

### [4.0.8] - 2016-12-09
- Added code to delete AWS instances

### [4.0.7] - 2016-12-09
- Added code to list, stop and starto AWS instances

### [4.0.6] - 2016-12-08
- Added code to list Packer AWS cliGents

### [4.0.5] - 2016-12-08
- Added code to list and delete AMIs

### [4.0.4] - 2016-12-08
- Updated AWS credential code

### [4.0.3] - 2016-12-07
- Initial Packer AWS support

### [4.0.2] - 2016-12-06
- Added vSphere and VCSA 6.5 support

### [4.0.1] - 2016-12-05
- Added check for Packer version 0.12.0 or above to deal with VMware Fusion stalling

### [4.0.0] - 2016-11-07
- Improved automatic gem installation and added support for Ubuntu 16.10

### [3.9.9] - 2016-10-08
- Added support of Windows 2016 PR5

### [3.9.8] - 2016-10-07
- Fixed bugs with Autounattend.xml creation

### [3.9.7] - 2016-09-25
- Added code to execute docker command on host

### [3.9.6] - 2016-09-25
- Added initial docker support

### [3.9.5] - 2016-09-24
- Fixed some command line handling bugs

### [3.9.4] - 2016-09-24
- Fixed bugs with determining windows service name from ISO

### [3.9.3] - 2016-09-24
- Initial cleanup of command line option handling

### [3.9.2] - 2016-08-22
- More fixes and webserver plumbing

### [3.9.1] - 2016-08-19
- Added initial VNC code

### [3.9.0] - 2016-08-19
- More HTML output fixes

### [3.8.9] - 2016-08-18
- Fixed OS check for VMware Fusion VMs

### [3.8.8] - 2016-08-18
- Code cleanup for listing VMs

### [3.8.7] - 2016-08-18
- More code cleanup for listing ISOs

### [3.8.6] - 2016-08-18
- Code cleanup for listing ISOs

### [3.8.5] - 2016-08-18
- Added some initial plumbing for webserver

### [3.8.4] - 2016-08-17
- Added HTML output capability to AI list commands

### [3.8.3] - 2016-08-17
- Output code migrated to new method

### [3.8.2] - 2016-08-17
- Added initial webserver functionality

### [3.8.1] - 2016-08-16
- Migrated common code in modest.rb into common.rb

### [3.8.0] - 2016-08-16
- Added check for platform when listing LDom services

### [3.7.9] - 2016-08-16
- Minor bug fixes

### [3.7.8] - 2016-08-15
- Fixed issues with Ubuntu 16.04 and Packer

### [3.7.7] - 2016-08-12
- Added code to show VM configuration and get parameters

### [3.7.6] - 2016-08-12
- Added initial code to set values of parameters

### [3.7.5] - 2016-08-12
- Fixed code to stop/start Guest Domains

### [3.7.4] - 2016-08-12
- Guest LDom code fixes

### [3.7.3] - 2016-08-12
- More Control Domain code fixes

### [3.7.2] - 2016-08-12
- Fixed bugs with Control Domain creation and Solaris 11 package/gem install scripts

### [3.7.1] - 2016-08-11
- Fixed bugs with Solaris 11 AI Server code

### [3.7.0] - 2016-07-25
- Packer VirtualBox improvements

### [3.6.9] - 2016-07-25
- VirtualBox bug fixes

### [3.6.8] - 2016-07-24
- Initial support for building ESXi under Packer

### [3.6.7] - 2016-07-24
- Fixed a bug with multiple vcpu entries being put in vmx file

### [3.6.6] - 2016-07-24
- More bug fixes

### [3.6.5] - 2016-07-22
- Bug fixes

### [3.6.4] - 2016-07-21
- Fixed bugs with ESXi support

### [3.6.3] - 2016-07-18
- Various Packer tweaks

### [3.6.2] - 2016-07-18
- Added code to attempt install gems if they are not installed

### [3.6.1] - 2016-07-18
- Added sudo configuration to Packer Solaris 11 post install

### [3.6.0] - 2016-07-17
- Working Packer Solaris 10 builds for VMware Fusion

### [3.5.9] - 2016-07-16
- Added initial support for Packer Solaris 10 builds

### [3.5.8] - 2016-07-15
- Added support for Packer Solaris 11.0 builds

### [3.5.7] - 2016-07-15
- Added support for Packer Solaris 11.1, 11.2, and 11.3 builds

### [3.5.6] - 2016-07-15
- Added code to determine VM type for Packer builds if not specified

### [3.5.5] - 2016-07-15
- Added initial support for Packer Solaris 11 x86 builds

### [3.5.4] - 2016-07-10
- Added support for OEL 6.8

### [3.5.3] - 2016-07-10
- Added initial support for Fedora 24

### [3.5.2] - 2016-05-12
- Various bug fixes for Ubuntu

### [3.5.1] - 2016-05-11
- Various bug fixed for Packer and Ubuntu

### [3.5.0] - 2016-05-05
- Added support for Ubuntu 16.04 and fixed a number of bugs

### [3.4.9] - 2016-05-01
- Added initial support for Windows 2016 and fixed packer image import

### [3.4.8] - 2016-04-12
- Added Packer check for Linux with VirtualBox in NAT mode (hostonly or bridged does not appear to work currently with ssh)

### [3.4.7] - 2016-04-12
- Fixed Packer support for Linux with VMware Fusion in NAT mode

### [3.4.6] - 2016-04-12
- Fixed Packer support for Windows with VMware Fusion in NAT mode

### [3.4.5] - 2016-04-12
- Added Packer support for Windows with VirtualBox in NAT mode (hostonly or bridged does not appear to work currently with winrm)

### [3.4.4] - 2016-04-11
- Initial Packer support for Windows with VirtualBox

### [3.4.3] - 2016-04-10
- Working support for Windows 2012 R2 with Packer

### [3.4.2] - 2016-04-06
- Working support for Windows 2008 R2 with Packer

### [3.4.1] - 2016-04-03
- Initial support for Packer Windows VMs - Unattend.xml needs fixing

### [3.4.0] - 2016-04-02
- Added code to determine Windows version from ISO

### [3.3.9] - 2016-04-02
- Fixed packer installation

### [3.3.8] - 2016-04-02
- Added code to start VMware Fusion if not started so network can be plumbed

### [3.3.7] - 2016-04-01
- Fixed several Packer bugs

### [3.3.6] - 2016-03-14
- Several bug fixes

### [3.3.5] - 2016-03-14
- Added initial Solaris 9 ISO UFS copy code

### [3.3.4] - 2016-03-13
- Solaris client disksuite config fixes

### [3.3.3] - 2016-03-13
- Initial support for Solaris 9 Jumpstart Server

### [3.3.2] - 2016-03-13
- Fixed deletion of ZFS filesystems

### [3.3.1] - 2016-03-13
- Fixed bugs with AutoYast

### [3.3.0] - 2016-03-13
- Added support for SLES 12 SP 1

### [3.2.9] - 2016-03-12
- Fixed Solaris 10 Jumpstart on x86

### [3.2.8] - 2016-03-10
- Fixed bug with Preseed client creation

### [3.2.7] - 2016-03-10
- Updated unconfigure service routine to deal with filesystems rather than symlinks in tftpboot directory (e.g. /etc/netboot)

### [3.2.6] - 2016-03-10
- Fixed issue with installing SLES 12.0

### [3.2.5] - 2016-03-07
- More minor updates

### [3.2.4] - 2016-03-03
- Minor updates

### [3.2.3] - 2016-03-02
- Fixed default route configuration in RHEL 5 and 6 postinstall

### [3.2.2] - 2016-03-02
- Fixed bugs with RHEL 5.x kickstart config creation

### [3.2.1] - 2016-03-02
- Fixed reboot action for VMware Fusion VMs

### [3.2.0] - 2016-03-01
- Fixed ISO copy for RHEL 5.x repo creation

### [3.1.9] - 2016-03-01
- Fixed bug with ZFS fs creation for repo directories

### [3.1.8] - 2016-03-01
- Fixed bug with packer methods file and re-enabled it

### [3.1.7] - 2016-03-01
- Fixed bug with listing ISOs

### [3.1.6] - 2016-03-01
- Fixed default route configuration for RHEL 6.x

### [3.1.5] - 2016-02-29
- Fixed listing Fusion VMs

### [3.1.4] - 2016-02-29
- Improved listing of clients

### [3.1.3] - 2016-02-29
- Minor updates

### [3.1.2] - 2016-02-28
- Added VM type detection for delete action and fixed kickstart packages on RHEL 6.x

### [3.1.1] - 2016-02-28
- Fixed error with kickstart file creation and install server repo

### [3.1.0] - 2016-02-28
- Added VM type detection for boot/stop like commands

### [3.0.9] - 2016-02-28
- Improved client listing code to show IP and MAC Address

### [3.0.8] - 2016-02-28
- More listing bug fixes

### [3.0.7] - 2016-02-27
- Fixed bug with list all services

### [3.0.6] - 2016-02-27
- Moved Windows related development files from .rb to .xx so they are not imported until they are ready

### [3.0.5] - 2015-12-25
- Added initial SUSE support for Packer

### [3.0.4] - 2015-12-24
- Fixes for Ubuntu and OEL and initial OEL support for Packer

### [3.0.3] - 2015-12-23
- Fixes for Ubuntu including intial Ubuntu support for Packer

### [3.0.2] - 2015-12-21
- More fixes for ESXi support for Packer

### [3.0.1] - 2015-12-21
- Improved ESXi support for Packer

### [3.0.0] - 2015-12-21
- Added Fedora support for Packer

### [2.9.9] - 2015-12-18
- Multiple fixes to Packer support code

### [2.9.8] - 2015-12-16
- Fixed up Packer deletion code

### [2.9.7] - 2015-12-09
- Cleaned up verbose information output

### [2.9.6] - 2015-12-09
- Added code to import VirtualBox Packer VM image

### [2.9.5] - 2015-12-09
- Improved VirtualBox VM old config file cleanup

### [2.9.4] - 2015-12-09
- Added code to import VMware Fusion Packer VM image

### [2.9.3] - 2015-12-08
- Improved packer support

### [2.9.2] - 2015-12-08
- Added build capability to packer support

### [2.9.1] - 2015-11-26
- More VCSA deployment improvements

### [2.9.0] - 2015-11-26
- Improved VCSA deployment

### [2.8.9] - 2015-11-24
- Added support for VCSA deployment

### [2.8.8] - 2015-11-09
- Fixed MAC address check

### [2.8.7] - 2015-11-08
- Added support for RedHat 6.7 changes to apache and SELinux

### [2.8.6] - 2015-11-07
- Fixed support for Solaris 11.3 and RedHat 6.7

### [2.8.5] - 2015-11-06
- Added MAC address check for VMware Fusion

### [2.8.4] - 2015-11-06
- Updated support for VMware Fusion 8

### [2.8.3] - 2015-11-06
- Fixed typo

### [2.8.2] - 2015-10-17
- Minor bug fix

### [2.8.1] - 2015-10-16
- More fixes for Solaris

### [2.8.0] - 2015-10-16
- Fixed netboot directory determination on Solaris

### [2.7.9] - 2015-09-13
- Fixed vSphere support for Packer

### [2.7.8] - 2015-09-13
- Added support for vSphere for Packer

### [2.7.7] - 2015-09-13
- Added SSH timeout for Packer

### [2.7.6] - 2015-09-13
- Added Packer VMware Fusion support

### [2.7.5] - 2015-09-13
- Fixed issue with Packer JSON creation

### [2.7.4] - 2015-09-13
- Added inital support for AutoYast and Preseed and Packer

### [2.7.3] - 2015-09-13
- Added code to print changelog

### [2.7.2] - 2015-09-12
- Added code to delete Packer images

### [2.7.1] - 2015-09-12
- Added initial support for Packer and building Linux Kickstart VirtualBox VMs

### [2.7.0] - 2015-09-11
- Fixed error with listing VMware Fusion VMs

### [2.6.9] - 2015-07-28
- Bug fixes for Linux Deployment Server support

### [2.6.8] - 2015-07-28
- Improved host IP detection on Linux

### [2.6.7] - 2015-07-28
- Linux OS version detection improvements

### [2.6.6] - 2015-07-28
- Fixed issues with RHEL 7 as a distribution server

### [2.6.5] - 2015-07-28
- Added support for distribution server on RHEL 7

### [2.6.4] - 2015-07-27
- Documentation and code fixes

### [2.6.3] - 2015-07-27
- Added several packages to default kickstart package list

### [2.6.2] - 2015-07-27
- Removed need for fileutils gem

### [2.6.1] - 2015-07-26
- Added disk to boot method for VirtualBox

### [2.6.0] - 2015-07-26
- Fixed bug with turning off VirtualBox warning messages

### [2.5.9] - 2015-07-26
- Fixed bugs and improved install method detection

### [2.5.8] - 2015-07-25
- Fixed bug with puppet package directory creation

### [2.5.7] - 2015-07-25
- Fixed method determination for RHEL for install service creation from ISO

### [2.5.6] - 2015-07-25
- Fixed client list code

### [2.5.5] - 2015-07-25
- Fixed creation of ESX VirtualBox VMs

### [2.5.4] - 2015-07-25
- Fixed creation of non default VirtualBox VMs

### [2.5.3] - 2015-07-25
- Cleaned up services list output

### [2.5.2] - 2015-07-25
- Fixed creation of dhcpd config and various bugs

### [2.5.1] - 2015-07-24
- Added check for /etc/netboot and /tftpboot on Solaris

### [2.5.0] - 2015-07-24
- Cleaned up ISO list functions

### [2.4.9] - 2015-07-24
- Added initial support for remote command execution

### [2.4.8] - 2015-07-24
- Minor updates

### [2.4.7] - 2015-07-24
- Added code to dettach VirtualBox CDROM

### [2.4.6] - 2015-07-23
- Bug fixes and added option to set boot device when attaching CDROM

### [2.4.5] - 2015-05-14
- Fixed import of OVA files for VMware Fusion

### [2.4.4] - 2015-05-10
- Updates and bug fixes

### [2.4.3] - 2015-05-08
- Added code to display client config and mirror switch

### [2.4.2] - 2015-05-07
- Cleaned up preseed code

### [2.4.1] - 2015-05-05
- Added check to make sure syslinux/pxelinux files are copied to tftpboot directory if not present when creating client

### [2.4.1] - 2015-05-05
- Cleaned up client creation code

### [2.4.0] - 2015-05-05
- Added support for license key in post install for vSphere

### [2.3.9] - 2015-05-05
- Added support for vSphere 6 and cleaned up some of the client code

### [2.3.8] - 2015-05-04
- Added code to restart VM and code cleanups

### [2.3.7] - 2015-05-03
- Improved service deletion code

### [2.3.6] - 2015-05-03
- Improved service list code

### [2.3.5] - 2015-05-03
- Improved ISO list code

### [2.3.4] - 2015-05-03
- Updated puppet install for Solaris 11.2

### [2.3.3] - 2015-05-03
- Cleaned up ISO list code and commandline handling

### [2.3.2] - 2015-05-02
- Improved command line handling and added handling for unreadable VMware Fusion config file

### [2.3.1] - 2015-02-18
- Added snapshot creation and deletion code for VirtualBox

### [2.3.0] - 2015-02-18
- Cleaned up VirtualBox list code

### [2.2.9] - 2015-02-17
- Added code to delete Fusion VM snapshots

### [2.2.8] - 2015-02-17
- Cleaned up snapshot code for Fusion VMs

### [2.2.7] - 2015-02-17
- Cleaned up list code for VMs

### [2.2.6] - 2015-02-16
- Initial snapshot code

### [2.2.5] - 2015-02-15
- More improvements to VMware Fusion network test

### [2.2.4] - 2015-02-15
- Improved VMware Fusion network test

### [2.2.3] - 2015-02-15
- Fixed network NAT/pfctl configuration

### [2.2.2] - 2015-02-15
- Fixed UID check on directories

### [2.2.1] - 2015-02-15
- Added shared folder support for Fusion VMs

### [2.2.0] - 2015-02-15
- Fixed CDROM attach/detach for Fusion VMs

### [2.1.9] - 2015-02-14
- Numerous code cleanups, including NAT configuration

### [2.1.8] - 2015-02-11
- Added code to generate MAC address

### [2.1.7] - 2015-02-11
- Added initial code to attach and detach ISOs

### [2.1.6] - 2015-02-11
- Added initial memory and cpu handling for vm creation

### [2.1.5] - 2015-02-11
- Updated VM code to allow image file to be attached to VM as part of creation

### [2.1.4] - 2015-02-11
- Added code to stop/start Parallels VMs

### [2.1.3] - 2015-02-11
- Added initial support for parallels

### [2.1.2] - 2015-02-08
- Fixed adding hosts to host file

### [2.1.1] - 2015-02-08
- Migrate list services code to new method

### [2.1.0] - 2015-02-08
- Added code to list all VirtualBox VMs

### [2.0.9] - 2015-02-08
- Improved info action and examples

### [2.0.8] - 2015-02-07
- Migrated LDom calls to new format

### [2.0.7] - 2015-02-06
- Cleaned up and migrated more code to new format

### [2.0.6] - 2015-02-06
- Migrated create and delete code to new format for VMware Fusion

### [2.0.5] - 2015-02-06
- Migrated create and delete code to new format for VirtualBox and fixed error with deleting VMs

### [2.0.4] - 2015-02-05
- Migrated help, list and VirtualBox code to new format

### [2.0.3] - 2014-12-02
- Added workaround for Ubuntu 14.10 PXE boot bug

### [2.0.2] - 2014-12-01
- Added initial client support for SLES 12

### [2.0.1] - 2014-12-01
- Added directory permissions checks for work directory

### [2.0.0] - 2014-10-29
- Added initial server support for SLES 12

### [1.9.9] - 2014-10-29
- Added code to delete repository directory if not deleted as part of zfs destroy

### [1.9.8] - 2014-09-04
- Fixed bugs with preseed

### [1.9.7] - 2014-09-03
- Cleaned up OVA code

### [1.9.6] - 2014-09-02
- Added export for VirtualBox VMs

### [1.9.5] - 2014-09-02
- Added import for VMware Fusion VMs

### [1.9.4] - 2014-08-31
- Added code to list running VMs

### [1.9.3] - 2014-08-31
- Added function to connect to serial port of VM

### [1.9.2] - 2014-08-31
- Added additional support for running ESX and vCenter under Virtual box

### [1.9.1] - 2014-08-29
- Added code to add DHCP and hosts entries for standard clients

### [1.9.0] - 2014-08-29
- Added IP and MAC address handling to VirtualBox cloning

### [1.8.9] - 2014-08-29
- Added IP, hostname and MAC address handling to VirtualBox import

### [1.8.8] - 2014-08-29
- Added VirtualBox import and clone code

### [1.8.7] - 2014-08-28
- Fixed ESXi serial support

### [1.8.6] - 2014-08-27
- Improved VirtualBox serial connectivity

### [1.8.5] - 2014-08-27
- Improved addition and removal of hosts

### [1.8.4] - 2014-08-26
- Fixed plumbing of vboxnet interface

### [1.8.3] - 2014-08-04
- Cleaned up puppet mirror and kickstart code

### [1.8.2] - 2014-08-02
- Removed/added packages for RHEL 7 based releases

### [1.8.1] - 2014-08-02
- Updated code for Solaris 11.2

### [1.8.0] - 2014-08-02
- Cleaned up local config output

### [1.7.9] - 2014-08-02
- Fixed -j switch

### [1.7.8] - 2014-07-17
- Added support for Scientific Linux 7

### [1.7.7] - 2014-07-17
- Added support for OEL 7

### [1.7.6] - 2014-07-16
- Added support for Centos 7

### [1.7.5] - 2014-07-16
- Fixed bug with IP forwarding check

### [1.7.4] - 2014-07-16
- Fixed bugs with local config check on OS X

### [1.7.3] - 2014-06-19
- Fixed bug with mounting CDs for AI

### [1.7.2] - 2014-06-19
- Fixed bugs with processing questions

### [1.7.1] - 2014-06-16
- Added initial CoreOS PXE boot support

### [1.7.0] - 2014-06-15
- Fedora 20 fixes and Fedora 19 support

### [1.6.9] - 2014-06-15
- Fedora 20 client support

### [1.6.8] - 2014-06-15
- Initial Fedora support

### [1.6.7] - 2014-06-15
- Inital OpenBSD support

### [1.6.6] - 2014-06-14
- Added code to set up BSD server

### [1.6.5] - 2014-06-14
- Numerous bug fixes and RHEL 7 support

### [1.6.4] - 2014-06-13
- Added code to setup a local package repository if it doesn't exist

### [1.6.3] - 2014-06-13
- Cleaned up server setup code

### [1.6.2] - 2014-06-11
- Cleaned up code to check hostonly networking

### [1.6.1] - 2014-06-10
- Various bug fixes

### [1.6.0] - 2014-06-08
- Added code to automatically create hostonly network if not present on VirtualBox and attach Guest Additions ISO

### [1.5.9] - 2014-06-08
- Added support for SAS controller to VirtualBox VMs and made it default

### [1.5.8] - 2014-06-08
- Fixed bugs with AI client creation

### [1.5.7] - 2014-06-07
- Improved handling of values with VMware Fusion and VirtualBox functions

### [1.5.6] - 2014-06-07
- Fixed bugs with VirtualBox VM creation

### [1.5.5] - 2014-06-07
- Added code to set architecture for VMware Fusion VMs if not given for Solaris

### [1.5.4] - 2014-06-07
- Added code to set default manifest to another manifest rather than updating the default

### [1.5.3] - 2014-06-07
- Added code to check listening interface is set up for DHCP on Solaris 11

### [1.5.2] - 2014-06-06
- Added option to set server size (e.g. small or large) for AI clients

### [1.5.1] - 2014-06-06
- Fixed more bugs with AI server installation and de-installation

### [1.5.0] - 2014-06-05
- Fixed bugs with Solaris 11 AI server configuration

### [1.4.9] - 2014-05-29
- Fixed bugs with ESXi configuration (5.5.0u1 test OK)

### [1.4.8] - 2014-05-29
- Fixed bug with listing Solaris 11 ISOs and improved help

### [1.4.7] - 2014-05-28
- RHEL 7.0 RC support and bug fixes

### [1.4.6] - 2014-05-27
- Improved ISO file name processing and added initial RHEL 7.0 RC ISO copy support

### [1.4.5] - 2014-05-25
- Bug fixes

### [1.4.4] - 2014-05-24
- Fix bugs with set up on Solaris

### [1.4.3] - 2014-02-12
- Added Puppet master support for Solaris 11

### [1.4.2]
- Cleaned up puppet support and added second DVD import capability for CentOS

### [1.4.1] - 2014-02-08
- Added code to fetch puppet RPMs

### [1.4.0] - 2014-02-08
- Added OS X dnsmasq and puppet configuration to Ubuntu Preseed

### [1.3.9] - 2014-02-07
- Added initial puppet master configuration

### [1.3.8] - 2014-02-06
- Added code to check DHCPd plist on OS X

### [1.3.7] - 2014-02-03
- Added flar based installs for Jumpstart

### [1.3.6] - 2014-02-03
- Cleaned up jumpstart client support

### [1.3.5] - 2014-02-01
- Initial Jumpstart client creation support on OS X

### [1.3.4] - 2014-02-01
- Added initial OS X Jumpstart server support

### [1.3.3] - 2014-01-31
- Fixed password crypt on OS X

### [1.3.2] - 2014-01-31
- Cleaned up OS X support

### [1.3.1] - 2014-01-31
- Fixed warnings

### [1.3.0] - 2014-01-30
- Cleaned up Solaris Zone code

### [1.2.9] - 2014-01-28
- Added dtrace install to OEL 6.5 Kickstart

### [1.2.8] - 2014-01-28
- Increased default /boot size

### [1.2.7] - 2014-01-28
- Update epel.repo to use local mirror

### [1.2.6] - 2014-01-28
- Fixed OEL support

### [1.2.5] - 2014-01-28
- Initial OEL support

### [1.2.4] - 2014-01-28
- Cleaned up output code

### [1.2.3] - 2014-01-27
- Bug fixes for kickstart postinstall script

### [1.2.2] - 2014-01-26
- Added support for Scientific Linux

### [1.2.1] - 2014-01-26
- Numerous bug fixes

### [1.2.0] - 2014-01-25
- Added code to use local mirror for apt sources

### [1.1.9] - 2014-01-25
- LXC bug fixes

### [1.1.8] - 2014-01-25
- Ubuntu LXC support

### [1.1.7] - 2014-01-24
- Initial working LXC support

### [1.1.6] - 2014-01-23
- Started to add LXC support

### [1.1.5] - 2014-01-23
- Fixed Kickstart and Preseed configuration file creation bugs

### [1.1.4] - 2014-01-22
- Minor updates

### [1.1.3] - 2014-01-22
- Added initial Guest domain support

### [1.1.2] - 2014-01-22
- Various fixes

### [1.1.1] - 2014-01-21
- Fixed bugs with DHCP config check and Solaris ISO processing for jumpstart

### [1.1.0] - 2014-01-21
- Initial LDom primary domain setup code

### [1.0.9] - 2014-01-21
- Minor updates

### [1.0.8] - 2014-01-21
- Initial Solaris Zones support

### [1.0.7] - 2014-01-20
- Added check to make sure AI profile doesn't already exist

### [1.0.6] - 2014-01-20
- Fixed various bugs with questions and AI clients

### [1.0.5] - 2014-01-19
- Fixed apache configuration on OS X

### [1.0.4] - 2014-01-19
- Fixed ISO mounting on OS X

### [1.0.3] - 2014-01-19
- Added intial support for Linux as a server

### [1.0.2] - 2014-01-18
- Added initial support for OS X as a server

### [1.0.1] - 2014-01-17
- Added SLES AutoYast client support

### [1.0.0] - 2014-01-14
- Added SLES server support

### [0.9.9] - 2014-01-11
- Added basic Ubuntu preseed support

### [0.9.8] - 2014-01-09
- Minor fixes

### [0.9.7] - 2014-01-09
- Cleaned up ESXi kickstart script

### [0.9.6] - 2014-01-09
- Fixed ESXi boot.cfg creation

### [0.9.5] - 2014-01-08
- Added inital ESX server support

### [0.9.4] - 2014-01-07
- Fixed VirtualBox VM creation and deletion

### [0.9.3] - 2014-01-07
- Improved help and VirtualBox handling

### [0.9.2] - 2014-01-06
- Added code to create and manage Virtual Box VMs

### [0.9.1] - 2014-01-06
- Fixed ruby warning messages

### [0.9.0] - 2014-01-05
- Added service check to client creation

### [0.8.9] - 2014-01-05
- Added x86_64 and i386 support to Kickstart

### [0.8.8] - 2014-01-05
- Added handling for lzma rpms

### [0.8.7] - 2014-01-05
- Fixed directory check for RHEL ISOs

### [0.8.6] - 2014-01-04
- Bug fixes, and initial Jumpstart support complete (need to add alternate package support)

### [0.8.5] - 2014-01-04
- Cleaned up PXE and DHCP code

### [0.8.4] - 2014-01-04
- Fix bugs with Jumpstart client code

### [0.8.3] - 2014-01-03
- Cleaned up jumpstart server configuration code

### [0.8.2] - 2014-01-03
- Added code for creating rules.ok file

### [0.8.1] - 2014-01-03
- Fixed default answer code

### [0.8.0] - 2014-01-03
- Added PXE and DHCP config creating for jumpstart

### [0.7.9] - 2014-01-03
- Updated usage information

### [0.7.8] - 2014-01-03
- Fixed jumpstart sysidcfg

### [0.7.7] - 2014-01-03
- Added code to unconfigure jumpstart client

### [0.7.6] - 2014-01-03
- Added code check rules and create rules.ok file for jumpstart client

### [0.7.5] - 2014-01-02
- Code cleanup and initial Jumpstart client configuration file support

### [0.7.4] - 2014-01-02
- Fixed question processing

### [0.7.3] - 2014-01-02
- Fixed jumpstart file system list

### [0.7.2] - 2014-01-02
- Fixed Solaris update checking

### [0.7.1] - 2014-01-02
- Fixed model handling for Jumpstart

### [0.7.0] - 2014-01-02
- Initial code for Jumpstart clients

### [0.6.9] - 2014-01-02
- Initial code for Jumpstart questions

### [0.6.8] - 2014-01-01
- Added code to fix rm_values['name'] and check scripts

### [0.6.7] - 2014-01-01
- Added code to enable NFS and TFTP server for Jumpstart

### [0.6.6] - 2014-01-01
- Added initial Jumpstart server code

### [0.6.5] - 2013-12-31
- Cleaned up code

### [0.6.4] - 2013-12-31
- Cleaned up main routine and made code more modular

### [0.6.3] - 2013-12-30
- Fixed post package install

### [0.6.2] - 2013-12-30
- Fixed kickstart post

### [0.6.1] - 2013-12-30
- Updated kickstart alternate packages

### [0.6.0] - 2013-12-30
- Added code to add admin user to kickstart file

### [0.5.9] - 2013-12-30
- Fixed KS dhcp code

### [0.5.8] - 2013-12-30
- Added code to unonfigure Linux client PXE boot

### [0.5.7] - 2013-12-30
- Fixed Linux PXE boot image copy code

### [0.5.6] - 2013-12-30
- Added code to create PXE boot files of kickstart client

### [0.5.5] - 2013-12-29
- Added code to copy boot images to tftpboot directory

### [0.5.4] - 2013-12-29
- Fixed Linux ISO copy

### [0.5.3] - 2013-12-29
- Added code to copy Linux PXE boot files from RPM file

### [0.5.2] - 2013-12-29
- Fixed bugs with kickstart file creation

### [0.5.1] - 2013-12-29
- Added initial kistart file output code

### [0.5.0] - 2013-12-29
- Added capability to change question structure

### [0.4.9] - 2013-12-29
- Fixed question processing

### [0.4.8] - 2013-12-29
- Initial Kickstart client support

### [0.4.7] - 2013-12-28
- Added code to list Kickstart clients

### [0.4.6] - 2013-12-28
- Added code to list Kickstart services

### [0.4.5] - 2013-12-28
- Added code to list AI clients

### [0.4.4] - 2013-12-28
- Added code to list AI services

### [0.4.3] - 2013-12-28
- Added code to add and remove apache alias for kickstart directory

### [0.4.2] - 2013-12-28
- Added Linux ISO mount and copy code

### [0.4.1] - 2013-12-28
- Fixed multiline output

### [0.4.0] - 2013-12-27
- Added ruby to base installation

### [0.3.9] - 2013-12-27
- Fixed grub.cfg update code

### [0.3.8] - 2013-12-27
- Fixed package dependency handling

### [0.3.7] - 2013-12-27
- Fixed package version check

### [0.3.6] - 2013-12-27
- Fixed package creation

### [0.3.5] - 2013-12-26
- Added code to install and uninstall packages

### [0.3.4] - 2013-12-26
- Fixed package repository check

### [0.3.3] - 2013-12-26
- Fixed alternate repository prefix

### [0.3.2] - 2013-12-26
- Fixed alternate repository creation and deletion

### [0.3.1] - 2013-12-26
- Updated usage information

### [0.3.0] - 2013-12-26
- Added more value checking

### [0.2.9] - 2013-12-26
- Added code for alternate package repository to deploy puppet packages

### [0.2.8] - 2013-12-24
- Fixed bug with editing grub.cfg

### [0.2.7] - 2013-12-23
- Fixed bug with backing up dhcp config

### [0.2.6] - 2013-12-23
- Added code to restart dhcp service

### [0.2.5] - 2013-12-23
- Added code to remove range entry from dhcpd config

### [0.2.4] - 2013-12-22
- Added code to extract release version from repository

### [0.2.3] - 2013-12-22
- Added code to use local file based repository if it exists

### [0.2.2] - 2013-12-20
- Fixed XML output bugs

### [0.2.1] - 2013-12-20
- Added code to change timeout and default menu item in netboot grub.cfg

### [0.2.0] - 2013-12-20
- Fixed bugs with error handling and XML creation

### [0.1.9] - 2013-12-20
- Added additional questions to profile

### [0.1.8] - 2013-12-19
- Fixed bugs with AI manifest creation

### [0.1.7] - 2013-12-19
- Cleaned up deletion code

### [0.1.6] - 2013-12-19
- Fixed pkg url in manifest

### [0.1.5] - 2013-12-19
- Fixed order of questions

### [0.1.4] - 2013-12-19
- Fixed issue with XML

### [0.1.3] - 2013-12-19
- Fixed auto_install directory to include release information

### [0.1.2] - 2013-12-19
- Fixed service creation

### [0.1.1] - 2013-12-19
- Cleaned up server configuration code

### [0.1.0] - 2013-12-18
- Added to delete service

### [0.0.9] - 2013-12-18
- Fixed ISO file determination

### [0.0.8] - 2013-12-18
- Improved verbose output

### [0.0.7] - 2013-12-18
- Added AI service manifest creation code

### [0.0.6] - 2013-12-18
- Added code to be able to create only one AI architecture service

### [0.0.5] - 2013-12-18
- Added code to delete AI client and service

### [0.0.4] - 2013-12-17
- Fixed processing of questions

### [0.0.3] - 2013-12-17
- Fixed system command output

### [0.0.2] - 2013-12-17
- Fixed AI publisher typo

### [0.0.1] - 2013-12-17
- Fixed Dir.* usage to be compatible on ruby 1.8

## webserver.rb

### [0.0.6] - 2026-09-28
- Fixed undefined ssl_password crashing SSL startup
- Fixed broken Basic Auth check that compared a freshly re-hashed stored hash instead of the submitted password, and could raise on an unknown username
- Replaced unsanitized eval of request parameters with a whitelisted method dispatcher, closing a remote code execution hole in the /list and /add/client and / routes
- Fixed dump_errors being set to the truthy string 'false' instead of boolean false, which left error/stack-trace dumping enabled

### [0.0.5] - 2025-06-07
- Code cleanup based on rubocop

### [0.0.4] - 2016-08-22
- More fixes and webserver plumbing

### [0.0.3] - 2016-08-18
- Added parseconfig gem to webserver

### [0.0.2] - 2016-08-17
- Added initial webserver functionality

### [0.0.1] - 2016-08-17
- Initial working webserver
