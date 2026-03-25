#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path
TARGET_PATTERNS = [
  "README.md",
  "CHANGELOG.md",
  "skills/**/*.md"
].freeze

def targets
  TARGET_PATTERNS
    .flat_map { |pattern| Dir.glob(ROOT.join(pattern).to_s, File::FNM_EXTGLOB) }
    .select { |path| File.file?(path) }
    .sort
    .map { |path| Pathname.new(path).relative_path_from(ROOT).to_s }
end

def mdl_path
  ENV.fetch("MDL_BIN", "mdl")
end

if ARGV == ["--print-targets"]
  puts targets
  exit 0
end

if targets.empty?
  warn "No markdown files matched lint targets."
  exit 0
end

exec mdl_path, *targets
