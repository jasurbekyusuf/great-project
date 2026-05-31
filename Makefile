.PHONY: help get clean analyze format fix test test-coverage coverage-html \
        build-runner watch run run-fake run-live build-apk build-aab \
        hooks-install

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---- Setup ------------------------------------------------------------------
get: ## flutter pub get
	flutter pub get

clean: ## flutter clean + remove .dart_tool
	flutter clean
	rm -rf .dart_tool build coverage

hooks-install: ## Install lefthook pre-commit hooks
	lefthook install

# ---- Quality ---------------------------------------------------------------
analyze: ## Static analysis (very_good_analysis + custom)
	flutter analyze --fatal-infos --fatal-warnings

format: ## Format with line-length 100
	dart format --line-length=100 lib test

fix: ## Auto-fix lints via `dart fix --apply`
	dart fix --apply

# ---- Tests -----------------------------------------------------------------
test: ## Run unit + widget tests
	flutter test

test-coverage: ## Run tests with coverage report
	flutter test --coverage
	@echo "Coverage report → coverage/lcov.info"

coverage-html: test-coverage ## Generate HTML coverage report (requires `lcov` installed)
	genhtml coverage/lcov.info -o coverage/html
	@echo "Open coverage/html/index.html"

# ---- Codegen ---------------------------------------------------------------
build-runner: ## One-shot codegen (freezed, json_serializable, riverpod_generator)
	dart run build_runner build --delete-conflicting-outputs

watch: ## Continuous codegen
	dart run build_runner watch --delete-conflicting-outputs

# ---- Run -------------------------------------------------------------------
run: ## flutter run (default device)
	flutter run

run-fake: ## Run with fake data (default)
	flutter run --dart-define=USE_FAKE_DATA=true

run-live: ## Run hitting the live API
	flutter run --dart-define=USE_FAKE_DATA=false

# ---- Release ---------------------------------------------------------------
build-apk: ## Build release APK (live API)
	flutter build apk --release --dart-define=USE_FAKE_DATA=false

build-aab: ## Build release App Bundle (live API)
	flutter build appbundle --release --dart-define=USE_FAKE_DATA=false
