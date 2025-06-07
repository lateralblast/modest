# frozen_string_literal: true

# Actions

# Handle action switch

def handle_action(values)
  if values['action'] != values['empty']
    case values['action']
    when /convert/
      convert_kvm_image(values) if values['vm'].to_s.match(/kvm|qemu/)
    when /check/
      check_dnsmasq(values) if values['check'].to_s.match(/dnsmasq/)
      check_kvm_permissions(values) if values['vm'].to_s.match(/kvm/)
      check_kvm_network_bridge(values) if values['type'].to_s.match(/bridge/) && values['vm'].to_s.match(/kvm/)
      values = check_local_config(values) if values['mode'].to_s.match(/server/)
      if values['mode'].to_s.match(/osx/)
        check_osx_dnsmasq(values)
        check_osx_tftpd(values)
        check_osx_dhcpd(values)
      end
      check_vm_network(values) if values['vm'].to_s.match(/fusion|vbox|kvm/)
      check_dhcpd_config(values) if values['check'].to_s.match(/dhcp/)
      check_tftpd_config(values) if values['check'].to_s.match(/tftp/)
    when /execute|shell/
      execute_docker_command(values) if values['type'].to_s.match(/docker/) || values['vm'].to_s.match(/docker/)
      execute_multipass_command(values) if values['vm'].to_s.match(/mp|multipass/)
    when /screen/
      get_vm_screen(values) if values['vm'] != values['empty']
    when /vnc/
      vnc_to_vm(values) if values['vm'] != values['empty']
    when /status/
      get_vm_status(values) if values['vm'] != values['empty']
    when /set|put/
      set_aws_s3_bucket_acl(values) if values['type'].to_s.match(/acl/) && (values['bucket'] != values['empty'])
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
        elsif values['type'].to_s.match(/url/) || values['action'].to_s.match(/url/)
          show_s3_bucket_url(values)
        else
          get_aws_billing(values)
        end
      elsif values['name'] != values['empty']
        if values['vm'] != values['empty']
          show_vm_config(values)
        else
          get_client_config(values)
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
      show_vm_config(values) if values['vm'] != values['empty']
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
      describe_file(values) if values['file'] != values['empty']
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
          values['mode'] = 'client'
          check_local_config(values)
          list_clients(values) if (values['service'] != values['empty']) && values['service'].to_s.match(/[a-z]/)
          if (values['vm'] != values['empty']) && values['vm'].to_s.match(/[a-z]/) && (values['type'] == values['empty'])
            if values['file'] != values['empty']
              describe_file(values)
            else
              list_vms(values)
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
        warning_message(values, 'No service of client name specified')
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
              warning_message(values, 'No VM, client or service specified')
              verbose_message(values, 'Available services')
              list_all_services(values)
            end
          end
        elsif values['vm'].to_s.match(/fusion|vbox|parallels|aws|kvm/)
          if values['type'].to_s.match(/packer|ansible/)
            unconfigure_client(values)
          elsif values['type'].to_s.match(/snapshot/)
            if values['name'] != values['empty'] && values['snapshot'] != values['empty']
              delete_vm_snapshot(values)
            else
              warning_message(values, 'Client name or snapshot not specified')
            end
          else
            delete_vm(values)
          end
        elsif values['vm'].to_s.match(/ldom|gdom/)
          unconfigure_gdom(values)
        elsif values['vm'].to_s.match(/mp|multipass/)
          delete_multipass_vm(values)
          return values
        else
          remove_hosts_entry(values)
          remove_dhcp_client(values)
          delete_client_dir(values) if values['yes'] == true
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
            elsif values['snapshot'] == values['empty']
              warning_message(values, 'No snapshot name specified')
              if values['name'] == values['empty']
                warning_message(values, 'No client name specified')
                list_all_vm_snapshots(values)
              else
                list_vm_snapshots(values)
              end
            elsif values['name'] == values['empty'] && values['snapshot'] == values['empty']
              warning_message(values, 'No client or snapshot name specified')
              return values
            else
              delete_vm_snapshot(values)
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
                ports = [port]
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
              warning_message(values, "No #{values['vm']} type, instance or image specified")
            end
          end
          return values
        end
        if values['type'].to_s.match(/packer|docker/)
          unconfigure_client(values)
        elsif values['service'] != values['empty']
          if values['method'] == values['empty']
          end
          unconfigure_server(values)
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
        warning_message(values, 'No service type or VM specified')
        return values
      end
      if values['type'].to_s.match(/service/) && !values['service'].to_s.match(/[a-z]/) && !values['service'] == values['empty']
        warning_message(values, 'No service name specified')
        return values
      end
      values['mode'] = 'client' if values['file'] == values['empty']
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
              ports = [port]
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
            warning_message(values, 'No Key Pair or Security Group specified')
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
      warning_message(values, 'No VM, Method or specified') if values['vm'] == values['empty'] && values['method'] == values['empty'] && values['type'] == values['empty'] && !values['mode'].to_s.match(/server/)
      if values['mode'].to_s.match(/server/) || values['type'].to_s.match(/service/) && values['file'] != values['empty'] && values['vm'] == values['empty'] && !values['type'].to_s.match(/packer/) && !values['service'].to_s.match(/packer/)
        values['mode'] = 'server'
        values = check_local_config(values)
        configure_docker_server(values) if values['host-os'].to_s.match(/Docker/)
        values['method'] = get_method_from_service(values) if (values['method'] == 'none') && (values['service'] != 'none')
        configure_server(values)
      else
        check_vm_network(values) if values['vm'].to_s.match(/fusion|vbox|kvm|mp|multipass/)
        if values['name'] != values['empty']
          if values['service'] != values['empty'] || values['type'].to_s.match(/packer/)
            values['method'] = get_install_method(values) if values['method'] == values['empty']
            check_dhcpd_config(values) if !values['type'].to_s.match(/packer/) && values['vm'] == values['empty']
            if !values['vmnetwork'].to_s.match(/nat/) && !values['action'].to_s.match(/add/)
              check_install_ip(values) unless values['type'].to_s.match(/pxe/)
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
            elsif values['vm'] == values['empty']
              if values['method'] == values['empty']
                if values['ip'].to_s.match(/[0-9]/)
                  values['mode'] = 'client'
                  values = check_local_config(values)
                  add_hosts_entry(values)
                end
                if values['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
                  values['service'] = ''
                  add_dhcp_client(values)
                end
              else
                if values['model'] == values['empty']
                  values['model'] = 'vmware'
                  values['slice'] = '4192'
                end
                values['mode'] = 'server'
                values = check_local_config(values)
                values['mac'] = generate_mac_address(values) unless values['mac'].to_s.match(/[0-9]/)
                configure_client(values)
              end
            else
              create_vm(values) if values['vm'].to_s.match(/fusion|vbox|parallels/) && !values['action'].to_s.match(/add/)
              eval "[configure_#{values['vm']}(values)]" if values['vm'].to_s.match(/zone|lxc|gdom/)
              configure_cdom(values) if values['vm'].to_s.match(/cdom/)
            end
          else
            create_vm(values) if values['vm'].to_s.match(/fusion|vbox|parallels/)
            eval "[configure_#{values['vm']}(values)]" if values['vm'].to_s.match(/zone|lxc|gdom/)
            configure_cdom(values) if values['vm'].to_s.match(/cdom/)
            if values['vm'] == values['empty']
              if values['ip'].to_s.match(/[0-9]/)
                values['mode'] = 'client'
                values = check_local_config(values)
                add_hosts_entry(values)
              end
              if values['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
                values['service'] = ''
                add_dhcp_client(values)
              end
            end
          end
        elsif values['mode'].to_s.match(/server/)
          if values['method'].to_s.match(/ai/)
            configure_ai_server(values)
          else
            warning_message(values, 'No install method specified')
          end
        else
          warning_message(values, 'Client or service name not specified')
        end
      end
    when /^boot$|^stop$|^halt$|^shutdown$|^suspend$|^resume$|^start$|^destroy$/
      values['mode']   = 'client'
      values['action'] = values['action'].gsub(/start/, 'boot')
      values['action'] = values['action'].gsub(/halt/, 'stop')
      values['action'] = values['action'].gsub(/shutdown/, 'stop')
      if values['vm'].to_s.match(/aws/)
        values = boot_aws_vm(values)
        return values
      end
      if values['name'] != values['empty'] && values['vm'] != values['empty'] && values['vm'] != values['empty']
        eval "[#{values['action']}_#{values['vm']}_vm(values)]"
      elsif values['name'] != values['empty'] && values['vm'] == values['empty']
        values['vm'] = get_client_vm_type(values)
        values = check_local_config(values)
        values['sudo'] = false if values['vm'].to_s.match(/vbox|fusion|parallels/)
        control_vm(values) if values['vm'] != values['empty']
      elsif values['name'] != values['empty']
        values['valid-vm'].each do |vm_type|
          values['vm'] = vm_type
          exists = check_vm_exists(values)
          control_vm(values) if exists == 'yes'
        end
      elsif values['name'] == values['empty']
        warning_message(values, 'Client name not specified')
      end
    when /restart|reboot/
      if values['service'] != values['empty']
        eval "[restart_#{values['service']}]"
      else
        values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty'] && values['name'] != values['empty']
        if values['vm'].to_s.match(/aws/)
          values = reboot_aws_vm(values)
          return values
        end
        if values['vm'] != values['empty']
          if values['name'] != values['empty']
            stop_vm(values)
            boot_vm(values)
          else
            warning_message(values, 'Client name not specified')
          end
        elsif values['name'] != values['empty']
          values['valid-vm'].each do |vm_type|
            values['vm'] = vm_type
            exists = check_vm_exists(values)
            next unless exists == 'yes'

            stop_vm(values)
            boot_vm(values)
            return values
          end
        else
          warning_message(values, 'Install service or VM type not specified')
        end
      end
    when /import/
      if values['file'] == values['empty']
        import_packer_vm(values) if values['type'].to_s.match(/packer/)
      elsif values['vm'].to_s.match(/fusion|vbox|kvm/)
        if values['file'].to_s.match(/ova/)
          set_ovfbin unless values['vm'].to_s.match(/kvm/)
          import_ova(values)
        elsif values['file'].to_s.match(/vmdk/)
          import_vmdk(values)
        end
      end
    when /export/
      eval "[export_#{values['vm']}_ova(values)]" if values['vm'].to_s.match(/fusion|vbox/)
      export_aws_image(values) if values['vm'].to_s.match(/aws/)
    when /clone|copy/
      if values['clone'] != values['empty'] && values['name'] != values['empty']
        eval "[clone_#{values['vm']}_vm(values)]"
      else
        warning_message(values, 'Client name or clone name not specified')
      end
    when /running|stopped|suspended|paused/
      eval "[list_#{values['action']}_#{values['vm']}_vms]" if values['vm'] != values['empty'] && values['vm'] != values['empty']
    when /post/
      eval "[execute_#{values['vm']}_post(values)]"
    when /change|modify/
      if values['name'] != values['empty']
        eval "[change_#{values['vm']}_vm_mem(values)]" if values['memory'].to_s.match(/[0-9]/)
        eval "[change_#{values['vm']}_vm_mac(values)]" if values['mac'].to_s.match(/[0-9]|[a-f]|[A-F]/)
      else
        warning_message(values, 'Client name not specified')
      end
    when /attach/
      eval "[attach_file_to_#{values['vm']}_vm(values)]" if values['vm'] != values['empty'] && values['vm'] != values['empty']
    when /detach/
      if values['vm'] != values['empty'] && values['name'] != values['empty'] && values['vm'] != values['empty']
        eval "[detach_file_from_#{values['vm']}_vm(values)]"
      else
        warning_message(values, 'Client name or virtualisation platform not specified')
      end
    when /share/
      eval "[add_shared_folder_to_#{values['vm']}_vm(values)]" if values['vm'] != values['empty'] && values['vm'] != values['empty']
    when /^snapshot|clone/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        if values['name'] != values['empty']
          eval "[snapshot_#{values['vm']}_vm(values)]"
        else
          warning_message(values, 'Client name not specified')
        end
      end
    when /migrate/
      eval "[migrate_#{values['vm']}_vm(values)]"
    when /deploy/
      if values['type'].to_s.match(/vcsa/)
        set_ovfbin
        values['file'] = handle_vcsa_ova(values)
        deploy_vcsa_vm(values)
      else
        eval "[deploy_#{values['vm']}_vm(values)]"
      end
    when /restore|revert/
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        if values['name'] != values['empty']
          eval "[restore_#{values['vm']}_vm_snapshot(values)]"
        else
          warning_message(values, 'Client name not specified')
        end
      end
    when /set/
      eval "[set_#{values['vm']}_value(values)]" if values['vm'] != values['empty']
    when /get/
      eval "[get_#{values['vm']}_value(values)]" if values['vm'] != values['empty']
    when /console|serial|connect|ssh/
      connect_to_kvm_vm(values) if values['vm'].to_s.match(/kvm/)
      if values['vm'].to_s.match(/mp|multipass/)
        connect_to_multipass_vm(values)
        return values
      end
      if values['vm'].to_s.match(/aws/) || values['id'].to_s.match(/[0-9]/)
        connect_to_aws_vm(values)
        return values
      end
      connect_to_docker_client(values) if values['type'].to_s.match(/docker/)
      if values['vm'] != values['empty'] && values['vm'] != values['empty']
        if values['name'] != values['empty']
          connect_to_virtual_serial(values)
        else
          warning_message(values, 'Client name not specified')
        end
      end
    else
      warning_message(values, "Action #{values['method']}")
    end
  end
  values
end

# Handle VM action

def handle_vm_action(values)
  if values['action'] != values['empty']
    if values['action'].to_s.match(/delete/) && values['service'] == values['empty']
      if values['vm'] == values['empty'] && values['type'] != values['empty']
        values['vm'] = get_client_vm_type_from_packer(values)
      elsif values['type'] != values['empty'] && values['vm'] == values['empty']
        values['vm'] = get_client_vm_type_from_packer(values) if values['type'].to_s.match(/packer/) && (values['name'] != values['empty'])
      end
    end
    if values['action'].to_s.match(/migrate|deploy/)
      if values['action'].to_s.match(/deploy/)
        if values['type'].to_s.match(/vcsa/)
          values['vm'] = 'fusion'
        else
          values['type'] = get_install_type_from_file(values)
          values['vm'] = 'fusion' if values['type'].to_s.match(/vcsa/)
        end
      end
      if values['vm'] == values['empty']
        information_message(values, 'Virtualisation method not specified, setting virtualisation method to VMware')
        values['vm'] = 'vm'
      end
      if values['server'] == values['empty'] || values['ip'] == values['empty']
        warning_message(values, 'Remote server hostname or IP not specified')
        quit(values)
      end
    end
  end
  values
end

# Handle packer import action

def handle_packer_import_action(values)
  if values['action'].to_s.match(/import/) && values['file'] == values['empty'] && values['service'] == values['empty'] && !values['type'].to_s.match(/packer/)
    vm_types = %w[fusion vbox]
    exists    = []
    vm_exists = ''
    vm_types.each do |vm_type|
      exists = check_packer_vm_image_exists(values, vm_type)
      next unless exists[0].to_s.match(/yes/)

      values['type'] = 'packer'
      values['vm']   = vm_type
      vm_exists      = 'yes'
    end
    unless vm_exists.match(/yes/)
      warning_message(values, 'No install file, type or service specified')
      quit(values)
    end
  end
  values
end

# Handle list action

def handle_list_action(values)
  if values['action'].to_s.match(/list|info/)
    if values['file'] && !values['file'] == values['empty']
      describe_file(values)
      quit(values)
    elsif values['vm'] == values['empty'] && values['service'] == values['empty'] && values['method'] == values['empty'] && values['type'] == values['empty'] && values['mode'] == values['empty']
      warning_message(values, 'No type or service specified')
    end
  end
  values
end

# Handle deploy action

def handle_deploy_action(values)
  if values['action'].to_s.match(/deploy/)
    values['type'] = 'esx' if values['type'] == values['empty']
    if values['type'].to_s.match(/esx|vcsa/)
      values['serverpassword'] = values['rootpassword'] if values['serverpassword'] == values['empty']
      check_ovftool_exists(values)
      if values['type'].to_s.match(/vcsa/)
        if values['file'] == values['empty']
          warning_message(values, 'No deployment image file specified')
          quit(values)
        end
        check_password(values)
        check_password(values)
      end
    end
  end
  values
end
