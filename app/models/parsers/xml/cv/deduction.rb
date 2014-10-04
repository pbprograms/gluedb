module Parsers::Xml::Cv
  class Deduction
    include NodeUtils

    def initialize(parser)
      @parser = parser
    end

    def dollar_amount
      @parser.at_xpath('./ns1:amount', NAMESPACES).text.to_f.round(2)
    end

    def type_urn
      @parser.at_xpath('./ns1:type', NAMESPACES).text
    end

    def type
      type_urn.split('#').last.parameterize("_").gsub("-", "_")
    end
=begin
alimony paid
certain business expenses of reservists, performing artists, and fee-basis government officials
deductible part of self-employment tax
domestic production activities deduction
educator expenses
health savings account deduction
moving expenses
penalty on early withdrawal of savings
rent or royalties
self-employed health insurance deduction
self-employed sep, simple, and qualified plans
=end

    def frequency_urn
      @parser.at_xpath('./ns1:frequency', NAMESPACES).text
    end

    def frequency
      frequency_urn.split('#').last
    end
=begin
Frequencies to map:
bi-weekly
half yearly
monthly
quarterly
weekly
yearly
=end

    def start_date
      first_date('./ns1:start_date')
    end

    def end_date
      first_date('./ns1:end_date')
    end

    def submitted_date
      first_date('./ns1:submitted_date')
    end

    def amount_in_cents
      (dollar_amount * 100).to_i
    end

    def empty?
      [type_urn,start_date,frequency_urn].any?(&:blank?)
    end

    def to_request
      {
        :kind => type,
        :frequency => frequency,
        :start_date => start_date,
        :end_date => end_date,
        :submitted_date => submitted_date,
        :amount_in_cents => amount_in_cents
      }
    end
  end
end
