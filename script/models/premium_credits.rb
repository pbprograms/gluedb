module Models
  class PremiumCredits

    def load
      Policy.with_aptc.each do |pol|        
        next if pol.subscriber.nil? || !pol.premium_credits.empty?

        if !pol.premium_credits.empty?
          pol.premium_credits.each {|p| p.destroy }
        end

        attrs = {
          aptc_in_cents: pol.applied_aptc, 
          start_on: pol.subscriber.coverage_start        
        }

        attrs.merge!({end_on: pol.subscriber.coverage_end}) if pol.subscriber.coverage_end
        pol.premium_credits.build(attrs)
        
        pol.save! if pol.valid?
      end
    end
  end
end