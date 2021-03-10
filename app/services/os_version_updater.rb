# frozen_string_literal: true

# A service class to update OS version for each policy with assigned hosts
class OsVersionUpdater
  class << self
    def run!
      Policy.find_each(&:update_os_versions)
    end
  end
end
