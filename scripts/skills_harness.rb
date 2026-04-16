#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "json"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
ALL_SKILL_FILES = Dir.glob(ROOT.join("skills/*/*/SKILL.md").to_s).sort
ACTIVE_SKILL_FILES = ALL_SKILL_FILES.select do |path|
  text = File.read(path)
  lines = text.lines
  end_idx = lines[1..]&.find_index { |line| line.strip == "---" }
  fm = end_idx ? (YAML.safe_load(lines[1..end_idx].join, permitted_classes: [], aliases: false) || {}) : {}
  status = fm.dig("metadata", "status").to_s
  status != "draft" && status != "scaffold"
end

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
  performance_pass: 0,
  diversity_cases: 0,
  diversity_pass: 0
}

DIVERSITY_REQUIRED_KEYS = %w[distinct_skeletons_required min_distinct_ratio recipes_must_cover_any_of min_recipes_covered].freeze

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

  # Structural-diversity suite (only runs for skills that declare an evals.json)
  evals_path = Pathname.new(path).dirname.join("evals/evals.json")
  next unless evals_path.file?

  begin
    evals = JSON.parse(File.read(evals_path))
  rescue JSON::ParserError => e
    failures << Failure.new(suite: "diversity", path: evals_path.to_s, message: "evals.json parse error: #{e.message}")
    next
  end

  eval_entries = evals.is_a?(Hash) ? evals["evals"] : evals
  next unless eval_entries.is_a?(Array)

  eval_entries.each do |entry|
    next unless entry.is_a?(Hash) && entry.key?("structural_diversity_pass_criteria")

    metrics[:diversity_cases] += 1
    criteria = entry["structural_diversity_pass_criteria"]
    missing = DIVERSITY_REQUIRED_KEYS.reject { |k| criteria.key?(k) }
    if !missing.empty?
      failures << Failure.new(
        suite: "diversity",
        path: evals_path.to_s,
        message: "eval #{entry['id']} structural_diversity_pass_criteria missing keys: #{missing.join(', ')}"
      )
      next
    end

    unless criteria["recipes_must_cover_any_of"].is_a?(Array) && !criteria["recipes_must_cover_any_of"].empty?
      failures << Failure.new(
        suite: "diversity",
        path: evals_path.to_s,
        message: "eval #{entry['id']} recipes_must_cover_any_of must be a non-empty array"
      )
      next
    end

    ratio = criteria["min_distinct_ratio"].to_f
    unless ratio > 0.0 && ratio <= 1.0
      failures << Failure.new(
        suite: "diversity",
        path: evals_path.to_s,
        message: "eval #{entry['id']} min_distinct_ratio must be in (0, 1]"
      )
      next
    end

    metrics[:diversity_pass] += 1
  end
end

puts "Skills tested: #{ACTIVE_SKILL_FILES.count}"
puts "Trigger suite: #{metrics[:trigger_pass]}/#{metrics[:trigger_cases]}"
puts "Functional suite: #{metrics[:functional_pass]}/#{metrics[:functional_cases]}"
puts "Performance suite: #{metrics[:performance_pass]}/#{metrics[:performance_cases]}"
if metrics[:diversity_cases].positive?
  puts "Diversity schema suite: #{metrics[:diversity_pass]}/#{metrics[:diversity_cases]}"
end

if failures.empty?
  puts "PASS: all suites passed."
  exit 0
end

failures.each do |failure|
  puts "[FAIL][#{failure.suite}] #{rel(failure.path)}: #{failure.message}"
end

exit 1
