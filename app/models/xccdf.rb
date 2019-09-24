# frozen_string_literal: true

Dir[File.join(__dir__, 'xccdf', '*.rb')].each { |f| require f }

# Represents all our models which come directly from the XCCDF XML format for
# SCAP content
module Xccdf
end
