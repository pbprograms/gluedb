require 'rails_helper'

describe PremiumCredit do

  let(:policy) { build(:policy) }
  let(:premium_credit1) { PremiumCredit.new(aptc_in_cents: '270.50', start_on: '1/1/2014', end_on: '4/30/2014') }
  let(:premium_credit2) { PremiumCredit.new(aptc_in_cents: '325.00', start_on: '5/1/2014', end_on: '12/31/2014') }

  context 'policy' do
    before do
      policy.premium_credits << premium_credit1
      policy.premium_credits << premium_credit2
      policy.save!
    end

    it 'should return preimum credits' do 
      expect(policy.premium_credits.count).to eq(2)
      expect(policy.premium_credits.first).to eq premium_credit1
      expect(policy.premium_credits.last).to eq premium_credit2
    end
  end
end