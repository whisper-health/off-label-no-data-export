# off-label-no-data-export

Denies member-initiated data exports on the Off-Label forum. Staff are exempt.

## Why a plugin

**Discourse has no site setting for this.** Verified against core `2026.7.0`,
not documentation:

- `frontend/discourse/app/controllers/preferences/account.js` — `canDownloadPosts`
  is `this.user?.viewingSelf`. The "Download all" button consults no setting.
- `lib/guardian.rb` — `can_export_entity?` lets any signed-in user export their
  own `user_archive`.
- `max_export_file_size_kb` and `export_authorized_extensions` are the only
  export-related settings that exist. Both shape the file that gets produced;
  neither gates whether it can be requested.

So the deny has to be a guardian override. Prepending rather than reopening
keeps core's method intact underneath and keeps this working across upgrades.

## Two halves, both required

| Half | Where | Does |
|---|---|---|
| Enforcing | this plugin | `POST /export_csv/export_entity` returns 403 |
| Visible | `theme/common/common.scss` (`.pref-data-export`) | removes the button |

The button is not conditioned on anything the server says, so the plugin alone
leaves members a button that errors, and the CSS alone leaves the endpoint open
to anyone who knows the URL.

## Editing plugin.rb — read this first

**No bare `#` line may appear above the first line of code.** It will take the
whole site down on the next rebuild, and the error names `rake db:migrate`
rather than this file.

`Plugin::Metadata.parse` (`lib/plugin/metadata.rb`) reads every line from the
top of `plugin.rb` and stops only at the first non-empty line that is not a
comment — blank lines do **not** stop it. For a bare `#`, `line[1..-1]` is `""`,
`"".split(":")` is `[]`, so `attribute` is `nil` and `attribute.strip` raises
`NoMethodError`. That aborts `rake db:migrate`, which fails the container
bootstrap. Separate paragraphs with blank lines instead.

Cheap check before pushing, against a Discourse checkout:

```ruby
require "./lib/plugin/metadata"
Plugin::Metadata.parse(File.read("path/to/plugin.rb"))
```

## Repository

This is a subtree mirror. **Source of truth is
`discourse/plugins/off-label-no-data-export/` in the `off-label` monorepo** —
edit there, not here. Public so the container can clone it without credentials;
it holds no secrets. Deploy notes are in the monorepo's `discourse/README.md`.
