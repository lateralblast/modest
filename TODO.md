# TODO

Status: `[ ]` open, `[~]` in progress, `[x]` done.

## Open

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
- [ ] Extend `--install` to other packages checked by `--check` (for example dnsmasq and packer). Only VirtualBox is wired up.
- [ ] Decide whether `--install` should keep the name it has now. It is an optional-value switch: bare `--install` means install with `--check`, and `--install VALUE` keeps the install-type meaning used by KVM and Solaris.
- [x] The `Executing: ipconfig getifaddr en0` line is removed from normal output (9.1.0). The probe in `get_my_ip` (`methods/common/common.rb`) is still run from the defaults, which pass no `verbose` flag, so it does not show even with `--verbose`.
- [ ] Review the `sudo sh -c cat ...` read in the macOS service checks. It runs under `--dryrun` and can prompt for a password, even though it only reads a plist.

## Done

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
