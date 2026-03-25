#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "pathname"

class MarkdownLintTest < Minitest::Test
  ROOT = Pathname.new(__dir__).join("..").expand_path

  def test_print_targets_lists_repo_markdown_inputs
    stdout, stderr, status = Open3.capture3("ruby", "scripts/markdown_lint.rb", "--print-targets", chdir: ROOT.to_s)

    assert status.success?, "expected success, got stderr: #{stderr}"

    targets = stdout.lines.map(&:strip).reject(&:empty?)

    assert_includes targets, "README.md"
    assert_includes targets, "CHANGELOG.md"
    assert_includes targets, "skills/assistant/promptify/SKILL.md"
    assert_includes targets, "skills/design/design-frontend/rules/layout-use-spacing-scale.md"
    assert_includes targets, "skills/assistant/agent-skill-creator/references/workflows.md"
  end
end
