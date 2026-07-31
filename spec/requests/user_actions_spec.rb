# frozen_string_literal: true

RSpec.describe UserActionsController do
  fab!(:member, :user)
  fab!(:other_member, :user)
  fab!(:admin)

  it "does not expose a member activity stream to another member" do
    sign_in(other_member)

    get "/user_actions.json", params: { username: member.username }

    expect(response.status).to eq(404)
  end

  it "keeps a member's own activity stream available" do
    sign_in(member)

    get "/user_actions.json", params: { username: member.username }

    expect(response.status).to eq(200)
  end

  it "preserves staff access to member activity" do
    sign_in(admin)

    get "/user_actions.json", params: { username: member.username }

    expect(response.status).to eq(200)
  end
end
