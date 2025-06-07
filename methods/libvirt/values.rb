# frozen_string_literal: true

# Handle libvirt/KVM values

def handle_libvirt_values(values)
  values['pool'] = values['hostname'] if (values['pool'] == values['empty']) && (values['hostname'] != values['empty'])
  values
end
