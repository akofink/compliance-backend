# frozen_string_literal: true

module Xccdf
  # Methods related to saving profiles and finding which hosts
  # they belong to
  module Datastreams
    extend ActiveSupport::Concern

    included do
      def op_datastream_file(datastream_filename)
        OpenscapParser::DatastreamFile.new(File.read(datastream_filename))
      end
    end
  end
end
