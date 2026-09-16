# SmartTube task runner. `just` lists recipes. Every recipe is safe to run from any cwd.
set shell := ["bash", "-euo", "pipefail", "-c"]

root      := justfile_directory()
workspace := root + "/SmartTube.xcworkspace"
package   := root + "/SmartTubeIOS"
derived   := env_var_or_default("SMARTTUBE_DERIVED_DATA", "/Volumes/External/tmp/DerivedData/SmartTube")
# Single source of truth for the target simulator. Override: `just sim="iPhone 17" test-ui`.
sim       := env_var_or_default("SMARTTUBE_SIM", "iPhone 17")
tv_sim    := env_var_or_default("SMARTTUBE_TV_SIM", "Apple TV")
workers   := "3"   # 16 GB Mac Mini ceiling; 5 stalls clone boot (docs/running-tests.md)

default:
    @just --list

# --- quality gates ---------------------------------------------------------
format:
    xcrun swift-format format --in-place --recursive --configuration {{root}}/.swift-format {{package}}/Sources {{package}}/Tests {{root}}/SmartTubeApp/Sources {{root}}/SmartTubeApp/UITests "{{root}}/SmartTubeApp/Smart Tube"

format-check:
    xcrun swift-format lint --strict --recursive --configuration {{root}}/.swift-format {{package}}/Sources {{package}}/Tests {{root}}/SmartTubeApp/Sources {{root}}/SmartTubeApp/UITests "{{root}}/SmartTubeApp/Smart Tube"

lint:
    cd {{root}} && swiftlint lint --strict --baseline .swiftlint.baseline --config .swiftlint.yml

lint-baseline:
    cd {{root}} && swiftlint lint --write-baseline .swiftlint.baseline --config .swiftlint.yml || true

secrets-check:
    cd {{root}} && scripts/check-no-secrets.sh

doc-links:
    cd {{root}} && scripts/check-doc-links.sh

# --- build & test ------------------------------------------------------------
build:
    xcodebuild build -workspace {{workspace}} -scheme SmartTube -destination "platform=iOS Simulator,name={{sim}}" -derivedDataPath {{derived}} CODE_SIGNING_ALLOWED=NO -quiet

build-tvos:
    xcodebuild build -workspace {{workspace}} -scheme "Smart Tube" -destination "platform=tvOS Simulator,name={{tv_sim}}" -derivedDataPath {{derived}} CODE_SIGNING_ALLOWED=NO -quiet

# Physical Apple TV only; pass the identifier from tv-devices.
tv-devices:
    xcrun devicectl list devices

check-tv-device-build:
    xcodebuild build -workspace {{workspace}} -scheme "Smart Tube" -destination 'generic/platform=tvOS' -derivedDataPath {{derived}} CODE_SIGNING_ALLOWED=NO -quiet

build-tv-device device team bundle:
    xcodebuild build -workspace {{workspace}} -scheme "Smart Tube" -destination 'platform=tvOS,id={{device}}' -derivedDataPath {{derived}} -allowProvisioningUpdates PRODUCT_BUNDLE_IDENTIFIER='{{bundle}}' DEVELOPMENT_TEAM='{{team}}' CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" PROVISIONING_PROFILE_SPECIFIER= -quiet

install-tv-device device:
    xcrun devicectl device install app --device '{{device}}' '{{derived}}/Build/Products/Debug-appletvos/Smart Tube.app'

launch-tv-device device bundle:
    xcrun devicectl device process launch --device '{{device}}' '{{bundle}}'

test-tv-device device team bundle test result:
    xcodebuild test -workspace {{workspace}} -scheme "Smart Tube" -destination 'platform=tvOS,id={{device}}' -derivedDataPath {{derived}} -allowProvisioningUpdates PRODUCT_BUNDLE_IDENTIFIER='{{bundle}}' DEVELOPMENT_TEAM='{{team}}' CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" PROVISIONING_PROFILE_SPECIFIER= -parallel-testing-enabled NO -only-testing:'SmartTubeTVUITests/{{test}}' -resultBundlePath '{{result}}' -quiet

