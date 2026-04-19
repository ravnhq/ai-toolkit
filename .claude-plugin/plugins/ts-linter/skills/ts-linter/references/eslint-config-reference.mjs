import eslintComments from "@eslint-community/eslint-plugin-eslint-comments/configs";
import eslint from "@eslint/js";
import { defineConfig } from "eslint/config";
import tanstackQuery from "@tanstack/eslint-plugin-query";
import reactNativeConfig from "@react-native/eslint-config/flat";
import vitestPlugin from "@vitest/eslint-plugin";
import prettierConfig from "eslint-config-prettier";
import deMorgan from "eslint-plugin-de-morgan";
import drizzle from "eslint-plugin-drizzle";
import nodePlugin from "eslint-plugin-n";
import playwrightPlugin from "eslint-plugin-playwright";
import promisePlugin from "eslint-plugin-promise";
import reactPlugin from "eslint-plugin-react";
import reactHooksPlugin from "eslint-plugin-react-hooks";
import reactYouMightNotNeedAnEffect from "eslint-plugin-react-you-might-not-need-an-effect";
import regexpPlugin from "eslint-plugin-regexp";
import securityPlugin from "eslint-plugin-security";
import sonarjs from "eslint-plugin-sonarjs";
import testingLibrary from "eslint-plugin-testing-library";
import unicorn from "eslint-plugin-unicorn";
import globals from "globals";
import tseslint from "typescript-eslint";

