# off-label-minimal-profiles

Keeps ordinary member profiles focused on identity and contact rather than
behavioral analytics.

## Policy

Non-staff responses omit:

- account creation, last-posted, and last-seen timestamps
- profile views, trust level, group/flair metadata, badges, and featured topics
- time read, days visited, topics viewed, posts read, and post/topic counts
- likes and the summary page's top topics, replies, links, categories, and
  member-to-member interaction lists
- user activity streams reached through `/user_actions.json`
- the same behavioral statistics when requested through the user directory,
  plus last-seen, trust-level, and group/flair metadata in group member APIs

The rule also applies when a member views their own profile. Staff retain the
data and activity endpoints required for moderation.

Identity and contact information remain available: avatar, display name,
username, title, bio, website, location, configured public user fields, and
message/chat eligibility.

## Why a plugin

The matching theme CSS removes the profile sections from the rendered page, but
CSS does not change JSON responses. Core exposes the same information through
`UserCardSerializer`, `UserSerializer`, `UserSummarySerializer`, and
`UserActionsController`. This plugin changes the serializer inclusion rules and
the guardian checks so a member cannot recover the hidden data by inspecting
network responses or calling those endpoints directly.

Staff are deliberately exempt. This is data minimization for member-facing
profiles, not deletion of moderation records or forum telemetry.

## Local installation

Link this directory into a Discourse checkout:

```bash
ln -s \
  /path/to/off-label/discourse/plugins/off-label-minimal-profiles \
  /path/to/discourse/plugins/off-label-minimal-profiles
```

Restart the Rails server after adding or changing the plugin.

## Production

This directory is the source of truth. Mirror it to
`whisper-health/off-label-minimal-profiles`, add that repository to the
container's plugin clone list, and rebuild the Discourse container.
