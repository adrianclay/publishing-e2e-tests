module ContentTaggerHelpers
  def create_draft_taxon(slug:, title:)
    visit(Plek.find("content-tagger") + "/taxons/new")
    fill_in "Path", with: slug
    fill_in "Internal taxon name", with: title
    fill_in "External taxon name", with: title
    fill_in "Description", with: Faker::Lorem.paragraph
    click_button "Create taxon"
  end

  def publish_taxon
    click_link "Publish"
    click_button "Confirm publish"
  end

  def visit_tag_external_content_page(slug:)
    visit(Plek.find("content-tagger") + "/taggings/lookup")
    fill_in "content_lookup_form_base_path", with: "/" + slug
    click_button "Edit page"
  end

  def self.included(base)
    return unless SignonHelpers::use_signon?

    default_permissions = ["GDS Editor"]

    base.before(:each) do |example|
      @user = get_next_user(
        "Content Tagger" =>
        example.metadata.fetch(:permissions, default_permissions),
        "Publisher" =>
        example.metadata.fetch(:permissions, %w[skip_review])
      )
      signin_with_user(@user)
    end
  end
end
