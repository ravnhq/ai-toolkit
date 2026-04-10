#!/usr/bin/env ruby
# frozen_string_literal: true

# Scores a single skill on a 0-100 composite scale.
# Usage: ruby scripts/skill_score.rb skills/platform/platform-frontend/SKILL.md
#
# Weights:
#   Trigger alignment  — 30 points
#   Functional checks  — 40 points
#   Performance limits  — 20 points
#   Audit (structure)   — 10 points
#
# Exit code 0 always. Score printed to stdout as last line: "score: NN.N"

require "yaml"
require "pathname"
require "json"

ROOT = Pathname.new(__dir__).join("..").expand_path

skill_path = ARGV[0]
unless skill_path
  warn "Usage: ruby scripts/skill_score.rb <path-to-SKILL.md>"
  exit 1
end

skill_path = File.expand_path(skill_path, ROOT)
unless File.exist?(skill_path)
  warn "File not found: #{skill_path}"
  exit 1
end

# --- Parse ---

text = File.read(skill_path)
lines = text.lines
end_idx = lines[1..]&.find_index { |line| line.strip == "---" }
frontmatter = end_idx ? (YAML.safe_load(lines[1..end_idx].join, permitted_classes: [], aliases: false) || {}) : {}
body = end_idx ? (lines[(end_idx + 2)..] || []).join : text
description = frontmatter.fetch("description", "").to_s

STOPWORDS = %w[
  the and for with from this that these those use when users say your about into over under
  not any all one two three four five six seven eight nine ten only most more less should
  where what who why how will would could can must have has had into than then also
].freeze

def keyword_set(desc)
  desc.downcase.scan(/[a-z][a-z0-9+-]{3,}/).reject { |t| STOPWORDS.include?(t) }.uniq
end

def extract_user_prompt(block)
  block[/User:\s*[""\u201c](.+?)[""\u201d]/m, 1]
end

# --- Trigger suite (0-30) ---

trigger_score = 0.0
positive_block = body[/^###\s+Positive Trigger\b(.*?)(?=^###\s+Non-Trigger\b|^##\s+Troubleshooting\b|\z)/mi, 1].to_s
negative_block = body[/^###\s+Non-Trigger\b(.*?)(?=^##\s+Troubleshooting\b|\z)/mi, 1].to_s
positive_prompt = extract_user_prompt(positive_block).to_s
negative_prompt = extract_user_prompt(negative_block).to_s

if !positive_prompt.empty? && !negative_prompt.empty?
  keywords = keyword_set(description)
  positive_hits = keywords.count { |t| positive_prompt.downcase.include?(t) }
  negative_hits = keywords.count { |t| negative_prompt.downcase.include?(t) }

  if positive_hits > 0 && positive_hits > negative_hits
    trigger_score = 30.0
  elsif positive_hits > 0
    trigger_score = 15.0 # partial — hits exist but not stronger than negative
  end
end

# --- Functional suite (0-40) ---

checks = [
  body.match?(/^##+\s+Workflow\b/i),
  body.match?(/^##+\s+Examples?\b/i),
  body.match?(/^##+\s+Troubleshooting\b/i),
  body.include?("- Error:"),
  body.include?("- Cause:"),
  body.include?("- Solution:"),
  body.include?("Expected behavior:")
]
functional_score = (checks.count(true).to_f / checks.length) * 40.0

# --- Performance suite (0-20) ---

body_lines = body.lines.count
body_words = body.split(/\s+/).reject(&:empty?).count

perf_checks = [
  body_lines <= 500,
  body_words <= 5000,
  description.length <= 1024
]
performance_score = (perf_checks.count(true).to_f / perf_checks.length) * 20.0

# --- Audit suite (0-10) ---

audit_errors = 0
name = frontmatter["name"].to_s
folder = File.basename(File.dirname(skill_path))
metadata = frontmatter["metadata"]
status = frontmatter.dig("metadata", "status")
active = skill_path.include?("/skills/") && status != "scaffold" && status != "draft"

audit_errors += 1 unless frontmatter.key?("name")
audit_errors += 1 unless frontmatter.key?("description")
audit_errors += 1 unless name.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
audit_errors += 1 unless name == folder
audit_errors += 1 if name.match?(/(claude|anthropic)/i)
audit_errors += 1 if description.empty?
audit_errors += 1 if description.length > 1024
audit_errors += 1 if active && !description.match?(/\b(use when|when users say|when)\b/i)

if active && metadata.is_a?(Hash) && metadata["version"]
  audit_errors += 1 unless metadata["version"].to_s.match?(/\A[1-9]\d*\z/)
  # Check marketplace consistency
  marketplace_path = ROOT.join("marketplace.json")
  if File.exist?(marketplace_path)
    marketplace = JSON.parse(File.read(marketplace_path)) rescue {}
    entry = (marketplace["skills"] || []).find { |s| s["name"] == name }
    if entry
      audit_errors += 1 if entry["version"].to_s != metadata["version"].to_s
    else
      audit_errors += 1
    end
  end
end

audit_score = [0.0, (1.0 - (audit_errors / 10.0))] .max * 10.0

# --- Composite ---

total = trigger_score + functional_score + performance_score + audit_score

puts "--- Skill Score: #{name} ---"
puts "trigger:     #{trigger_score.round(1)}/30"
puts "functional:  #{functional_score.round(1)}/40"
puts "performance: #{performance_score.round(1)}/20"
puts "audit:       #{audit_score.round(1)}/10"
puts "score: #{total.round(1)}"
