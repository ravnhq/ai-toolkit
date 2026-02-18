#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
ACTIVE_SKILL_FILES = Dir.glob(ROOT.join("skills/*/*/SKILL.md").to_s).sort

STOPWORDS = %w[
  the and for with from this that these those use when users say your about into over under
  not any all one two three four five six seven eight nine ten only most more less should
  where what who why how will would could can must have has had into than then also
].freeze

Failure = Struct.new(:suite, :path, :message, keyword_init: true)

def rel(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
end

def parse_skill(path)
  text = File.read(path)
  lines = text.lines
  end_idx = lines[1..]&.find_index { |line| line.strip == "---" }
  frontmatter = end_idx ? (YAML.safe_load(lines[1..end_idx].join, permitted_classes: [], aliases: false) || {}) : {}
  body = end_idx ? (lines[(end_idx + 2)..] || []).join : text
  [frontmatter, body]
end

def extract_user_prompt(block)
  block[/User:\s*["“](.+?)["”]/m, 1]
end

def keyword_set(description)
  description
    .downcase
    .scan(/[a-z][a-z0-9+-]{3,}/)
    .reject { |token| STOPWORDS.include?(token) }
    .uniq
end

failures = []
metrics = {
  trigger_cases: 0,
  trigger_pass: 0,
  functional_cases: 0,
  functional_pass: 0,
  performance_cases: 0,
  performance_pass: 0
}

ACTIVE_SKILL_FILES.each do |path|
  frontmatter, body = parse_skill(path)
  description = frontmatter.fetch("description", "").to_s
  body_lines = body.lines.count
  body_words = body.split(/\s+/).reject(&:empty?).count

  # Trigger suite
  metrics[:trigger_cases] += 1
  positive_block = body[/^###\s+Positive Trigger\b(.*?)(?=^###\s+Non-Trigger\b|^##\s+Troubleshooting\b|\z)/mi, 1].to_s
  negative_block = body[/^###\s+Non-Trigger\b(.*?)(?=^##\s+Troubleshooting\b|\z)/mi, 1].to_s
  positive_prompt = extract_user_prompt(positive_block).to_s
  negative_prompt = extract_user_prompt(negative_block).to_s

  if positive_prompt.empty? || negative_prompt.empty?
    failures << Failure.new(suite: "trigger", path:, message: "Missing positive/non-trigger example user prompts.")
  else
    keywords = keyword_set(description)
    positive_hits = keywords.count { |token| positive_prompt.downcase.include?(token) }
    negative_hits = keywords.count { |token| negative_prompt.downcase.include?(token) }

    if positive_hits.zero?
      failures << Failure.new(suite: "trigger", path:, message: "Positive trigger prompt has zero overlap with description keywords.")
    elsif positive_hits <= negative_hits
      failures << Failure.new(suite: "trigger", path:, message: "Positive trigger is not more aligned than non-trigger prompt.")
    else
      metrics[:trigger_pass] += 1
    end
  end

  # Functional suite
  metrics[:functional_cases] += 1
  has_workflow = body.match?(/^##+\s+Workflow\b/i)
  has_examples = body.match?(/^##+\s+Examples?\b/i)
  has_troubleshooting = body.match?(/^##+\s+Troubleshooting\b/i)
  has_error = body.include?("- Error:")
  has_cause = body.include?("- Cause:")
  has_solution = body.include?("- Solution:")
  has_expected_behavior = body.include?("Expected behavior:")

  if has_workflow && has_examples && has_troubleshooting && has_error && has_cause && has_solution && has_expected_behavior
    metrics[:functional_pass] += 1
  else
    failures << Failure.new(
      suite: "functional",
      path:,
      message: "Missing required structure (Workflow/Examples/Troubleshooting/Error-Cause-Solution/Expected behavior)."
    )
  end

  # Performance suite
  metrics[:performance_cases] += 1
  line_limit_ok = body_lines <= 500
  word_limit_ok = body_words <= 5000
  desc_limit_ok = description.length <= 1024

  if line_limit_ok && word_limit_ok && desc_limit_ok
    metrics[:performance_pass] += 1
  else
    failures << Failure.new(
      suite: "performance",
      path:,
      message: "Exceeds limits: lines=#{body_lines} (<=500), words=#{body_words} (<=5000), description=#{description.length} (<=1024)."
    )
  end
end

puts "Skills tested: #{ACTIVE_SKILL_FILES.count}"
puts "Trigger suite: #{metrics[:trigger_pass]}/#{metrics[:trigger_cases]}"
puts "Functional suite: #{metrics[:functional_pass]}/#{metrics[:functional_cases]}"
puts "Performance suite: #{metrics[:performance_pass]}/#{metrics[:performance_cases]}"

if failures.empty?
  puts "PASS: trigger, functional, and performance suites all passed."
  exit 0
end

failures.each do |failure|
  puts "[FAIL][#{failure.suite}] #{rel(failure.path)}: #{failure.message}"
end

exit 1
