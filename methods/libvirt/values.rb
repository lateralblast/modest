# Handle libvirt/KVM values

def handle_libvirt_values(values)
  if values['pool'] == values['empty']
    if not values['hostname'] == values['empty']
      values['pool'] = values['hostname']
    end
  end
  return values
end