format-file path:
    xcrun swift-format format --in-place --configuration {{root}}/.swift-format '{{path}}'

test-unit:
    cd {{package}} && swift test --parallel 2>&1 | tail -30

# filter: `just test-unit-filter HLSManifestParserTests`
test-unit-filter name:
    cd {{package}} && swift test --filter {{name}} 2>&1 | tail -40

# temporary until WS3-T3.4 adds the Smoke/Live test plans
test-ui-legacy:
    xcodebuild test -workspace {{workspace}} -scheme SmartTube -destination "platform=iOS Simulator,name={{sim}}" -derivedDataPath {{derived}} -parallel-testing-enabled YES -maximum-parallel-testing-workers {{workers}} -only-testing:SmartTubeUITests 2>&1 | tee /Volumes/External/tmp/smarttube-parallel-test.log | grep -E "Test Case|TEST SUCCEEDED|TEST FAILED|error:" | tail -40

test-smoke:
    xcodebuild test -workspace {{workspace}} -scheme SmartTube -testPlan Smoke -destination "platform=iOS Simulator,name={{sim}}" -derivedDataPath {{derived}} -parallel-testing-enabled YES -maximum-parallel-testing-workers {{workers}} -resultBundlePath /Volumes/External/tmp/smarttube-smoke.xcresult CODE_SIGNING_ALLOWED=NO 2>&1 | tee /Volumes/External/tmp/smarttube-smoke.log | grep -E "Test Case|TEST SUCCEEDED|TEST FAILED|error:" | tail -40

test-ui:
    xcodebuild test -workspace {{workspace}} -scheme SmartTube -testPlan Live -destination "platform=iOS Simulator,name={{sim}}" -derivedDataPath {{derived}} -parallel-testing-enabled YES -maximum-parallel-testing-workers {{workers}} -resultBundlePath /Volumes/External/tmp/smarttube-live.xcresult 2>&1 | tee /Volumes/External/tmp/smarttube-live.log | grep -E "Test Case|TEST SUCCEEDED|TEST FAILED|error:" | tail -60

# run one UI test: `just test-ui-one SmartTubeUITests/PlayerControlsUITests/testPlayPause`
test-ui-one id:
    xcodebuild test -workspace {{workspace}} -scheme SmartTube -destination "platform=iOS Simulator,name={{sim}}" -derivedDataPath {{derived}} -only-testing:{{id}} 2>&1 | grep -E "Test Case|TEST SUCCEEDED|TEST FAILED|error:" | tail -20

ci: secrets-check doc-links format-check lint test-unit
    @echo "CI gate passed"

# regenerate the Unreleased section of CHANGELOG.md from Conventional Commits since the last tag
changelog:
    git-cliff --config {{root}}/cliff.toml --unreleased --prepend {{root}}/CHANGELOG.md

# --- metrics (ratchet, see docs/adr/0001) -------------------------------------
metrics:
    @echo "largest files:"; find {{package}}/Sources -name '*.swift' -exec wc -l {} + | sort -rn | head -11
    @echo "AGENTS.md bytes/lines:"; wc -c -l {{root}}/AGENTS.md
    @echo "a11y literals:"; grep -rho 'accessibilityIdentifier("' --include='*.swift' {{package}}/Sources {{root}}/SmartTubeApp/Sources | wc -l
    @echo "sleep( in UITests:"; grep -rhoE '\bsleep\(' {{root}}/SmartTubeApp/UITests | wc -l
    @echo "XCTSkip:"; grep -rho 'XCTSkip' {{root}}/SmartTubeApp/UITests | wc -l
    @echo ".shared reads in Views:"; grep -rho '\.shared\b' --include='*.swift' {{package}}/Sources/SmartTubeIOS/Views | wc -l
    @echo "mirror tests:"; grep -rli 'mirror' {{package}}/Tests | wc -l
