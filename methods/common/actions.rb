# Actions

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
    when /usage/
      print_usage(values)
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
    when /listisos|listimages/
      case values['vm']
      when /kvm/
        list_kvm_images(values)
      end
    when /listvms/
      case values['vm']
      when /kvm/
        list_kvm_vms(values)
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
        verbose_output(values, "Warning:\tNo service of client name specified")
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
              verbose_output(values, "Warning:\tNo VM, client or service specified")
              verbose_output(values, "Available services")
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
                  verbose_output(values, "Warning:\tClient name or snapshot not specified")
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
                verbose_output(values, "Warning:\tNo snapshot name specified")
                if values['name'] == values['empty']
                  verbose_output(values, "Warning:\tNo client name specified")
                  list_all_vm_snapshots(values)
                else
                  list_vm_snapshots(values)
                end
              else
                if values['name'] == values['empty'] && values['snapshot'] == values['empty']
                  verbose_output(values, "Warning:\tNo client or snapshot name specified")
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
              verbose_output(values, "Warning:\tNo #{values['vm']} type, instance or image specified")
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
        verbose_output(values, "Warning:\tNo service type or VM specified")
        return values
      end
    if values['type'].to_s.match(/service/) && !values['service'].to_s.match(/[a-z]/) && !values['service'] == values['empty']
        verbose_output(values, "Warning:\tNo service name specified")
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
            verbose_output(values, "Warning:\tNo Key Pair or Security Group specified")
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
        verbose_output(values, "Warning:\tNo VM, Method or specified")
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
              verbose_output(values, "Warning:\tNo install method specified")
            end
          else
            verbose_output(values, "Warning:\tClient or service name not specified")
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
              verbose_output(values, "Warning:\tClient name not specified")
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
            verbose_output(values, "Warning:\tClient name not specified")
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
            verbose_output(values, "Warning:\tInstall service or VM type not specified")
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
        verbose_output(values, "Warning:\tClient name or clone name not specified")
      end
    when /running|stopped|suspended|paused/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval"[list_#{values['action']}_#{values['vm']}_vms]"
      end
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
        verbose_output(values, "Warning:\tClient name not specified")
      end
    when /attach/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval"[attach_file_to_#{values['vm']}_vm(values)]"
      end
    when /detach/
      if values['vm'] != values['empty'] && values['name'] != values['empty'] && values['vm'] != values['empty']
        eval"[detach_file_from_#{values['vm']}_vm(values)]"
      else
        verbose_output(values, "Warning:\tClient name or virtualisation platform not specified")
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
          verbose_output(values, "Warning:\tClient name not specified")
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
          verbose_output(values, "Warning:\tClient name not specified")
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
          verbose_output(values, "Warning:\tClient name not specified")
        end
      end
    else
      verbose_output(values, "Warning:\tAction #{values['method']}")
    end
  end
  return values
end

# Handle VM action

def handle_vm_action(values)
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
        verbose_output(values, "Information:\tVirtualisation method not specified, setting virtualisation method to VMware")
        values['vm'] = "vm"
      end
      if values['server'] == values['empty'] || values['ip'] == values['empty']
        verbose_output(values, "Warning:\tRemote server hostname or IP not specified")
        quit(values)
      end
    end
  end
  return values
end

# Handle packer import action

def handle_packer_import_action(values)
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
        verbose_output(values, "Warning:\tNo install file, type or service specified")
        quit(values)
      end
    end
  end
  return values
end

# Handle list action

def handle_list_action(values)
  if values['action'].to_s.match(/list|info/)
    if values['file'] && !values['file'] == values['empty']
      describe_file(values)
      quit(values)
    else
      if values['vm'] == values['empty'] && values['service'] == values['empty'] && values['method'] == values['empty'] && values['type'] == values['empty'] && values['mode'] == values['empty']
        verbose_output(values, "Warning:\tNo type or service specified")
      end
    end
  end
  return values
end

# Handle deploy action

def handle_deploy_action(values)
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
          verbose_output(values, "Warning:\tNo deployment image file specified")
          quit(values)
        end
        check_password(values)
        check_password(values)
      end
    end
  end
  return values
end
