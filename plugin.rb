# frozen_string_literal: true

# name: off-label-no-data-export
# about: Denies member-initiated data exports. Staff exports are untouched.
# version: 0.1
# authors: Off-Label
# url: https://github.com/whisper-health/off-label-no-data-export

# Rationale and the core-source citations are in README.md. Keep them there.

# Nothing above the first line of code may be a bare "#" with no text after it.
# Plugin::Metadata.parse reads every line from the top of this file and only
# stops at the first non-empty line that is not a comment — blank lines do not
# stop it. On a bare "#", line[1..-1].split(":") is [], so attribute is nil and
# attribute.strip raises (lib/plugin/metadata.rb:50). That aborts rake
# db:migrate and fails the whole container bootstrap. Blank lines are safe;
# bare "#" lines are not.

after_initialize do
  module ::OffLabelNoDataExport
    def can_export_entity?(entity, entity_id = nil, args = nil)
      # Staff keep the ability: exporting a member's archive is how a data
      # request gets answered, and the admin user page relies on it.
      return false if entity == "user_archive" && !is_staff?

      super
    end
  end

  Guardian.prepend(::OffLabelNoDataExport)
end
