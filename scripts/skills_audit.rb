#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "pathname"
require "set"
require "json"

ROOT = Pathname.new(__dir__).join("..").expand_path
SKILL_FILES = Dir.glob(ROOT.join("skills/**/SKILL.md").to_s).sort
ACTIVE_SKILL_FILES = Dir.glob(ROOT.join("skills/*/*/SKILL.md").to_s).sort

ALLOWED_FRONTMATTER_KEYS = Set.new(%w[name description license allowed-tools compatibility metadata]).freeze
NAME_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
RESERVED_NAME_PATTERN = /(claude|anthropic)/i
WHEN_PATTERN = /\b(use when|when users say|when)\b/i
BUILD_PATTERN = /\A[1-9]\d*\z/

Issue = Struct.new(:severity, :code, :path, :message, keyword_init: true)

def rel(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
end

def parse_skill(path, issues)
  text = File.read(path)
  lines = text.lines

  unless lines.first&.strip == "---"
    issues << Issue.new(severity: :error, code: "missing_frontmatter", path:, message: "Missing YAML frontmatter delimiters.")
    return [{}, text]
  end

  end_idx = lines[1..]&.find_index { |line| line.strip == "---" }
  unless end_idx
    issues << Issue.new(severity: :error, code: "invalid_frontmatter", path:, message: "Unterminated YAML frontmatter block.")
    return [{}, text]
  end

  frontmatter_text = lines[1..end_idx].join
  body = (lines[(end_idx + 2)..] || []).join

  frontmatter = begin
    YAML.safe_load(frontmatter_text, permitted_classes: [], aliases: false)
  rescue StandardError => error
    issues << Issue.new(severity: :error, code: "yaml_parse_error", path:, message: "Invalid YAML frontmatter: #{error.message}")
    {}
  end

  unless frontmatter.is_a?(Hash)
    issues << Issue.new(severity: :error, code: "frontmatter_not_map", path:, message: "Frontmatter must parse to a YAML mapping.")
    frontmatter = {}
  end

  [frontmatter, body]
end

def strip_fenced_code(markdown)
  in_fence = false
  kept = []

  markdown.each_line do |line|
    if line.lstrip.start_with?("```")
      in_fence = !in_fence
      next
    end
    kept << line unless in_fence
  end

  kept.join
end

def check_frontmatter(path, frontmatter, issues)
  keys = frontmatter.keys.map(&:to_s)
  unexpected = keys.reject { |key| ALLOWED_FRONTMATTER_KEYS.include?(key) }
  unless unexpected.empty?
    issues << Issue.new(severity: :error, code: "unexpected_frontmatter_keys", path:, message: "Unexpected frontmatter keys: #{unexpected.join(", ")}")
  end

  unless frontmatter.key?("name")
    issues << Issue.new(severity: :error, code: "missing_name", path:, message: "Frontmatter must include `name`.")
    return
  end

  unless frontmatter.key?("description")
    issues << Issue.new(severity: :error, code: "missing_description", path:, message: "Frontmatter must include `description`.")
    return
  end

  name = frontmatter["name"].to_s
  description = frontmatter["description"].to_s
  folder = File.basename(File.dirname(path))

  unless name.match?(NAME_PATTERN)
    issues << Issue.new(severity: :error, code: "invalid_name_format", path:, message: "Name must be kebab-case.")
  end

  unless name == folder
    issues << Issue.new(severity: :error, code: "name_folder_mismatch", path:, message: "Name `#{name}` must match folder `#{folder}`.")
  end

  if name.match?(RESERVED_NAME_PATTERN)
    issues << Issue.new(severity: :error, code: "reserved_name", path:, message: "Name must not include reserved terms `claude` or `anthropic`.")
  end

  if description.empty?
    issues << Issue.new(severity: :error, code: "empty_description", path:, message: "Description must be non-empty.")
  end

  if description.length > 1024
    issues << Issue.new(severity: :error, code: "description_too_long", path:, message: "Description exceeds 1024 characters (#{description.length}).")
  end

  if description.include?("<") || description.include?(">")
    issues << Issue.new(severity: :error, code: "description_angle_brackets", path:, message: "Description must not include angle brackets.")
  end
end

def check_metadata(path, frontmatter, issues)
  metadata = frontmatter["metadata"]
  active = path.include?("/skills/") && !path.include?("/skills/_drafts/")

  return unless active

  unless metadata.is_a?(Hash)
    issues << Issue.new(severity: :warn, code: "missing_metadata", path:, message: "Missing `metadata.version` — CI will bootstrap to build 1 on merge.")
    return
  end

  if metadata["version"]
    version = metadata["version"].to_s
    unless version.match?(BUILD_PATTERN)
      issues << Issue.new(severity: :error, code: "invalid_version_format", path:, message: "Version `#{version}` must be a positive integer build id (e.g., 1, 2, 3).")
    end
  else
    issues << Issue.new(severity: :warn, code: "missing_version", path:, message: "Missing `metadata.version` — CI will bootstrap to build 1 on merge.")
  end
end

def check_structure(path, body, frontmatter, issues)
  active = path.include?("/skills/") && !path.include?("/skills/_drafts/")

  if active && !frontmatter["description"].to_s.match?(WHEN_PATTERN)
    issues << Issue.new(severity: :error, code: "description_missing_when", path:, message: "Active skills must include explicit trigger language (`Use when ...`).")
  end

  if active && body !~ /^##+\s+Examples?\b/i
    issues << Issue.new(severity: :error, code: "missing_examples_section", path:, message: "Active skills must include an `## Examples` section.")
  end

  if active && body !~ /^##+\s+Troubleshooting\b/i
    issues << Issue.new(severity: :error, code: "missing_troubleshooting_section", path:, message: "Active skills must include an `## Troubleshooting` section.")
  end

  if active && body !~ /^##+\s+Workflow\b/i
    issues << Issue.new(severity: :error, code: "missing_workflow_section", path:, message: "Active skills must include an `## Workflow` section.")
  end

  readme_paths = [File.join(File.dirname(path), "README.md"), File.join(File.dirname(path), "readme.md")]
  if readme_paths.any? { |readme| File.exist?(readme) }
    issues << Issue.new(severity: :error, code: "readme_not_allowed", path:, message: "Skill folders must not include README.md/readme.md.")
  end
end

def check_links(path, body, issues)
  text = strip_fenced_code(body)
  text.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |target|
    link_path = target.split("#", 2).first
    next if link_path.nil? || link_path.empty?
    next if link_path.match?(/\Ahttps?:\/\//i) || link_path.match?(/\Amailto:/i)

    absolute = File.expand_path(link_path, File.dirname(path))
    next if File.exist?(absolute)

    issues << Issue.new(severity: :error, code: "broken_local_link", path:, message: "Broken local link target `#{target}`.")
  end
end

def check_version_consistency(skill_data, issues)
  # skill_data is array of [path, frontmatter] tuples for active skills
  marketplace_path = ROOT.join("marketplace.json").to_s

  unless File.exist?(marketplace_path)
    issues << Issue.new(severity: :error, code: "marketplace_missing", path: marketplace_path, message: "marketplace.json not found.")
    return
  end

  marketplace = begin
    JSON.parse(File.read(marketplace_path))
  rescue StandardError => error
    issues << Issue.new(severity: :error, code: "marketplace_json_error", path: marketplace_path, message: "Invalid JSON: #{error.message}")
    return
  end

  # Collect versions from active SKILL.md files
  skill_versions = {}
  skill_data.each do |path, frontmatter|
    name = frontmatter["name"]
    version = frontmatter.dig("metadata", "version")
    next unless name

    # Skills without a version are not checked for consistency —
    # CI will bootstrap the version on merge.
    next unless version

    skill_versions[name] = { version:, path: }
  end

  return if skill_versions.empty?

  # Check 1: SKILL.md versions must match marketplace.json entries
  marketplace_skills = (marketplace["skills"] || [])
  marketplace_index = marketplace_skills.each_with_object({}) { |entry, acc| acc[entry["name"]] = entry }

  skill_versions.each do |name, data|
    entry = marketplace_index[name]
    unless entry
      issues << Issue.new(
        severity: :error,
        code: "missing_marketplace_entry",
        path: data[:path],
        message: "Active skill `#{name}` is missing from marketplace.json."
      )
      next
    end

    marketplace_version = entry["version"]
    unless marketplace_version
      issues << Issue.new(
        severity: :error,
        code: "missing_marketplace_version",
        path: data[:path],
        message: "Marketplace entry for `#{name}` is missing a version build id."
      )
      next
    end

    skill_version = data[:version].to_s
    if skill_version != marketplace_version.to_s
      issues << Issue.new(
        severity: :error,
        code: "version_mismatch_marketplace",
        path: data[:path],
        message: "Version `#{skill_version}` in SKILL.md does not match marketplace.json version `#{marketplace_version}`."
      )
    end
  end
end

issues = []
active_skill_data = []

SKILL_FILES.each do |path|
  frontmatter, body = parse_skill(path, issues)
  check_frontmatter(path, frontmatter, issues)
  check_metadata(path, frontmatter, issues)
  check_structure(path, body, frontmatter, issues)
  check_links(path, body, issues)

  # Collect active skill data for version consistency checks
  if path.include?("/skills/") && !path.include?("/skills/_drafts/")
    active_skill_data << [path, frontmatter]
  end
end

# Cross-file version consistency checks
check_version_consistency(active_skill_data, issues)

puts "Skill files audited: #{SKILL_FILES.count}"
puts "Active skills audited: #{ACTIVE_SKILL_FILES.count}"

if issues.empty?
  puts "PASS: no issues found."
  exit 0
end

issues.sort_by { |issue| [issue.severity == :error ? 0 : 1, issue.path, issue.code] }.each do |issue|
  puts "[#{issue.severity.upcase}] #{issue.code} #{rel(issue.path)}: #{issue.message}"
end

error_count = issues.count { |issue| issue.severity == :error }
warn_count = issues.count { |issue| issue.severity == :warn }
puts "Summary: errors=#{error_count}, warnings=#{warn_count}"

exit(error_count.zero? ? 0 : 1)
