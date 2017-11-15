feature "Publishing a parent and child topic on Collections Publisher", collections_publisher: true do
  include CollectionsPublisherHelpers

  let(:parent_title) { title_with_timestamp }
  let(:parent_slug) { slug_with_timestamp }
  let(:link) { "/topic/" + parent_slug }

  let(:child_slug) { slug_with_timestamp }
  let(:child_title) { title_with_timestamp }

  scenario "Publishing a parent and child topic" do
    given_i_have_a_published_topic
    when_i_add_a_child_topic
    and_i_publish_it
    then_i_can_view_both_on_gov_uk
  end

  private

  def visit_create_topic
    visit_collections_publisher("/topics/new")
  end

  def given_i_have_a_published_topic
    create_topic
    and_i_publish_it
  end

  def create_topic
    visit_create_topic

    fill_in_topic_form(slug: parent_slug, title: parent_title)
    click_button "Create"
    expect(page).to have_text(parent_title)
  end

  def when_i_add_a_child_topic
    visit_create_topic

    fill_in_topic_form(slug: child_slug, title: child_title, parent: parent_title)
    click_button "Create"
    expect(page).to have_text(child_title)
  end

  def and_i_publish_it
    click_link("Publish topic")
    expect(page).to have_text("published")
  end

  def then_i_can_view_both_on_gov_uk
    url = find_link(link)[:href]
    reload_url_until_status_code(url, 200)

    click_link(link)
    expect_rendering_application("collections")
    expect(page).to have_content(child_title)

    first(:link, parent_title).click
    expect(current_url).to end_with(parent_slug)
  end
end
