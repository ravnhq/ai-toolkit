#!/usr/bin/env node
/**
 * categorize-errors.js — Reads ESLint JSON output and groups errors by rule ID.
 *
 * Usage:
 *   npx eslint . --format json 2>/dev/null | node categorize-errors.js
 *
 * Outputs a prioritized summary showing which rules have the most violations,
 * grouped by fix category (auto-fixable vs manual), to guide systematic remediation.
 */

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
	let data;
	try {
		data = JSON.parse(input);
	} catch {
		console.error(
			"❌ Invalid JSON input. Run: npx eslint . --format json 2>/dev/null | node categorize-errors.js",
		);
		process.exit(1);
	}

	const byRule = new Map();
	let totalErrors = 0;
	let totalFixable = 0;
	let filesWithErrors = 0;

	for (const file of data) {
		const filePath = file.filePath || "unknown";
		const messages = file.messages || [];
		if (messages.length === 0) continue;

		filesWithErrors++;

		for (const msg of messages) {
			const ruleId = msg.ruleId || "parse-error";
			if (msg.severity === 0) continue;

			totalErrors++;

			if (!byRule.has(ruleId)) {
				byRule.set(ruleId, {
					count: 0,
					fixable: 0,
					files: new Set(),
					samples: [],
				});
			}

			const entry = byRule.get(ruleId);
			entry.count++;
			entry.files.add(filePath);

			if (msg.fix) {
				entry.fixable++;
				totalFixable++;
			}

			if (entry.samples.length < 2) {
				const shortPath = filePath.split("/").pop();
				entry.samples.push(
					`  ${shortPath}:${msg.line || "?"}:${msg.column || "?"} — ${msg.message || ""}`,
				);
			}
		}
	}

	if (totalErrors === 0) {
		console.log("✅ No lint errors found!");
		process.exit(0);
	}

	const sorted = [...byRule.entries()].sort((a, b) => b[1].count - a[1].count);
	const autoFixable = sorted.filter(([, d]) => d.fixable > 0);
	const manualOnly = sorted.filter(([, d]) => d.fixable === 0);

	const pct = (n, total) => Math.round((n * 100) / total);

	console.log("=".repeat(60));
	console.log(`  ESLint Error Summary`);
	console.log(
		`  Total errors: ${totalErrors} across ${filesWithErrors} files`,
	);
	console.log(
		`  Auto-fixable: ${totalFixable} (${pct(totalFixable, totalErrors)}%)`,
	);
	console.log(
		`  Manual fixes: ${totalErrors - totalFixable} (${pct(totalErrors - totalFixable, totalErrors)}%)`,
	);
	console.log("=".repeat(60));

	if (autoFixable.length > 0) {
		console.log(`\n${"─".repeat(60)}`);
		console.log("  🔧 AUTO-FIXABLE (run `npx eslint . --fix`)");
		console.log("─".repeat(60));
		for (const [ruleId, info] of autoFixable) {
			const fixPct = pct(info.fixable, info.count);
			console.log(
				`\n  ${ruleId}: ${info.count} errors in ${info.files.size} files (${fixPct}% auto-fixable)`,
			);
			for (const s of info.samples) console.log(s);
		}
	}

	if (manualOnly.length > 0) {
		console.log(`\n${"─".repeat(60)}`);
		console.log("  🛠️  MANUAL FIXES REQUIRED");
		console.log("─".repeat(60));
		for (const [ruleId, info] of manualOnly) {
			console.log(
				`\n  ${ruleId}: ${info.count} errors in ${info.files.size} files`,
			);
			for (const s of info.samples) console.log(s);
		}
	}

	// Priority fix order
	console.log(`\n${"=".repeat(60)}`);
	console.log("  📋 SUGGESTED FIX ORDER");
	console.log("=".repeat(60));

	const priorityOrder = [
		["@typescript-eslint/no-unused-vars", "Remove unused imports/variables"],
		["@typescript-eslint/no-explicit-any", "Replace `any` with proper types"],
		["@typescript-eslint/no-unsafe-", "Add type guards or proper typing"],
		["@typescript-eslint/no-deprecated", "Migrate to replacement APIs"],
		["unicorn/", "Apply unicorn best practices"],
		["promise/", "Fix promise handling patterns"],
		[
			"sonarjs/cognitive-complexity",
			"Extract helper functions, simplify logic",
		],
		["max-lines", "Split files exceeding 300 lines"],
		["react/no-multi-comp", "One component per file"],
		[
			"react/no-unstable-nested-components",
			"Extract nested components",
		],
	];

	let step = 1;
	const seen = new Set();

	for (const [prefix, description] of priorityOrder) {
		const matching = sorted.filter(
			([r]) => r.startsWith(prefix) && !seen.has(r),
		);
		if (matching.length > 0) {
			const total = matching.reduce((sum, [, d]) => sum + d.count, 0);
			const ruleNames = matching.map(([r]) => r).join(", ");
			console.log(`\n  ${step}. ${description}`);
			console.log(`     Rules: ${ruleNames}`);
			console.log(`     Errors: ${total}`);
			step++;
			for (const [r] of matching) seen.add(r);
		}
	}

	const remaining = sorted.filter(([r]) => !seen.has(r));
	if (remaining.length > 0) {
		const total = remaining.reduce((sum, [, d]) => sum + d.count, 0);
		console.log(`\n  ${step}. Other rules (${total} errors)`);
		for (const [r, d] of remaining) {
			console.log(`     ${r}: ${d.count}`);
		}
	}

	console.log();
});
