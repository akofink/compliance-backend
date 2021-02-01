# frozen_string_literal: true

# Methods that are related to a profile's policy
module ProfilePolicyAssociation
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_policy_with_internal
    after_destroy :destroy_empty_policy

    belongs_to :policy_object, class_name: :Policy, foreign_key: :policy_id,
                               optional: true, inverse_of: :profiles
    has_many :policy_test_results, through: :policy_object,
                                   source: :test_results
    has_many :policy_test_result_hosts, -> { distinct },
             through: :policy_test_results, source: :host
    delegate :business_objective, :business_objective_id,
             to: :policy_object, allow_nil: true
    validate :no_duplicate_policy_types, on: :create

    def policy_profile
      policy_object&.initial_profile
    end

    def policy_profile_id
      policy_profile&.id
    end

    def no_duplicate_policy_types
      return if canonical? || external

      error_msg = 'must be unique. Another policy with '\
                  'this policy type already exists.'
      profile = Profile.includes(:benchmark).find_by(
        ref_id: ref_id, account: account, external: false,
        benchmarks: { ref_id: benchmark.ref_id }
      )

      errors.add(:policy_type, error_msg) if profile
    end

    def compliance_threshold
      policy_object&.compliance_threshold ||
        Policy::DEFAULT_COMPLIANCE_THRESHOLD
    end

    def destroy_policy_with_internal
      policy_object&.destroy unless external?
    end

    def destroy_empty_policy
      policy_object.destroy if policy_object&.profiles&.empty?
    end
  end
end
