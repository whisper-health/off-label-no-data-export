# frozen_string_literal: true

# name: off-label-no-data-export
# about: Denies member-initiated data exports. Staff exports are untouched.
# version: 0.1
# authors: Off-Label
# url: https://github.com/whisper-health/off-label-no-data-export

# Discourse has no site setting for this. As of core 2026.7.0 the "Download all"
# button in preferences renders for anyone viewing their own account
# (frontend/discourse/app/controllers/preferences/account.js — `canDownloadPosts`
# is just `user.viewingSelf`), and Guardian#can_export_entity? lets any signed-in
# user export their own `user_archive`. `max_export_file_size_kb` and
# `export_authorized_extensions` shape the file that gets produced; neither one
# gates whether it can be requested.
#
# So the deny has to be a guardian override. Prepending rather than reopening
# keeps core's method intact underneath and keeps this working across upgrades.
#
# The theme hides the button (`.pref-data-export`, theme/common/common.scss).
# That is the visible half and this is the enforcing half — the button is not
# conditioned on anything the server says, so without this the endpoint still
# answers to anyone who knows the URL, and without the CSS members get a button
# that errors.
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
