#!/usr/bin/env ruby
# frozen_string_literal: true

# Extract structural skeletons from a design-variations gallery HTML file.
#
# Usage:
#   ruby scripts/extract_skeletons.rb <path-to-gallery.html> [--json] [--threshold N]
#
# Parses each `.variation-preview` (or `.variation-cell > :last-child`) block,
# strips attributes/text/comments/whitespace, and emits a canonical tag-tree
# skeleton. Hashes each skeleton to compare structural identity across
# variations. Exits 1 if the distinct-skeleton ratio falls below THRESHOLD
# (default 0.50 — the SKILL.md §"Structural Mutation" mandate).
#
# stdlib-only (no nokogiri); parses with a tolerant tag tokenizer. Gallery
# HTML produced by this skill is well-formed enough for the tokenizer.

require "digest"
require "json"
require "strscan"

THRESHOLD_DEFAULT = 0.50

# Tags that don't introduce a child node we care about (self-closing / void).
VOID_TAGS = %w[area base br col embed hr img input link meta param source track wbr].freeze

# Tags we skip entirely when building the skeleton tree — they're chrome, not
# structural signal. We keep them for gallery-cell detection but exclude them
# from the DOM hash.
SKELETON_IGNORE = %w[style script svg path g rect circle line polyline polygon defs use symbol title desc].freeze

def strip_comments(html)
  html.gsub(/<!--.*?-->/m, "")
end

# Extract each variation preview block. Galleries produced by this skill wrap
# each variation in `<div class="variation-cell">…<div class="variation-preview">RENDERED</div></div>`.
# We capture the inside of `variation-preview`.
def extract_preview_blocks(html)
  blocks = []
  # Non-greedy match on variation-preview opening, balance with a stack walk.
  offset = 0
  while (match = html.match(/<div[^>]*class="[^"]*\bvariation-preview\b[^"]*"[^>]*>/, offset))
    start = match.end(0)
    depth = 1
    pos = start
    while depth.positive? && pos < html.length
      open_tag = html.index(/<div\b/i, pos)
      close_tag = html.index(%r{</div>}i, pos)
      break unless close_tag
      if open_tag && open_tag < close_tag
        depth += 1
        pos = open_tag + 4
      else
        depth -= 1
        pos = close_tag + 6
      end
    end
    blocks << html[start...(pos - 6)]
    offset = pos
  end
  blocks
end

# Tokenise an HTML fragment into a flat list of :open/:close/:void events,
# skipping SKELETON_IGNORE subtrees.
def tokenize(fragment)
  tokens = []
  skip_depth = 0
  skip_tag = nil
  scanner = StringScanner.new(fragment)
  until scanner.eos?
    if scanner.scan(/[^<]+/)
      next
    end
    break unless scanner.scan(/</)

    if scanner.scan(%r{/([a-zA-Z][a-zA-Z0-9:-]*)\s*>})
      tag = scanner[1].downcase
      if skip_depth.positive? && tag == skip_tag
        skip_depth -= 1
        skip_tag = nil if skip_depth.zero?
      elsif skip_depth.zero?
        tokens << [:close, tag]
      end
    elsif scanner.scan(/([a-zA-Z][a-zA-Z0-9:-]*)([^>]*?)(\/?)>/)
      tag = scanner[1].downcase
      self_close = !scanner[3].empty? || VOID_TAGS.include?(tag)
      if skip_depth.positive?
        skip_depth += 1 unless self_close
      elsif SKELETON_IGNORE.include?(tag)
        unless self_close
          skip_depth = 1
          skip_tag = tag
        end
      elsif self_close
        tokens << [:void, tag]
      else
        tokens << [:open, tag]
      end
    else
      # unrecognised — advance one char to avoid infinite loop
      scanner.getch
    end
  end
  tokens
end

# Canonicalise tokens into a nested skeleton string: `tag(child1,child2(grandchild),…)`
def canonical_skeleton(tokens)
  stack = [[:root, []]]
  tokens.each do |kind, tag|
    case kind
    when :open
      frame = [tag, []]
      stack.last[1] << frame
      stack.push(frame)
    when :void
      stack.last[1] << [tag, []]
    when :close
      stack.pop if stack.size > 1
    end
  end
  render = lambda do |node|
    tag, kids = node
    return tag if kids.empty?
    "#{tag}(#{kids.map(&render).join(',')})"
  end
  children = stack.first[1]
  children.map(&render).join(",")
end

def analyze(path, threshold: THRESHOLD_DEFAULT, json: false)
  html = strip_comments(File.read(path))
  previews = extract_preview_blocks(html)
  skeletons = previews.each_with_index.map do |block, idx|
    tokens = tokenize(block)
    canon = canonical_skeleton(tokens)
    hash = Digest::SHA1.hexdigest(canon)[0, 10]
    { index: idx + 1, skeleton: canon, hash: hash }
  end

  total = skeletons.size
  distinct = skeletons.map { |s| s[:hash] }.uniq.size
  ratio = total.zero? ? 0.0 : distinct.to_f / total

  duplicates = skeletons.group_by { |s| s[:hash] }.reject { |_, g| g.size < 2 }

  report = {
    file: path,
    variations: total,
    distinct_skeletons: distinct,
    distinct_ratio: ratio.round(3),
    threshold: threshold,
    pass: ratio >= threshold,
    duplicates: duplicates.map { |hash, group| { hash: hash, indices: group.map { |s| s[:index] } } }
  }

  if json
    puts JSON.pretty_generate(report.merge(skeletons: skeletons))
  else
    puts "File: #{path}"
    puts "Variations: #{total}"
    puts "Distinct skeletons: #{distinct} (#{(ratio * 100).round(1)}%)"
    puts "Threshold: #{(threshold * 100).round(1)}% — #{report[:pass] ? 'PASS' : 'FAIL'}"
    unless duplicates.empty?
      puts
      puts "Duplicate skeleton groups:"
      duplicates.each do |hash, group|
        puts "  [#{hash}] variations #{group.map { |s| s[:index] }.join(', ')}"
      end
    end
  end

  report[:pass]
end

if $PROGRAM_NAME == __FILE__
  args = ARGV.dup
  json_mode = args.delete("--json") ? true : false
  threshold = THRESHOLD_DEFAULT
  if (i = args.index("--threshold"))
    threshold = args.delete_at(i + 1).to_f
    args.delete_at(i)
  end

  if args.empty?
    warn "Usage: #{$PROGRAM_NAME} <gallery.html> [--json] [--threshold N]"
    exit 2
  end

  results = args.map { |path| analyze(path, threshold: threshold, json: json_mode) }
  exit(results.all? ? 0 : 1)
end
