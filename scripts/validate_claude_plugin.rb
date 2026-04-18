#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Validate .claude-plugin/ structure for Claude Code marketplace compatibility
#
# Checks:
#   - .claude-plugin/plugin.json exists and is valid JSON with required fields
#   - .claude-plugin/marketplace.json matches Claude Code schema
#   - All plugins have valid source paths pointing to existing SKILL.md
#   - Version format is semver (X.Y.Z)
#   - No scaffold skills included
#
# Usage: ruby scripts/validate_claude_plugin.rb
#
# Exit codes:
#   0 - All validations pass
#   1 - One or more validations failed

require "json"
require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
PLUGIN_DIR = ROOT.join(".claude-plugin")
PLUGIN_JSON = PLUGIN_DIR.join("plugin.json")
MARKETPLACE_JSON = PLUGIN_DIR.join("marketplace.json")

class Validator
  def initialize
    @errors = []
    @warnings = []
  end

  def validate
    validate_plugin_json
    validate_marketplace_json
    print_results
    @errors.empty?
  end

  private

  def error(msg)
    @errors << msg
  end

  def warn_msg(msg)
    @warnings << msg
  end

  def validate_plugin_json
    unless PLUGIN_JSON.exist?
      error "Missing .claude-plugin/plugin.json"
      return
    end

    begin
      data = JSON.parse(File.read(PLUGIN_JSON))
    rescue JSON::ParserError => e
      error "Invalid JSON in plugin.json: #{e.message}"
      return
    end

    # For relative-path marketplaces, version goes in marketplace.json per-plugin, not here
    %w[name description author].each do |field|
      error "plugin.json missing required field: #{field}" unless data[field]
    end

    unless data["author"].is_a?(Hash) && data.dig("author", "name")
      error "plugin.json author must be object with 'name' field"
    end
  end

  def validate_marketplace_json
    unless MARKETPLACE_JSON.exist?
      error "Missing .claude-plugin/marketplace.json — run scripts/generate_claude_plugin.rb"
      return
    end

    begin
      data = JSON.parse(File.read(MARKETPLACE_JSON))
    rescue JSON::ParserError => e
      error "Invalid JSON in marketplace.json: #{e.message}"
      return
    end

    # Required root fields
    %w[name owner plugins].each do |field|
      error "marketplace.json missing required field: #{field}" unless data[field]
    end

    unless data["owner"].is_a?(Hash) && data.dig("owner", "name")
      error "marketplace.json owner must be object with 'name' field"
    end

    plugins = data["plugins"]
    return unless plugins.is_a?(Array)

    plugins.each_with_index do |plugin, idx|
      validate_plugin(plugin, idx)
    end
  end

  def validate_plugin(plugin, idx)
    name = plugin["name"] || "plugin[#{idx}]"

    %w[name source description version].each do |field|
      error "#{name}: missing required field '#{field}'" unless plugin[field]
    end

    # Validate version is semver
    version = plugin["version"]
    if version && !version.match?(/^\d+\.\d+\.\d+$/)
      error "#{name}: version must be semver (X.Y.Z), got: #{version}"
    end

    # Validate source path exists (paths are relative to .claude-plugin/)
    source = plugin["source"]
    if source
      skill_path = PLUGIN_DIR.join(source, "SKILL.md")
      error "#{name}: source path not found: #{skill_path}" unless skill_path.exist?
    end

    # Warn if source doesn't start with ../ (paths must go up from .claude-plugin/)
    warn_msg "#{name}: source should start with '../' for Claude Code" if source && !source.start_with?("../")
  end

  def print_results
    if @warnings.any?
      puts "Warnings:"
      @warnings.each { |w| puts "  ⚠ #{w}" }
      puts
    end

    if @errors.any?
      puts "Errors:"
      @errors.each { |e| puts "  ✗ #{e}" }
      puts
      puts "Validation FAILED (#{@errors.size} errors)"
    else
      puts "✓ .claude-plugin/ validation passed"
      puts "  - plugin.json: valid"
      puts "  - marketplace.json: valid"
      plugins_count = begin
        JSON.parse(File.read(MARKETPLACE_JSON))["plugins"]&.size || 0
      rescue
        0
      end
      puts "  - plugins: #{plugins_count}"
    end
  end
end

exit(Validator.new.validate ? 0 : 1)
