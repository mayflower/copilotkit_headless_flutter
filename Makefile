SHELL := /bin/bash

.PHONY: \
	quality \
	package-check \
	example-check \
	format-check \
	analyze \
	test \
	coverage \
	docs-check \
	example-analyze \
	example-test \
	markdownlint \
	workflow-lint \
	workflow-security \
	secret-scan \
	pub-outdated \
	pana \
	tooling-check

quality: package-check example-check markdownlint workflow-lint workflow-security secret-scan

package-check: format-check analyze test docs-check

example-check: example-analyze example-test

format-check:
	dart format --set-exit-if-changed .

analyze:
	flutter analyze

test:
	flutter test

coverage:
	flutter test --coverage

docs-check:
	dart doc --dry-run .

example-analyze:
	cd example && flutter analyze

example-test:
	cd example && flutter test

markdownlint:
	npx --yes markdownlint-cli2

workflow-lint:
	actionlint

workflow-security:
	zizmor .github/workflows

secret-scan:
	gitleaks detect --source . --redact --no-git

pub-outdated:
	flutter pub outdated

pana:
	dart pub global activate pana
	tmp_dir="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	mkdir -p "$$tmp_dir/package"; \
	tar \
		--exclude='./.git' \
		--exclude='./.dart_tool' \
		--exclude='./build' \
		--exclude='./coverage' \
		--exclude='./example/.dart_tool' \
		--exclude='./example/build' \
		-cf - . | tar -xf - -C "$$tmp_dir/package"; \
	dart pub global run pana "$$tmp_dir/package"

tooling-check:
	@command -v actionlint >/dev/null || echo "Missing: actionlint"
	@command -v zizmor >/dev/null || echo "Missing: zizmor"
	@command -v gitleaks >/dev/null || echo "Missing: gitleaks"
	@command -v npx >/dev/null || echo "Missing: npx"
