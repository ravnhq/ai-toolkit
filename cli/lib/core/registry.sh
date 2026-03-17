#!/usr/bin/env bash
# cli/lib/core/registry.sh — Parse marketplace.json, resolve deps, search

MARKETPLACE_FILE="${RAVENCITO_DIR}/repo/marketplace.json"

# Ensure registry is available
ensure_registry() {
    if [[ ! -f "$MARKETPLACE_FILE" ]]; then
        die "Registry not found. Run 'ravencito update' to refresh."
    fi
}

# Get skill count
registry_skill_count() {
    ensure_registry
    if has_cmd jq; then
        jq '.skills | length' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "import json; print(len(json.load(open('$MARKETPLACE_FILE'))['skills']))"
    fi
}

# List all skill names
registry_skill_names() {
    ensure_registry
    if has_cmd jq; then
        jq -r '.skills[].name' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
for s in data['skills']:
    print(s['name'])
"
    fi
}

# Get a field for a specific skill
# Usage: registry_skill_field "tech-react" "description"
registry_skill_field() {
    local name="$1" field="$2"
    ensure_registry
    if has_cmd jq; then
        jq -r --arg n "$name" --arg f "$field" \
            '.skills[] | select(.name == $n) | .[$f] // empty' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
for s in data['skills']:
    if s['name'] == '$name':
        v = s.get('$field', '')
        if isinstance(v, list): print(','.join(str(x) for x in v))
        elif v: print(v)
        break
"
    fi
}

# Get full skill info as formatted text
registry_skill_info() {
    local name="$1"
    ensure_registry
    if has_cmd jq; then
        jq -r --arg n "$name" '
            .skills[] | select(.name == $n) |
            "Name:        \(.name)\nDescription: \(.description)\nCategory:    \(.category)\nTags:        \(.tags | join(", "))\nExtends:     \(.extends // "—")\nVersion:     \(.version // "—")\nRules:       \(.rules // "—")\nSource:      \(.source)"
        ' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
for s in data['skills']:
    if s['name'] == '$name':
        print(f\"Name:        {s['name']}\")
        print(f\"Description: {s['description']}\")
        print(f\"Category:    {s['category']}\")
        print(f\"Tags:        {', '.join(s.get('tags', []))}\")
        print(f\"Extends:     {s.get('extends', '—')}\")
        print(f\"Version:     {s.get('version', '—')}\")
        print(f\"Rules:       {s.get('rules', '—')}\")
        print(f\"Source:      {s['source']}\")
        break
else:
    print('Skill not found: $name')
"
    fi
}

# Check if a skill exists in registry
registry_skill_exists() {
    local name="$1"
    ensure_registry
    local result
    if has_cmd jq; then
        result=$(jq -r --arg n "$name" '.skills[] | select(.name == $n) | .name' "$MARKETPLACE_FILE")
    elif has_cmd python3; then
        result=$(python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
for s in data['skills']:
    if s['name'] == '$name':
        print(s['name'])
        break
")
    fi
    [[ -n "$result" ]]
}

# Get skill version from registry
registry_skill_version() {
    registry_skill_field "$1" "version"
}

# Get skill source path from registry
registry_skill_source() {
    registry_skill_field "$1" "source"
}

# Resolve dependency chain for a skill (returns all needed skills in install order)
# Usage: registry_resolve_deps "tech-react" → "core-coding-standards platform-frontend tech-react"
registry_resolve_deps() {
    local name="$1"
    local chain=""
    local current="$name"

    while [[ -n "$current" ]]; do
        chain="${current}${chain:+ ${chain}}"
        current=$(registry_skill_field "$current" "extends")
    done

    echo "$chain"
}

# List skills by category
# Usage: registry_skills_by_category "framework"
registry_skills_by_category() {
    local category="$1"
    ensure_registry
    if has_cmd jq; then
        jq -r --arg c "$category" \
            '.skills[] | select(.category == $c) | .name' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
for s in data['skills']:
    if s['category'] == '$category':
        print(s['name'])
"
    fi
}

# Get all categories with counts
registry_categories() {
    ensure_registry
    if has_cmd jq; then
        jq -r '[.skills[].category] | group_by(.) | map("\(.[0]) \(length)") | .[]' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
from collections import Counter
data = json.load(open('$MARKETPLACE_FILE'))
counts = Counter(s['category'] for s in data['skills'])
for cat in sorted(counts):
    print(f'{cat} {counts[cat]}')
"
    fi
}

# Search skills by keyword (matches name, description, tags)
# Usage: registry_search "react"
registry_search() {
    local query="$1"
    local query_lower
    query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')
    ensure_registry
    if has_cmd jq; then
        jq -r --arg q "$query_lower" '
            .skills[] |
            select(
                (.name | ascii_downcase | contains($q)) or
                (.description | ascii_downcase | contains($q)) or
                (.tags | map(ascii_downcase) | any(contains($q)))
            ) | .name
        ' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
q = '$query_lower'
for s in data['skills']:
    if (q in s['name'].lower() or
        q in s['description'].lower() or
        any(q in t.lower() for t in s.get('tags', []))):
        print(s['name'])
"
    fi
}

# Get formatted skill list for display (name + description)
registry_skill_list_formatted() {
    ensure_registry
    if has_cmd jq; then
        jq -r '.skills[] | "\(.name)\t\(.description)"' "$MARKETPLACE_FILE"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$MARKETPLACE_FILE'))
for s in data['skills']:
    print(f\"{s['name']}\t{s['description']}\")
"
    fi
}
