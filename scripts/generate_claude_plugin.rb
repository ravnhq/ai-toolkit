#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Transform marketplace.json (corvus format) → .claude-plugin/marketplace.json (Claude Code format)
# plus generate wrapper plugin directories under .claude-plugin/plugins/<name>/skills/<name>/
# so Claude Code discovers SKILL.md at the expected nesting (<plugin-root>/skills/<name>/SKILL.md).
#
# Differences from corvus format:
#   - Root key: "skills" → "plugins"
#   - Source: "skills/<cat>/<name>" → "./.claude-plugin/plugins/<name>" (wrapper plugin dir)
#   - Version: integer build → semver string (1.0.0 baseline)
#   - Filter: exclude agent-skills-manager (corvus-only) and scaffold skills
#
# Usage: ruby scripts/generate_claude_plugin.rb
#
# Outputs:
#   - .claude-plugin/marketplace.json
#   - .claude-plugin/plugins/<name>/skills/<name>/** (copies of each included skill)

require "json"
require "yaml"
require "pathname"
require "fileutils"

ROOT = Pathname.new(__dir__).join("..").expand_path
MARKETPLACE_PATH = ROOT.join("marketplace.json")
PLUGIN_DIR = ROOT.join(".claude-plugin")
OUTPUT_PATH = PLUGIN_DIR.join("marketplace.json")
PLUGIN_JSON_PATH = PLUGIN_DIR.join("plugin.json")
PLUGINS_DIR = PLUGIN_DIR.join("plugins")

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

  source_dir = ROOT.join(skill["source"].sub(%r{^\./}, ""))
  unless source_dir.directory? && source_dir.join("SKILL.md").exist?
    warn "Skipping #{name}: source directory or SKILL.md missing at #{source_dir}"
    return nil
  end

  # Copy skill contents into wrapper plugin layout:
  # .claude-plugin/plugins/<name>/skills/<name>/<skill-contents>
  wrapper_root = PLUGINS_DIR.join(name)
  wrapper_skill = wrapper_root.join("skills", name)
  wrapper_skill.mkpath
  source_dir.each_child do |entry|
    FileUtils.cp_r(entry.to_s, wrapper_skill.to_s, preserve: true)
  end

  semver = metadata.dig("metadata", "semver") || "1.0.0"

  {
    "name" => name,
    "source" => "./.claude-plugin/plugins/#{name}",
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

  # Clean generated wrapper plugin dirs — they are rebuilt from scratch each run
  FileUtils.rm_rf(PLUGINS_DIR.to_s)
  PLUGINS_DIR.mkpath

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
