#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Transform marketplace.json (corvus format) → .claude-plugin/marketplace.json (Claude Code format)
#
# Differences:
#   - Root key: "skills" → "plugins"
#   - Source prefix: "skills/..." → "./skills/..."
#   - Version: integer build → semver string (1.0.0 baseline)
#   - Filter: exclude agent-skills-manager (corvus-only) and scaffold skills
#
# Usage: ruby scripts/generate_claude_plugin.rb
#
# Outputs .claude-plugin/marketplace.json

require "json"
require "yaml"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
MARKETPLACE_PATH = ROOT.join("marketplace.json")
PLUGIN_DIR = ROOT.join(".claude-plugin")
OUTPUT_PATH = PLUGIN_DIR.join("marketplace.json")
PLUGIN_JSON_PATH = PLUGIN_DIR.join("plugin.json")

# Skills excluded from Claude Code distribution (corvus-only)
EXCLUDED_SKILLS = %w[agent-skills-manager].freeze

def read_skill_metadata(source_path)
  skill_md = ROOT.join(source_path.sub(%r{^\./}, ""), "SKILL.md")
  return {} unless skill_md.exist?

  content = File.read(skill_md)
  return {} unless content =~ /\A---\n(.*?)\n---\n/m

  YAML.safe_load(::Regexp.last_match(1), permitted_classes: [Symbol]) || {}
rescue StandardError => e
  warn "Warning: Could not parse #{skill_md}: #{e.message}"
  {}
end

def transform_skill(skill)
  name = skill["name"]
  return nil if EXCLUDED_SKILLS.include?(name)
  return nil if skill["status"] == "scaffold"

  # Read SKILL.md for distribution check
  metadata = read_skill_metadata(skill["source"])
  distribution = metadata.dig("metadata", "distribution")

  # If distribution specified and doesn't include claude-code, skip
  if distribution.is_a?(Array) && !distribution.include?("claude-code")
    warn "Skipping #{name}: distribution excludes claude-code"
    return nil
  end

  # Transform source path: add ./ prefix if missing
  source = skill["source"]
  source = "./#{source}" unless source.start_with?("./")

  # Use semver from metadata or default to 1.0.0
  semver = metadata.dig("metadata", "semver") || "1.0.0"

  {
    "name" => name,
    "source" => source,
    "description" => skill["description"],
    "version" => semver
  }
end

def main
  unless MARKETPLACE_PATH.exist?
    abort "Error: marketplace.json not found at #{MARKETPLACE_PATH}"
  end

  unless PLUGIN_JSON_PATH.exist?
    abort "Error: plugin.json not found at #{PLUGIN_JSON_PATH}"
  end

  marketplace = JSON.parse(File.read(MARKETPLACE_PATH))
  plugin_json = JSON.parse(File.read(PLUGIN_JSON_PATH))

  skills = marketplace["skills"] || []
  plugins = skills.filter_map { |skill| transform_skill(skill) }

  output = {
    "name" => plugin_json["name"] || marketplace["name"],
    "owner" => marketplace["owner"] || { "name" => "Ravn" },
    "plugins" => plugins
  }

  PLUGIN_DIR.mkpath
  File.write(OUTPUT_PATH, JSON.pretty_generate(output) + "\n")

  puts "Generated #{OUTPUT_PATH}"
  puts "  Total skills: #{skills.size}"
  puts "  Included plugins: #{plugins.size}"
  puts "  Excluded: #{skills.size - plugins.size}"
end

main if __FILE__ == $0
