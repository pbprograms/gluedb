module ChangeSets
  class PersonPhoneChangeSet
    attr_reader :address_kind

    include ::ChangeSets::SimpleMaintenanceTransmitter

    def initialize(addy_kind)
      @address_kind = addy_kind
    end

    def perform_update(person, person_update, policies_to_notify)
      new_address = person_update.phones.detect { |au| au.phone_type == address_kind }
      update_result = false
      if new_address.nil?
        person.remove_phone_of(address_kind)
        update_result = person.save
      else
        person.set_phone(Phone.new(new_address.to_hash))
        update_result = person.save
      end
      return false unless update_result
      notify_policies("change", "personnel_data", person_update.hbx_member_id, policies_to_notify)
      true
    end
  end
end
