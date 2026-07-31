# frozen_string_literal: true

# name: off-label-minimal-profiles
# about: Limits member-facing profiles to identity and contact information.
# version: 0.1
# authors: Off-Label
# url: https://github.com/whisper-health/off-label-minimal-profiles

after_initialize do
  module ::OffLabelMinimalProfiles
    module StaffOnlySerializerAttributes
      private

      def include_for_staff(attribute)
        return false unless scope&.is_staff?

        include_method = method(:"include_#{attribute}?").super_method
        include_method ? include_method.call : true
      end
    end

    module UserCardSerializerExtension
      include StaffOnlySerializerAttributes

      LINKEDIN_FIELD_NAME = "LinkedIn"

      %i[
        last_posted_at
        last_seen_at
        created_at
        trust_level
        badge_count
        topic_post_count
        time_read
        recent_time_read
        primary_group_id
        primary_group_name
        flair_group_id
        flair_name
        flair_url
        flair_bg_color
        flair_color
        featured_topic
        timezone
        featured_user_badges
      ].each do |attribute|
        define_method(:"include_#{attribute}?") { include_for_staff(attribute) }
      end

      def website
        linkedin_url || super
      end

      def user_fields
        return super if scope&.is_staff?

        linkedin_field = UserField.find_by(name: LINKEDIN_FIELD_NAME)
        return {} if linkedin_field.blank?

        value = object.user_fields([linkedin_field.id])[linkedin_field.id.to_s]
        value.present? ? { linkedin_field.id.to_s => value } : {}
      end

      private

      def linkedin_url
        linkedin_field = UserField.find_by(name: LINKEDIN_FIELD_NAME)
        return if linkedin_field.blank?

        value = object.user_fields([linkedin_field.id])[linkedin_field.id.to_s]
        return if value.blank?

        value.match?(%r{\Ahttps?://}i) ? value : "https://#{value}"
      end
    end

    module UserSerializerExtension
      include StaffOnlySerializerAttributes

      %i[
        profile_view_count
        invited_by
        groups
        group_users
        profile_background_upload_url
      ].each do |attribute|
        define_method(:"include_#{attribute}?") { include_for_staff(attribute) }
      end
    end

    module UserSummarySerializerExtension
      include StaffOnlySerializerAttributes

      MEMBER_ATTRIBUTES = %i[can_see_summary_stats can_see_user_actions].freeze
      EMPTY_MEMBER_COLLECTIONS = %i[
        topics
        replies
        links
        most_liked_by_users
        most_liked_users
        most_replied_to_users
        badges
        top_categories
      ].freeze

      %i[
        likes_given
        likes_received
        topics_entered
        posts_read_count
        days_visited
        topic_count
        post_count
        time_read
        recent_time_read
        bookmark_count
      ].each do |attribute|
        define_method(:"include_#{attribute}?") { include_for_staff(attribute) }
      end

      EMPTY_MEMBER_COLLECTIONS.each do |collection|
        define_method(collection) { scope&.is_staff? ? super() : [] }
        define_method(:"include_#{collection}?") { scope&.is_staff? ? include_for_staff(collection) : true }
      end

      def can_see_summary_stats
        scope&.is_staff?
      end

      def can_see_user_actions
        scope&.is_staff?
      end

      private

      def attributes
        serialized_attributes = super
        return serialized_attributes if scope&.is_staff?

        serialized_attributes.slice(
          *MEMBER_ATTRIBUTES,
          *MEMBER_ATTRIBUTES.map(&:to_s),
        )
      end
    end

    module DirectoryItemSerializerExtension
      MEMBER_HIDDEN_ATTRIBUTES = %i[
        days_visited
        likes_given
        likes_received
        post_count
        posts_read
        posts_read_count
        time_read
        topic_count
        topics_entered
      ].freeze

      private

      def attributes
        serialized_attributes = super
        return serialized_attributes if scope&.is_staff?

        serialized_attributes.except(
          *MEMBER_HIDDEN_ATTRIBUTES,
          *MEMBER_HIDDEN_ATTRIBUTES.map(&:to_s),
        )
      end
    end

    module DirectoryUserSerializerExtension
      include StaffOnlySerializerAttributes

      %i[
        trust_level
        primary_group_name
        flair_name
        flair_url
        flair_bg_color
        flair_color
        flair_group_id
      ].each do |attribute|
        define_method(:"include_#{attribute}?") { include_for_staff(attribute) }
      end
    end

    module GroupUserSerializerExtension
      include StaffOnlySerializerAttributes

      %i[
        last_posted_at
        last_seen_at
        added_at
        timezone
        trust_level
        primary_group_name
        flair_name
        flair_url
        flair_bg_color
        flair_color
        flair_group_id
      ].each do |attribute|
        define_method(:"include_#{attribute}?") { include_for_staff(attribute) }
      end
    end

    module UserGuardianExtension
      def can_see_summary_stats?(target_user)
        is_staff?
      end

      def can_see_user_actions?(user, action_types)
        return super if is_staff?

        false
      end
    end
  end

  UserCardSerializer.prepend(::OffLabelMinimalProfiles::UserCardSerializerExtension)
  UserSerializer.prepend(::OffLabelMinimalProfiles::UserSerializerExtension)
  UserSummarySerializer.prepend(::OffLabelMinimalProfiles::UserSummarySerializerExtension)
  DirectoryItemSerializer.prepend(::OffLabelMinimalProfiles::DirectoryItemSerializerExtension)
  DirectoryItemSerializer::UserSerializer.prepend(
    ::OffLabelMinimalProfiles::DirectoryUserSerializerExtension,
  )
  GroupUserSerializer.prepend(::OffLabelMinimalProfiles::GroupUserSerializerExtension)
  GroupUserWithCustomFieldsSerializer.prepend(
    ::OffLabelMinimalProfiles::GroupUserSerializerExtension,
  )
  Guardian.prepend(::OffLabelMinimalProfiles::UserGuardianExtension)
end
