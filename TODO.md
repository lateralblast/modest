# TODO

Status: `[ ]` open, `[~]` in progress, `[x]` done.

## Open

- [ ] Packer install of arm64 Ubuntu 26.04.1 on Fusion, `--type packer --os-type ubuntu --vm fusion` with `~/Documents/modest/export/isos/ubuntu-26.04.1-live-server-arm64.iso`. Status: the installer boots and runs the autoinstall seed, then stops on the early commands. Fixed so far (10.2.3 to 10.3.1, see CHANGELOG): `--size none` override, host-only SSH port 22, `network_adapter_type`, `--action build --dryrun` starting a real build, static address on the kernel line (`ip=`), top-level `package_update`/`package_upgrade`, `ip addr replace`, `ip route replace`, and clearing the stale output directory before a build. Last failure: `ip route add default` (now `replace`); the 10.2.11 run was stopped before it finished. Next: close the stale Fusion VM window (`ubuntu2604pk01`, left by a SIGINT'd build), regenerate the client with `--action create --type packer ...`, run `--action build --name ubuntu2604pk01 --vm fusion`, and check that Packer connects over SSH to 192.168.2.101:22 and runs the provisioning. Known open points: the boot command uses GRUB `e`-edit keystrokes that are not confirmed on this arm64 GRUB; `--action build` on a stuck VM leaves the VMX running after a SIGINT; the template hard-codes the password `P455w0rd` for the Packer SSH login and the installed user, which should come from a flag or be generated

- [ ] `--vm kvm` fails argument validation with "Invalid value for disk: contains characters not allowed in shell arguments", even for `--action list --vm kvm`. `--vm qemu` and `--vm libvirt` work. Find which kvm default for `disk` trips the shell-argument check in `methods/common/values.rb`
- [ ] Do not set `dtb.nofixup` in a Fusion VMX: it is not a supported key, and setting it made Fusion shut the VM down with an error. The arm64 PXE stall (see the PXE install item) is still open
- [ ] PXE install of arm64 Ubuntu on Fusion: the client add (`--action add --mode client --method ci`) configures the kernel, initrd, seed and per-MAC GRUB menu, and the netboot GRUB requests its config and loads the kernel and initrd over TFTP. The kernel then stalls in its EFI stub ("HWID matching failed, no DT blob") with no further output, so the installer never fetches the ISO. Next: try a different netboot kernel or the firmware's DT settings, or get kernel output from the stub stage.
- [ ] macOS server setup for an arm64 Ubuntu ISO (`add --mode server`): generate the dnsmasq config for the host-only bridge (DHCP and TFTP, bridge name looked up at run time) instead of isc-dhcp, configure Homebrew httpd instead of `/etc/apache2`, and copy the boot files into `/private/tftpboot` with sudo
- [ ] Generate the cloud-init seed for a Fusion arm64 VM with `ssh: install-server: true`, `openssh-server` installed, and the key from `sshkeyfile` written as `authorized-keys`, so SSH works without a password after install
- [ ] `create --vm fusion --method ci` on Apple Silicon: test end to end on a new VM and SSH in with the key (test VM `modest-vnet9-test` was built by hand)
- [ ] Fusion `--size none` (no `--size`) still needs a proper fix beyond the 20GB fallback in 9.6.4

- [ ] `--action create --vm fusion --os-type ubuntu --release 2204` fails under `--dryrun` writing the VMX file, because the VM directory is created by a `mkdir` that dry-run skips (`methods/vmware/fusion/common.rb` around line 1478). The VM network is also not configured here, because Fusion host-only networking is not set up on this Mac. A real Fusion create has not been run.
- [ ] Systemic arity mismatches: a whole-tree check finds about 150 call sites whose argument count does not match the definition. Many are false positives (the same name is defined per platform), but the Solaris zone code, LDom and Jumpstart code, and most of the VirtualBox create path (`add_nonbridged_network_to_vbox_vm`, `modify_vbox_vm`, `setextradata_vbox_vm`, `add_hosts_entry`, `change_vbox_vm_mac`) are affected. VirtualBox create in dry-run still fails. Fix as a dedicated pass, with a test per function.
- [ ] Docker server side is not finished: `methods/docker/server.rb` calls `create_docker_file` with one argument (it takes two), uses undefined `$docker_host_*` globals, writes a Dockerfile with no newlines and an invalid `FROM:` line, and `build_docker_file` does nothing.
- [ ] Add `execute` to the valid `--action` values (and `--command`), so `methods/docker/client.rb`'s exec path can be run from the command line. Also decide the Docker delete check: `--action delete --vm docker` has not been run for real.
- [x] `--action create --vm zone` ran the LXC questions. Zones are now refused on non-SunOS hosts with a message, and the LXC questions use the right struct (9.2.2, 9.2.3).
- [x] Linux containers (LXC) questions and standard container creation fixed (9.2.2, 9.2.4). Standard containers only run on Ubuntu hosts; the wiki LXC page is still missing.
- [ ] Wiki pages still missing for Ansible, cloud-init, BSD, WinPE, QEMU, Solaris zones and Linux containers. Parallels and Docker now have pages.
- [x] `list` and `boot` without `--method` ran past the nil-value failures (9.1.5 to 9.2.1). They now complete in dry-run for VirtualBox, Fusion and Parallels. Not yet run for real.
- [ ] Parallels `--action boot`, `stop`, `delete` and `connect` have not been run for a real VM. Create, list and check are verified in dry-run only.
- [x] Dry-run ran `sudo` on read-only probes. Fixed in 9.2.7 (no sudo wrapping under `--dryrun`) and 9.2.8 (literal `sudo` prefixes dropped for read-only commands under `--dryrun`).
- [ ] Test `--check parallels --install` for real on a Mac without Parallels, and check that the Homebrew cask install completes. The installed path has been run (Parallels 27.1.0).
- [x] `--check fusion` confirmed on macOS with VMware Fusion 25.0.1 installed (version and location reported). Still untested: `--check workstation` on a Linux host with VMware Workstation installed.
- [ ] Decide what `--install` should do for VMware. Fusion and Workstation are not in Homebrew or apt, so `--install` only prints the download page for now.
- [ ] Start the web front end (`webserver.rb`) and check the new parameter validation returns HTTP 400 for unsafe values and normal pages still work (validation added in webserver 0.0.9).
- [ ] Run a real `--dryrun` and then a real create/delete for VirtualBox and KVM, checking the escaped commands and the Ruby routing in `methods/common/files.rb` end to end. The repo has no test suite, so this is manual.
- [ ] Test the Linux and Solaris branches. Only macOS has been run. The likeliest differences are in the `/proc`-based probes in `methods/common/defaults.rb`.
- [ ] Review the guest-side `post_list` scripts in the kickstart, preseed, LXC and zones code. They run inside VMs, so they are a different threat from the host-side shell injection already fixed.
- [ ] Review the rest of the repo. The bug review so far covered the shell-out paths and web input only, not all ~38k lines. A per-directory pass with parallel review agents would close this.
- [ ] Move the remaining host probes to Ruby where that is straightforward: `ifconfig`, `netstat -rn`, `ip r`, `lsb_release`, `dmidecode`, `sw_vers`, `system_profiler`, `prtdiag`, `dladm`, and `uname -p` (Ruby's `Etc.uname` gives a different machine string on macOS). Each needs its output parsed, so each is its own change.
- [ ] Decide whether the Solaris `which` calls should move to Ruby. They match Solaris's `no X in PATH` message, so the replacement has to reproduce that text.
- [ ] Extend the file-operation router to the cases it still sends to the shell: `cp -r` and `cp -p`, glob arguments, quoted text containing `(`, `#` or `*`, and `echo` text containing a backslash.
- [ ] Decide whether the packer `awk '{print $3}'` pipelines should move to Ruby. Their `$` is unescaped, which the router rejects by design, so they would need an explicit parser.
- [ ] Audit the dry-run denylist in `execute_command` (`methods/common/common.rb`). It is a regex of command words, and it has already missed mutating commands: `--dryrun --check dnsmasq` ran `sudo launchctl load` (fixed in 8.9.5). Each `execute_command` call site should be checked for mutating commands that are not matched. The denylist also now skips read calls to `virsh`, `prlctl`, `multipass`, `zfs`, `ldm` and similar CLIs under `--dryrun`, which changes dry-run output for those tools. Consider a per-call-site flag instead.
- [ ] Decide whether normal runs should print the 509 `Setting value for ...` lines from `process_values` (`methods/common/values.rb`). They are logged as Information on every run, not only with `--verbose`. The informational switches are already clean.
- [ ] Fix the `quit` helper in `methods/common/common.rb`. It only exits when `values['dryrun'] == false`, so under `--dryrun` (or wherever `dryrun` is unset) it returns and the run carries on. Example: `--dryrun --check dhcp` prints `Launch Agent not found`, then reports the service as `enabled` (`check_osx_service_is_enabled`, `methods/macos/common.rb`). Several call sites depend on it, so review each one before changing it.
- [ ] Test `--check virtualbox --install` for real on macOS and on a Linux host. It has only been run in dry-run, or for the failing download path, because a real install changes the machine. Check the `virtualbox` and `virtualbox-ext-pack` package names on Debian and Ubuntu, and the `virtualbox` package on RHEL-family systems, where it is not in the base repositories.
- [x] Extension Pack install: name mismatch found (the download was saved under a different file name) and fixed in 9.0.4. Also runs with sudo unless root. Rerun to confirm.
- [x] Extension Pack install on macOS confirmed end to end on VirtualBox 7.2.22 (9.0.7): `--check virtualbox --install` installs it, with the licence answered in the terminal. Still untested: a real VirtualBox install on Linux.
- [ ] Homebrew reports that the third-party tap `dkorunic/tap` is ignored until it is trusted. The VirtualBox cask install was not affected. Decide whether to trust, untap or leave it. The tool should not change that setting for you.
- [ ] Decide whether Debian and Ubuntu should still pre-accept the Extension Pack licence through debconf (current behaviour), or ask the user first as macOS now does.
- [ ] Extend `--install` to other packages checked by `--check`. VirtualBox, Parallels and Packer are wired up (Packer in 10.2.2). dnsmasq is still open.
- [ ] Decide whether `--install` should keep the name it has now. It is an optional-value switch: bare `--install` means install with `--check`, and `--install VALUE` keeps the install-type meaning used by KVM and Solaris.
- [x] The `Executing: ipconfig getifaddr en0` line is removed from normal output (9.1.0). The probe in `get_my_ip` (`methods/common/common.rb`) is still run from the defaults, which pass no `verbose` flag, so it does not show even with `--verbose`.
- [ ] Review the `sudo sh -c cat ...` read in the macOS service checks. It runs under `--dryrun` and can prompt for a password, even though it only reads a plist.

- [ ] `methods/libvirt/common.rb` line 371 assigns `values['method'] = 'ci'` in the `if`, so `configure_kvm_client` always takes the cloud-init branch and never the kickstart/preseed questions. Compare with `==` (or `match?`) instead
- [ ] `methods/packer/json.rb` line 783 matches the RHEL-family template with `/fedora|[el,centos,rocky,alma]_[8,9]/`. The brackets are a character class, so any letter from those names before `_8` or `_9` matches. `debian_9` takes the RHEL-family branch (checked in Ruby). Use `(fedora|el|centos|rocky|alma)_[89]`, and check the template for `debian_9` after the change

## Install methods by VM system

Where each install method stands on each VM system. Status is what has been run, not what the code could do:

- **Verified:** run for real, with the result recorded.
- **Partial:** part of the path is verified, with the open part noted in the cell.
- **Code only:** a create path exists in the code but has not been run here.
- **Not verified:** the guest OS mapping exists, but no install has been run.
- **Not wired:** the VM system has no install wiring for that method.
- **n/a:** the method does not apply to that VM system.

Method codes: `ci` Ubuntu 26.04 live server (subiquity, cloud-init), `ks` Kickstart, `ps` Preseed, `ay` AutoYaST, `js` Jumpstart, `ai` Solaris AI, `pe` WinPE, `vs` vSphere.

| Method | Fusion (macOS) | VirtualBox (macOS) | Parallels (macOS) | KVM / libvirt | QEMU (`qemu-system-*`, macOS) | Multipass | Packer (any builder) | Docker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ci` | Partial: arm64 create, boot and SSH with key verified, no PXE. The PXE client stalls at the EFI stub | Partial: arm64 ISO create verified after fixes. No host-only networking on this Mac, and keystrokes do not reach the guest on arm64 | Not wired | Code only: a branch exists, but see the open `configure_kvm_client` item | Partial: PXE install reached subiquity partitioning and finished the kernel install at 8 GB. The `casper url=` route did not fetch the squashfs at 4 GB. The installed disk is not yet checked for SSH | Code only: a `ci` branch exists in `configure_multipass_vm` Partial: the autoinstall seed runs and the early commands are the current blocker (see the open Packer item). The build has not finished | n/a |
| `ks` | Not verified | Not verified | Not wired | Code only | n/a | n/a | Code only: RHEL-family template (see open regex item) | n/a |
| `ps` | Not verified | Not verified | Not wired | Code only | n/a | n/a | Code only: Debian and Ubuntu template | n/a |
| `ay` | Not verified | Not verified | Not wired | Code only | n/a | n/a | Code only: SLES template | n/a |
| `js` | Not verified | Not verified | Not wired | n/a | n/a | n/a | Code only: Solaris 10 template | n/a |
| `ai` | Not verified | Not verified | Not wired | n/a | n/a | n/a | Code only: Solaris 11 template | n/a |
| `pe` | Not verified | Not verified | Not wired | n/a | n/a | n/a | Code only: Windows template | n/a |
| `vs` | Not verified | Not verified | Not wired | n/a | n/a | n/a | Code only: vSphere and ESXi template | n/a |
| Container image | n/a | n/a | n/a | n/a | n/a | n/a | n/a | Verified: `--action create --vm docker --os ubuntu` built `ubuntu26041` (9.4.3). The server side is unfinished (open item) |

Notes:

- **Parallels:** `configure_<method>_parallels_vm` only registers the VM with an OS type. No install configuration is attached for any method. Create is verified in dry-run only, and boot, stop and delete have not been run for real.
- **VirtualBox:** the create path has arity mismatches that break dry-run (open item). Only `ci` has a verified path, and it is the arm64 ISO route, not PXE.
- **macOS deployment server:** `configure_osx_netboot_services` (dnsmasq for DHCP and TFTP, Homebrew httpd for the ISO and seed) applies to any Linux method on macOS. Only `ci` has been tested end to end, with the QEMU test.
- **Fusion, non-`ci` methods:** `get_fusion_guest_os` maps `ai`, `js`, `ay`, `nb`, `ob`, `ps`, `pe`, `ks` and `vs` to a guest OS. No install of those has been run.
- **Packer:** the column is the template code, which Packer uses with its VirtualBox, Fusion, Parallels and KVM/QEMU builders. Packer is not installed on this Mac, so nothing has been built with it here.
- **Other VM systems** (AWS, Ansible, zones, LDoms, LXC and the vSphere/VCSA deployment) are not in this table. Their status is recorded in the Open and Done items above.

## Deployment server capabilities

What the deployment server provides for a PXE or network install, and how far each part has been checked. The status words are the same as the install-method table above.

| Capability | macOS (netboot services) | Linux (ISC dhcpd, tftpd, Apache) | Solaris 11 (AI, `installadm`) | Solaris 10 (Jumpstart) |
|---|---|---|---|---|
| DHCP | Verified: dnsmasq handed a Fusion vmnet9 client an address (192.168.209.134) from the netboot range. Dry-run only for the other networks | Code only: `check_yum_dhcpd` and `check_apt_dhcpd` install the server. `dhcpdfile` is `/etc/dhcp/dhcpd.conf` | Code only: not re-run here. CLAUDE.md calls Solaris 11 the most-tested server OS | Code only: `dhcpdfile` is `/etc/inet/dhcpd4.conf` |
| TFTP (GRUB or PXE loader) | Verified: Fusion clients loaded the per-MAC GRUB menu over TFTP and reached the kernel. dnsmasq serves `/private/tftpboot` | Code only: `tftpdir` is `/var/lib/tftpboot`, with inetd or xinetd set up | Code only: not re-run here | Code only: `tftpdir` is `/etc/netboot` |
| HTTP (ISO, repo, seed) | Partial: Homebrew httpd on port 8081 is configured. The QEMU tests served the ISO and seed with `python3 -m http.server`, and the Fusion client never reached HTTP | Code only: `add_apache_alias`, which returns early on Darwin | Code only: not re-run here | Not checked |
| Cloud-init seed over HTTP (NoCloud) | Partial: the seed was built and fetched by the QEMU client (`user-data` at 02:50:30). The tool's own HTTP path is unconfirmed | n/a | n/a | n/a |
| Netboot config generation (dnsmasq, httpd, GRUB menus) | Verified: `configure_osx_netboot_services` writes the config and starts dnsmasq and httpd | Code only | Code only | Code only |
| Host network for the VMs | Verified on Fusion: `--nic bridge104` on the vmnet9 host-only network. Parallels host-only is dry-run only. VirtualBox host-only does not load on this Mac | Not checked | Not checked | Not checked |
| Serial console to the VM | Verified on Fusion through the socket. VirtualBox does not pass keystrokes on arm64. QEMU is a manual test, not the tool's create path | Not checked | Not checked | Not checked |

Notes:

- The macOS column is where the testing happened. The Linux and Solaris columns are code paths that have not been run in this work.
- On macOS the netboot path uses dnsmasq for DHCP and TFTP instead of ISC dhcpd, and `check_dhcpd_config` returns early on Darwin.
- A macOS HTTP check against the tool's own httpd (not the python server) is needed before HTTP can be marked verified.

## Done

- [x] Two-way serial console on the Fusion arm64 install: typed input reaches the VM, and a login prompt appears on the serial console (9.8.3)
- [x] Read-only and no-OS creates no longer run `ifconfig` or `grep` with empty names; the no-OS create stops with status 1 (9.4.8, 9.4.9, 9.5.0)
- [x] Add: `--action create --vm docker --os ubuntu --release <release>` creates an Ubuntu Docker instance with the `docker` CLI for the host architecture, falling back to the release line when the exact tag is not published. Created `ubuntu26041` from `ubuntu:26.04` (9.3.7 to 9.4.3)
- [x] Normal runs are quiet: startup and `Setting ...` messages and `Executing:` lines show only with `--verbose` (or `Executing:` under `--dryrun`), and list results print without `--verbose` (9.3.4 to 9.3.6)
- [x] Read-only actions such as `--action list --vm docker` no longer configure the host-only network with `sudo ifconfig ... up` (9.3.3)
- [x] Add: `--check parallels` (macOS) reports whether Parallels Desktop and `prlctl` are present, with the version; `--install` uses `brew install --cask parallels` (9.1.1)
- [x] Add: `--check fusion` (macOS) and `--check workstation` (Linux) report whether VMware is installed, with version and vmrun (9.0.8). `--help` shows `--check`/`--install` correctly (9.0.9)
- [x] Fix: `--check` runs quietly, showing only the check it runs. Default-setting lines are verbose-only, `--check perms` names the directory and `--check dnsmasq` announces itself (8.9.6, 8.9.7)
- [x] Fix: `--check dhcp` and `--check tftp` raised an `ArgumentError` and a `NameError` in the macOS service helpers (8.9.8)
- [x] Fix: `--check` with no value lists the available parameters and exits with status 1, and `--check VALUE` selects the check action (8.9.3, 8.9.9)
- [x] Add: `--check virtualbox` (alias `vbox`) reports whether VBoxManage is installed, with its version and location (9.0.0)
- [x] Add: `--install` given with `--check` and no value installs what the check finds missing; `--check virtualbox --install` installs VirtualBox (9.0.1)
- [x] Add: `--check virtualbox` reports the VirtualBox Extension Pack, and `--install` installs it (9.0.2)
- [x] Fix: macOS dnsmasq, DHCP and TFTP checks called `install_brew_pkg` with the wrong number of arguments (8.9.4)
- [x] Fix: `--dryrun` ran `sudo launchctl load` because `launchctl` was not in the denylist; denylist extended to launchctl, hdiutil, pfctl, ipfw, natd and the platform CLIs (8.9.5)
- [x] Fix: `--version`, `--help`, `--changelog` and `--usage` print only their own output, and an invalid option exits with status 1 (8.9.2)
- [x] Fix: `cd DIR ; ...` sequences and `chown`/`chgrp` run in Ruby when the commands that follow are supported file operations; `chown`/`chgrp` only as root (8.9.1)
- [x] Fix: `cat FILE | ... > DEST` and `>> DEST` pipelines, and compound commands that chain them with file operations, run in Ruby (8.9.0)
- [x] Fix: glob characters in file operations are left to the shell, so `rm DIR/*` is never handled in Ruby (8.9.0)
- [x] Change: `cat FILE | grep | head | tail | awk | cut` pipelines run in Ruby, with grep patterns limited to characters that behave the same in Ruby (8.8.0)
- [x] Change: `cp`, `rm`, `mkdir`, `touch`, `rmdir`, `chmod`, `ln -s` and `cat` on one file run in Ruby, with `sudo` fallback on permission errors (8.6.0)
- [x] Change: compound file operations joined by `;` run in Ruby when every part is supported and the targets are writable (8.7.0)
- [x] Change: host probes (`uname`, `hostname`, `whoami`, `id -u`, `getent group`, `sysctl hw.ncpu`, `free -g`, `date`, `which`) use Ruby in `methods/common/host.rb` (8.5.0)
- [x] Fix: `--dryrun` now skips commands that write with `>` or `>>`; `rmdir` added to the denylist (8.7.0, 8.4.1)
- [x] Fix: the webserver `gem install` and `openssl req` backticks escape their values (webserver 0.1.0)
- [x] Fix: web request parameters that reach shell commands are validated and return HTTP 400 when unsafe (webserver 0.0.9)
- [x] Fix: shell-bound CLI values (`--name`, `--ip`, `--mac`, `--vm`, `--method` and others) are validated before any command runs; `--nic` and path fields are not restricted, by decision (8.4.7)
- [x] Fix: values interpolated into shell command strings and backticks are escaped for their quoting context (`shell_arg`, `shell_sq`, `shell_dq`) (8.4.8, 8.4.5)
- [x] Fix: Windows `netsh` batch file is written to a unique file in the temp directory with mode 0600 (8.4.6)
- [x] Fix: a stray quote in the VirtualBox `restorecurrent` command (8.4.4)
- [x] Fix: `sudo sh -c` wrapping escapes the command with `Shellwords.escape` (8.4.3)
- [x] Fix: awk escaping in `get_osx_disk_name` (8.4.2)
- [x] Fix: local commands never ran outside `--dryrun` because of a misspelled `drydun` key (8.4.0)
- [x] Fix: `docker-machine ssh` command had an unmatched quote; Solaris `dd` call had a missing argument (8.4.9)
- [x] Fix: self-signed SSL key is 2048-bit, not 1024-bit (webserver 0.0.8)
