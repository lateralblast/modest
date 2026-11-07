# TODO

Status: `[ ]` open, `[~]` in progress, `[x]` done.

## Open

- [ ] Start the web front end (`webserver.rb`) and check the new parameter validation returns HTTP 400 for unsafe values and normal pages still work (validation added in webserver 0.0.9).
- [ ] Run a real `--dryrun` and then a real create/delete for VirtualBox and KVM, checking the escaped commands and the Ruby routing in `methods/common/files.rb` end to end. The repo has no test suite, so this is manual.
- [ ] Test the Linux and Solaris branches. Only macOS has been run. The likeliest differences are in the `/proc`-based probes in `methods/common/defaults.rb`.
- [ ] Review the guest-side `post_list` scripts in the kickstart, preseed, LXC and zones code. They run inside VMs, so they are a different threat from the host-side shell injection already fixed.
- [ ] Review the rest of the repo. The bug review so far covered the shell-out paths and web input only, not all ~38k lines. A per-directory pass with parallel review agents would close this.
- [ ] Move the remaining host probes to Ruby where that is straightforward: `ifconfig`, `netstat -rn`, `ip r`, `lsb_release`, `dmidecode`, `sw_vers`, `system_profiler`, `prtdiag`, `dladm`, and `uname -p` (Ruby's `Etc.uname` gives a different machine string on macOS). Each needs its output parsed, so each is its own change.
- [ ] Decide whether the Solaris `which` calls should move to Ruby. They match Solaris's `no X in PATH` message, so the replacement has to reproduce that text.
- [ ] Extend the file-operation router to the cases it still sends to the shell: `cp -r` and `cp -p`, glob arguments, quoted text containing `(`, `#` or `*`, and `echo` text containing a backslash.
- [ ] Decide whether the packer `awk '{print $3}'` pipelines should move to Ruby. Their `$` is unescaped, which the router rejects by design, so they would need an explicit parser.
- [ ] Review the dry-run denylist in `execute_command` (`methods/common/common.rb`). It is a regex of command words, so it is easy to get wrong. Consider replacing it with an explicit list of mutating commands per call site.
- [ ] Decide whether normal runs should print the 509 `Setting value for ...` lines from `process_values` (`methods/common/values.rb`). They are logged as Information on every run, not only with `--verbose`. The informational switches are already clean.
- [ ] Check the `quit` helper in `methods/common/common.rb`. It only exits when `values['dryrun'] == false`, so it returns silently in any path where `dryrun` was never set. Several call sites depend on it, so any change needs a review of each one.

## Done

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
