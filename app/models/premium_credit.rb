class PremiumCredit
  include Mongoid::Document
  include Mongoid::Timestamps

  field :aptc_in_cents, type: BigDecimal, default: 0.00
  field :start_on, type: Date
  field :end_on, type: Date
  field :is_voided, type: Boolean, default: false
  field :is_corrected, type: Boolean, default: false

  embedded_in :policy

  default_scope  ->{ order(:"start_on".desc) }
  scope :active, ->{ where(:is_voided => false) }

  # Second Lowest Cost Silver Plan
  # field :slcsp_id, type: String

  # def slcsp=(new_slcsp)
  #   raise ArgumentError.new("expected Plan class") unless new_slcsp.is_a? Plan
  #   self.new_slcsp_id = new_slcsp._id
  # end

  # def slcsp
  #   Plan.find(self.new_slcsp_id) unless new_slcsp_id.blank?
  # end

  def is_voided?
    is_voided
  end

  def is_corrected?
    is_corrected
  end
end
