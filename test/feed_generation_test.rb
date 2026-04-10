#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "pathname"

class FeedGenerationTest < Minitest::Test
  ROOT = Pathname.new(__dir__).join("..").expand_path
  DOCS = ROOT.join("docs")
  PAGES_WORKFLOW = ROOT.join(".github/workflows/pages.yml")

  def test_docs_config_enables_jekyll_feed
    config = DOCS.join("_config.yml").read

    assert_match(/^plugins:\n\s*-\s*jekyll-feed$/m, config)
    assert_match(/^feed:\n\s*path:\s*feed\.xml$/m, config)
  end

  def test_layout_and_pages_workflow_publish_and_validate_feed
    layout = DOCS.join("_layouts/default.html").read
    workflow = PAGES_WORKFLOW.read

    assert_includes layout, "{% feed_meta %}"
    assert_includes workflow, "Validate feed output"
    assert_includes workflow, "test -f _site/feed.xml"
    assert_includes workflow, "grep -q \"application/atom+xml\" _site/index.html"
  end
end
