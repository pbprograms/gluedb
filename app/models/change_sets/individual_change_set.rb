module ChangeSets
  class IndividualChangeSet
    attr_reader :resource, :record

    def initialize(remote_resource)
      @resource = remote_resource
      @individual_exists = remote_resource.exists?
      if @individual_exists
        @record = remote_resource.record
      end
    end

    def member
      @member ||= record.members.detect { |m| m.hbx_member_id == resource.hbx_member_id }
    end

    def individual_exists?
      @individual_exists
    end

    def create_individual_resource
      new_person = build_new_person
      @record = new_person
      new_person.save
    end

    def full_error_messages
      record.errors.full_messages
    end

    def member_active_policies
      all_policies = member.policies
      non_canceled_policies = all_policies.reject(&:canceled?)
      non_canceled_policies.select do |pol|
        pol.currently_active_for?(member.hbx_member_id) ||
          pol.future_active_for?(member.hbx_member_id)
      end
    end

    def now_or_future_active_policies
      @now_or_future_active_polices ||= member_active_policies
    end

    def transmission_policies
      @transmission_policies ||= determine_policies_to_transmit
    end

    def process_first_edi_change
      if home_address_changed?
        process_home_address_change
      elsif mailing_address_changed?
        process_mailing_address_change
      elsif home_email_changed?
        process_home_email_change
      elsif work_email_changed?
        process_work_email_change
      elsif home_phone_changed?
        process_home_phone_change
      elsif work_phone_changed?
        process_work_phone_change
      elsif names_changed?
        process_name_change
      elsif ssn_changed?
        process_ssn_change
      elsif gender_changed?
        process_gender_change
      end
    end

    def process_home_address_change
      cs = ::ChangeSets::PersonAddressChangeSet.new("home")
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def process_mailing_address_change
      cs = ::ChangeSets::PersonAddressChangeSet.new("mailing")
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def process_name_change
      cs = ::ChangeSets::PersonNameChangeSet.new
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def process_ssn_change
      cs = ::ChangeSets::PersonSsnChangeSet.new
      cs.perform_update(member, resource, determine_policies_to_transmit)
    end

    def process_gender_change
      cs = ::ChangeSets::PersonGenderChangeSet.new
      cs.perform_update(member, resource, determine_policies_to_transmit)
    end

    def process_home_email_change
      cs = ::ChangeSets::PersonEmailChangeSet.new("home")
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def process_work_email_change
      cs = ::ChangeSets::PersonEmailChangeSet.new("work")
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def process_home_phone_change
      cs = ::ChangeSets::PersonPhoneChangeSet.new("home")
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def process_work_phone_change
      cs = ::ChangeSets::PersonPhoneChangeSet.new("work")
      cs.perform_update(record, resource, determine_policies_to_transmit)
    end

    def any_changes?
      change_count > 0
    end

    def multiple_changes?
      change_count > 1
    end

    def change_count
      @change_count ||= (change_collection.count { |a| a })
    end

    def change_collection
      [
        home_address_changed?,
        mailing_address_changed?,
        names_changed?,
        ssn_changed?,
        gender_changed?,
        home_email_changed?,
        work_email_changed?,
        home_phone_changed?,
        work_phone_changed?,
        dob_changed?
      ]
    end

    def dob_changed?
      resource.dob != member.dob
    end

    def home_phone_changed?
      phone_has_changed?("home")
    end

    def work_phone_changed?
      phone_has_changed?("work")
    end

    def home_email_changed?
      email_has_changed?("home")
    end

    def work_email_changed?
      email_has_changed?("work")
    end

    def home_address_changed?
      resource_address = resource.addresses.detect { |adr| adr.address_kind == "home" }
      record_address = record.addresses.detect { |adr| adr.address_type == "home" }
      # Don't wipe home addresses
      return false if (resource_address.nil? && (!record_address.nil?))
      address_has_changed?("home")
    end

    def mailing_address_changed?
      address_has_changed?("mailing")
    end

    def names_changed?
      (resource.name_first != record.name_first) ||
        (resource.name_last != record.name_last) ||
        (resource.name_middle != record.name_middle) ||
        (resource.name_pfx != record.name_pfx) ||
        (resource.name_sfx != record.name_sfx)
    end

    def ssn_changed?
      return false if (resource.ssn.blank? && member.ssn.blank?)
      resource.ssn != member.ssn
    end

    def gender_changed?
      resource.gender != member.gender
    end

    protected

    def determine_policies_to_transmit
      selected_policies = now_or_future_active_policies.inject({}) do |acc, pol|
        carrier_id = pol.plan.carrier_id
        individual_market = pol.employer_id.blank? 
        lookup_key = [carrier_id, individual_market]
        if acc.has_key?(lookup_key)
          if acc[lookup_key].policy_start <= pol.policy_start
            acc[lookup_key] = pol
          end
        else
          acc[lookup_key] = pol
        end
        acc
      end
      selected_policies.values
    end

    def items_changed?(resource_item, record_item)
      return false if (resource_item.nil? && record_item.nil?)
      return true if record_item.nil?
      !record_item.match(resource_item)
    end

    def phone_has_changed?(phone_kind)
      resource_address = resource.phones.detect { |adr| adr.phone_type == phone_kind }
      record_address = record.phones.detect { |adr| adr.phone_type == phone_kind }
      items_changed?(resource_address, record_address)
    end

    def email_has_changed?(email_kind)
      resource_address = resource.emails.detect { |adr| adr.email_type == email_kind }
      record_address = record.emails.detect { |adr| adr.email_type == email_kind }
      items_changed?(resource_address, record_address)
    end

    def address_has_changed?(addy_kind)
      resource_address = resource.addresses.detect { |adr| adr.address_type == addy_kind }
      record_address = record.addresses.detect { |adr| adr.address_type == addy_kind }
      items_changed?(resource_address, record_address)
    end

    def build_new_person
      person_properties = resource.to_hash
      person_properties[:members] = [Member.new(resource.member_hash)]
      person_properties[:addresses] = resource.addresses.map { |addy| Address.new(addy.to_hash) }
      person_properties[:emails] = resource.emails.map { |addy| Email.new(addy.to_hash) }
      person_properties[:phones] = resource.phones.map { |addy| Phone.new(addy.to_hash) }
      Person.new(person_properties)
    end
  end
end
