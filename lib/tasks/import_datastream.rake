# frozen_string_literal: true

namespace :ssg do
  desc 'Update compliance DB with the latest release of the SCAP Security Guide'
  task import: [:environment, 'ssg:sync_rhel'] do
    # DATASTREAM_FILENAMES from openscap_parser's ssg:sync
    DatastreamImporter.new(DATASTREAM_FILENAMES.flatten).import!
  end
end
