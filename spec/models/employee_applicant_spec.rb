require "spec_helper"

describe EmployeeApplicant do

  let(:e0) {Employer.create!(b_type: "broker", npn: "987432010", name_last: "popeye")}
  
  let(:p0) {Person.create!(name_first: "Dan", name_last: "Aurbach")}
  let(:p1) {Person.create!(name_first: "Patrick", name_last: "Carney")}
  let(:ag) {ApplicationGroup.create()}

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
    end
  end

end 