export default defineConfig(
	// ============================================================
	// 🚫 GLOBAL IGNORES
	// Common build/output directories. Add your own as needed.
	// ============================================================
	{
		ignores: [
			"**/node_modules/**",
			"**/.next/**",
			"**/dist/**",
			"**/build/**",
			"**/.expo/**",
			"**/.trigger/**",
			"**/.turbo/**",
			"**/.wrangler/**",
			"**/coverage/**",
			".*/**",
			// ADD any generated files your project produces:
			// "**/routeTree.gen.ts",
		],
	},

	// ============================================================
	// ⛔ TREAT ALL WARNINGS AS ERRORS
	// Keeps CI clean — no "warning debt" piling up.
	// Run ESLint with: eslint . --max-warnings=0
	// This treats any warning as a CI failure — no plugin needed.
	// ============================================================

	// ============================================================
	// ✅ CORE: Language & Code Quality (everyone keeps this)
	//
	// These are framework-agnostic and apply to any TS/JS project.
	// 📦 @eslint/js, typescript-eslint, eslint-plugin-unicorn,
	//    eslint-plugin-de-morgan, eslint-plugin-promise,
	//    eslint-plugin-security, eslint-plugin-sonarjs (v4+, SSALv1 license),
	//    eslint-plugin-regexp, @eslint-community/eslint-plugin-eslint-comments
	// ============================================================
	eslint.configs.recommended,
	...tseslint.configs.recommended,
	...tseslint.configs.recommendedTypeChecked,
	deMorgan.configs.recommended,
	unicorn.configs.recommended,
	promisePlugin.configs["flat/recommended"],
	securityPlugin.configs.recommended,
	sonarjs.configs.recommended,
	regexpPlugin.configs["flat/recommended"],
	// ESLint 9.17+ has native reportUnusedDisableDirectives; this plugin
	// still works but can be removed once your project requires ESLint >=9.17.
	eslintComments.recommended,

	// ============================================================
	// ✅ CORE: TypeScript Type-Aware Linting
	//
	// Enables rules that read your tsconfig for type information.
	// Update `allowDefaultProject` with any JS config files in
	// your repo root that aren't covered by a tsconfig.
	//
	// MONOREPO NOTE (Turborepo / pnpm workspaces):
	// Keep tsconfigRootDir pointed at the repo root. ESLint's
	// projectService walks up from each file to find the nearest
	// tsconfig.json, so per-app configs (apps/web/tsconfig.json)
	// are picked up automatically. If the root tsconfig.json is a
	// base config, do NOT set "include" in it — let each workspace
	// define its own. If root-level .ts files (e.g. scripts/*.ts)
	// still get "file not covered" errors, add them to
	// allowDefaultProject below.
	// ============================================================
	{
		languageOptions: {
			parserOptions: {
				projectService: {
					allowDefaultProject: [
						"eslint.config.mjs",
						"prettier.config.mjs",
						// ADD any other root-level JS/MJS config files here
					],
				},
				tsconfigRootDir: import.meta.dirname,
			},
		},
	},

	// ============================================================
	// ⚛️ REACT (Web + Native shared)
	//
	// REMOVE this entire section if you don't use React.
	// 📦 eslint-plugin-react, eslint-plugin-react-hooks (v7+),
	//    eslint-plugin-react-you-might-not-need-an-effect
	// ============================================================
	reactPlugin.configs.flat.recommended,
	reactPlugin.configs.flat["jsx-runtime"],
	reactHooksPlugin.configs.flat.recommended,
	{
		rules: {
			// Disabled — using react/no-unstable-nested-components instead (faster)
			"react-hooks/static-components": "off",
		},
	},
	reactYouMightNotNeedAnEffect.configs.recommended,
	{
		rules: {
			// Catch nested components (faster than react-hooks/static-components)
			"react/no-unstable-nested-components": "error",

			// One component per file — keeps files focused and easy to find
			"react/no-multi-comp": ["error", { ignoreStateless: false }],
		},
	},

	// ============================================================
	// ⚛️ TANSTACK QUERY
	//
	// REMOVE if you don't use @tanstack/react-query.
	// 📦 @tanstack/eslint-plugin-query
	// ============================================================
	...tanstackQuery.configs["flat/recommended"],

	// ============================================================
	// ✅ CORE: Global Settings
	// ============================================================
	{
		settings: {
			react: {
				version: "detect", // REMOVE if not using React
			},
		},
		languageOptions: {
			globals: {
				...globals.browser,
				...globals.node,
			},
		},
	},

	// ============================================================
	// ✅ CORE: Rule Customizations
	//
	// Opinionated overrides on the base configs above.
	// ============================================================
	{
		rules: {
			// Too verbose — TypeScript already enforces immutability where needed
			"sonarjs/prefer-read-only-props": "off",

			// Too many false positives for legitimate enum/object lookups
			"security/detect-object-injection": "off",

			// Best for greenfield projects only. Causes too much churn when added
			// to existing codebases, and conflicts with ORMs (Drizzle, Prisma)
			// that return null from queries. Enable if starting fresh.
			"unicorn/no-null": "off",

			// Use typescript-eslint's deprecation check instead of sonarjs (much faster)
			"sonarjs/deprecation": "off",
			"@typescript-eslint/no-deprecated": "error",

			// Too noisy — many common abbreviations are universally understood
			// and the allowList needed to make this usable is massive
			"unicorn/prevent-abbreviations": "off",

			// Cap file length at 300 lines to encourage splitting
			"max-lines": [
				"error",
				{ max: 300, skipBlankLines: true, skipComments: true },
			],
		},
	},

	// ============================================================
	// 🛠️ PER-APP OVERRIDES
	//
	// Use this pattern to relax rules for specific apps/packages.
	// Update the file globs to match YOUR monorepo structure.
	// ============================================================
	// Example: relax multi-comp and max-lines for a web app
	// {
	// 	files: ["apps/web/**/*.tsx"],
	// 	rules: {
	// 		"react/no-multi-comp": "off",
	// 		"max-lines": "off",
	// 	},
	// },

	// ============================================================
	// 🎨 SHADCN UI COMPONENTS (generated multi-component files)
	//
	// REMOVE if you don't use ShadCN UI.
	// ShadCN generates multi-component files by design (e.g., table.tsx
	// exports Table, TableHeader, TableBody, TableRow, etc.)
	// This is part of the initial config, not a per-line suppression.
	// ============================================================
	{
		files: ["**/components/ui/**/*.tsx"],
		rules: {
			"react/no-multi-comp": "off",
			"max-lines": "off",
		},
	},

	// ============================================================
	// 🧪 TEST & CONFIG FILES — relax strict rules
	//
	// Keeps test/config files from tripping over max-lines
	// and multi-component restrictions.
	// ============================================================
	{
		files: [
			"**/*.test.ts",
			"**/*.test.tsx",
			"**/*.spec.ts",
			"**/*.spec.tsx",
			"**/*.config.*",
			"**/test/**",
		],
		rules: {
			// Tests often have long setup/assertion blocks
			"max-lines": "off",
			// Test files frequently define helper components inline
			"react/no-multi-comp": "off",
		},
	},

	// ============================================================
	// 🗃️ DRIZZLE ORM (Database files)
	//
	// REMOVE if you don't use Drizzle ORM.
	// Enforces .where() on update/delete to prevent accidental
	// full-table mutations.
	// 📦 eslint-plugin-drizzle
	// ============================================================
	{
		files: [
			// UPDATE these globs to match where your DB/repository code lives
			"**/db/**/*.ts",
			"**/*.repository.ts",
		],
		plugins: {
			drizzle,
		},
		rules: {
			"drizzle/enforce-delete-with-where": "error",
			"drizzle/enforce-update-with-where": "error",
		},
	},

	// ============================================================
	// 🦄 UNICORN CUSTOMIZATIONS
	// ============================================================
	{
		rules: {
			// Conflicts with passing named functions to .map(), .filter(), etc.
			"unicorn/no-array-callback-reference": "off",
			// Ternaries aren't always more readable than if/else
			"unicorn/prefer-ternary": "off",
			// Enforce kebab-case filenames with exceptions for framework routing
			"unicorn/filename-case": [
				"error",
				{
					cases: {
						kebabCase: true,
					},
					ignore: [
						// Expo Router dynamic routes: [param].tsx, [...catchAll].tsx
						String.raw`^\[.*\]\.tsx$`,
						// TanStack Router routes: $param.tsx, _layout.tsx
						String.raw`^\$.*\.tsx$`,
						String.raw`^_.*\.tsx$`,
						// Expo Router special files: +not-found.tsx
						String.raw`^\+.*\.tsx$`,
					],
				},
			],
		},
	},

	// ============================================================
	// 🖥️ NODE.JS (Server-side / backend code)
	//
	// REMOVE if your project is frontend-only.
	// 📦 eslint-plugin-n
	// ============================================================
	{
		files: [
			// UPDATE these globs to match your server/backend code
			"**/server/**/*.ts",
			"**/api/**/*.ts",
			"**/scripts/**/*.ts",
			"**/seed.ts",
			"**/migrate.ts",
		],
		plugins: {
			n: nodePlugin,
		},
		settings: {
			n: {
				// ESLint v10 requires Node ^20.19.0 || ^22.13.0 || >=24
				version: ">=22.13.0",
			},
		},
		rules: {
			...nodePlugin.configs["flat/recommended"].rules,
			// Handled by TypeScript / bundler resolution
			"n/no-missing-import": "off",
			// Monorepo packages aren't "published" but are valid imports
			"n/no-unpublished-import": "off",
			"n/no-unsupported-features/node-builtins": [
				"error",
				{
					// crypto is widely supported and stable
					ignores: ["crypto"],
				},
			],
		},
	},

	// ============================================================
	// 📱 REACT NATIVE
	//
	// REMOVE this entire section if you don't have a native app.
	// 📦 @react-native/eslint-config (official, replaces eslint-plugin-react-native)
	// Note: @react-native/eslint-config/flat exports an array — spread at top level
	// ============================================================
	...reactNativeConfig.map((entry) => ({
		...entry,
		files: [
			// UPDATE these globs to match your React Native app
			"**/native/**/*.tsx",
			"**/native/**/*.ts",
		],
	})),
	{
		files: [
			"**/native/**/*.tsx",
			"**/native/**/*.ts",
		],
		languageOptions: {
			globals: {
				...globals.browser,
				__DEV__: "readonly",
			},
		},
		rules: {
			// Allow inline styles (e.g. with NativeWind / Tailwind)
			"react-native/no-inline-styles": "off",
			// Colors handled by styling framework (NativeWind, etc.)
			"react-native/no-color-literals": "off",
			// Style ordering is subjective and not worth enforcing
			"react-native/sort-styles": "off",
			// Allow text in custom text-safe components
			"react-native/no-raw-text": [
				"error",
				{
					skip: [
						// ADD your custom text-wrapping component names here
						"Button",
					],
				},
			],
		},
	},

	// ============================================================
	// 🧪 VITEST (Unit / integration tests)
	//
	// REMOVE if you use a different test runner (Jest, etc.)
	// 📦 @vitest/eslint-plugin
	// ============================================================
	{
		files: ["**/*.test.ts", "**/*.test.tsx", "**/*.spec.ts", "**/*.spec.tsx"],
		plugins: {
			vitest: vitestPlugin,
		},
		rules: {
			...vitestPlugin.configs.recommended.rules,
			// Tests reuse strings for readability (e.g. repeated assertion messages)
			"sonarjs/no-duplicate-string": "off",
			// eslint-disable-next-line sonarjs/no-hardcoded-passwords -- Rule name, not a password
			// Test fixtures use fake credentials intentionally
			"sonarjs/no-hardcoded-passwords": "off",
			// Tests often need `any` for mocking and type coercion
			"@typescript-eslint/no-explicit-any": "off",
			// Vitest/Jest mocking patterns trigger unsafe type errors
			"@typescript-eslint/no-unsafe-assignment": "off",
			"@typescript-eslint/no-unsafe-member-access": "off",
			"@typescript-eslint/no-unsafe-call": "off",
			"@typescript-eslint/no-unsafe-argument": "off",
			"@typescript-eslint/no-unsafe-return": "off",
			// Test helpers sometimes use require() for dynamic mocking
			"@typescript-eslint/no-require-imports": "off",
			// Dynamic require/import is common in test setup
			"unicorn/prefer-module": "off",
		},
		languageOptions: {
			globals: {
				...vitestPlugin.environments.env.globals,
			},
		},
	},

	// ============================================================
	// 🧪 TESTING LIBRARY (React component tests)
	//
	// REMOVE if you don't use @testing-library/react.
	// 📦 eslint-plugin-testing-library
	// ============================================================
	{
		files: [
			"**/*.test.tsx",
			"**/*.spec.tsx",
			"**/test/**/*.tsx",
			"**/tests/**/*.tsx",
		],
		...testingLibrary.configs["flat/react"],
	},

	// ============================================================
	// 🧪 TEST HELPERS & SEED FILES
	// ============================================================
	{
		files: [
			"**/test/**/*.ts",
			"**/tests/**/*.ts",
			"**/seed.ts",
			"**/mock-*.ts",
		],
		rules: {
			// eslint-disable-next-line sonarjs/no-hardcoded-passwords -- Rule name, not a password
			// Seed/mock files intentionally use hardcoded credentials
			"sonarjs/no-hardcoded-passwords": "off",
			// Seed files and test utilities can be long
			"max-lines": "off",
		},
	},

	// ============================================================
	// 🎭 PLAYWRIGHT (E2E tests)
	//
	// REMOVE if you don't use Playwright.
	// 📦 eslint-plugin-playwright
	// ============================================================
	{
		files: [
			// UPDATE to match your E2E test location
			"**/e2e/**/*.ts",
			"**/e2e/**/*.tsx",
		],
		...playwrightPlugin.configs["flat/recommended"],
		rules: {
			...playwrightPlugin.configs["flat/recommended"].rules,
			// E2E tests reuse selectors and assertion strings frequently
			"sonarjs/no-duplicate-string": "off",
			// eslint-disable-next-line sonarjs/no-hardcoded-passwords -- Rule name, not a password
			// E2E test fixtures use fake credentials intentionally
			"sonarjs/no-hardcoded-passwords": "off",
			// Playwright fixtures use `use()` which triggers false positives
			"react-hooks/rules-of-hooks": "off",
		},
	},

	// ============================================================
	// ⚙️ CONFIG FILES (CommonJS, untyped APIs)
	// ============================================================
	{
		files: [
			"*.config.js",
			"*.config.mjs",
			// ADD any framework-specific config files
		],
		rules: {
			// Config files often require CommonJS for compatibility
			"unicorn/prefer-module": "off",
			"@typescript-eslint/no-require-imports": "off",
			// Config files use untyped framework APIs (bundler plugins, etc.)
			"@typescript-eslint/no-unsafe-assignment": "off",
			"@typescript-eslint/no-unsafe-member-access": "off",
			"@typescript-eslint/no-unsafe-argument": "off",
			"@typescript-eslint/no-unsafe-call": "off",
			"@typescript-eslint/no-unsafe-return": "off",
			// Config files commonly use anonymous default exports
			"unicorn/no-anonymous-default-export": "off",
		},
	},

	// ============================================================
	// 📄 JAVASCRIPT FILES (disable type-aware rules)
	// Required for mixed TS/JS repos — JS files aren't covered by tsconfig
	// ============================================================
	{
		files: ["**/*.js", "**/*.mjs", "**/*.cjs", "**/*.jsx"],
		...tseslint.configs.disableTypeChecked,
	},

	// ============================================================
	// 💅 PRETTIER (must be LAST to override formatting rules)
	// 📦 eslint-config-prettier
	// ============================================================
	prettierConfig,
);
