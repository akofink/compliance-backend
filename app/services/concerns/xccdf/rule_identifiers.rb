# frozen_string_literal: true

module Xccdf
  # Methods related to parsing rules
  module RuleIdentifiers
    extend ActiveSupport::Concern

    def save_rule_identifier(rule: Rule.new,
                             op_rule_identifier:
                             OpenscapParser::RuleIdentifier.new)
      RuleIdentifier.find_or_create_by(
        label: op_rule_identifier.label,
        system: op_rule_identifier.system,
        rule: rule
      )
    end
  end
end
