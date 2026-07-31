# frozen_string_literal: true

RSpec.describe UserSerializer do
  fab!(:member, :user)
  fab!(:admin)

  before do
    member.user_profile.update!(bio_raw: "A short member bio", website: "https://example.com")
    member.user_stat.update!(
      days_visited: 12,
      posts_read_count: 16,
      topics_entered: 6,
      time_read: 1.hour.to_i,
    )
  end

  def serialized_user(viewer)
    UserSerializer.new(member, scope: Guardian.new(viewer), root: false).as_json
  end

  def serialized_summary(viewer)
    summary = UserSummary.new(member, Guardian.new(viewer))
    UserSummarySerializer.new(summary, scope: Guardian.new(viewer), root: false).as_json
  end

  it "keeps identity and contact fields for members" do
    json = serialized_user(member)

    expect(json).to include(:id, :username, :name, :avatar_template)
    expect(json[:bio_raw]).to eq("A short member bio")
    expect(json[:website]).to eq("https://example.com")
  end

  it "omits profile and behavioral metadata even when viewing yourself" do
    json = serialized_user(member)

    expect(json).not_to include(
      :created_at,
      :last_posted_at,
      :last_seen_at,
      :profile_view_count,
      :trust_level,
      :groups,
      :time_read,
      :recent_time_read,
    )
  end

  it "returns no summary metrics or relationship lists to members" do
    json = serialized_summary(member)

    expect(json[:can_see_summary_stats]).to eq(false)
    expect(json[:can_see_user_actions]).to eq(false)
    expect(json).to include(
      topic_ids: [],
      replies: [],
      links: [],
      most_liked_by_users: [],
      most_liked_users: [],
      most_replied_to_users: [],
      badges: [],
      top_categories: [],
    )
    expect(json).not_to include(
      :days_visited,
      :posts_read_count,
      :topics_entered,
      :time_read,
      :likes_given,
      :likes_received,
    )
  end

  it "turns the LinkedIn public field into the card website link" do
    linkedin = Fabricate(:user_field, name: "LinkedIn", show_on_user_card: true)
    specialty = Fabricate(:user_field, name: "Specialty", show_on_user_card: true)
    UserCustomField.create!(
      user: member,
      name: "#{User::USER_FIELD_PREFIX}#{linkedin.id}",
      value: "linkedin.com/in/member",
    )
    UserCustomField.create!(
      user: member,
      name: "#{User::USER_FIELD_PREFIX}#{specialty.id}",
      value: "Cardiology",
    )

    json = serialized_user(member)

    expect(json[:website]).to eq("https://linkedin.com/in/member")
    expect(json[:website_name]).to eq("linkedin.com/in/member")
    expect(json[:user_fields]).to eq(linkedin.id.to_s => "linkedin.com/in/member")
  end

  it "preserves profile data for staff moderation" do
    user_json = serialized_user(admin)
    summary_json = serialized_summary(admin)

    expect(user_json).to include(:created_at, :profile_view_count, :trust_level)
    expect(summary_json[:can_see_summary_stats]).to eq(true)
    expect(summary_json).to include(:days_visited, :posts_read_count, :time_read)
  end
end
