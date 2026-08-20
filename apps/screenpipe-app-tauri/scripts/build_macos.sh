#!/usr/bin/env bash
set -Eeuo pipefail

# This script intentionally delegates signing to the Tauri bundler. A bundle
# signed after the fact can leave nested binaries and resources with a
# different code-signing state, which is exactly how the microphone entitlement
# went missing in the old local-build path.

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly APP_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly BUNDLE_ROOT="${APP_ROOT}/src-tauri/target/release/bundle/macos"
readonly APP_PATH="${BUNDLE_ROOT}/screenpipe - Development.app"
readonly ENTITLEMENTS_PATH="${APP_ROOT}/src-tauri/entitlements.plist"
readonly EXPECTED_BUNDLE_ID="screenpi.pe.dev"
readonly EXPECTED_VERSION="2.6.32"
readonly EXPECTED_RUST="1.94.0"
readonly EXPECTED_BUN="1.3.10"

die() {
  echo "build_macos.sh: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_true_entitlement() {
  local plist="$1"
  local key="$2"
  /usr/bin/plutil -p "$plist" 2>/dev/null | grep -Fq "\"${key}\" => true" \
    || die "required entitlement is missing or false: ${key} (${plist})"
}

require_signed_code() {
  local path="$1"
  /usr/bin/codesign --verify --strict "$path" >/dev/null 2>&1 \
    || die "nested code is not validly signed: ${path}"
}

require_command bun
require_command rustup
require_command security
require_command codesign
require_command plutil
require_command grep
require_command find

: "${APPLE_SIGNING_IDENTITY:?APPLE_SIGNING_IDENTITY must name an installed Apple signing identity}"

rustc_path="$(rustup which rustc)"
cargo_path="$(rustup which cargo)"
[[ -x "$rustc_path" && -x "$cargo_path" ]] \
  || die "the active rustup toolchain is missing rustc or cargo"
actual_rust="$("$rustc_path" --version | awk '{print $2}')"
[[ "$actual_rust" == "$EXPECTED_RUST" ]] \
  || die "Rust ${EXPECTED_RUST} is required (found ${actual_rust})"

# Tauri invokes cargo by name. Put the verified rustup toolchain first so a
# system/Homebrew cargo cannot silently select an older compiler.
export PATH="$(dirname -- "$rustc_path"):$PATH"

actual_bun="$(bun --version)"
[[ "$actual_bun" == "$EXPECTED_BUN" ]] \
  || die "bun ${EXPECTED_BUN} is required (found ${actual_bun})"

security find-identity -v -p codesigning 2>/dev/null \
  | grep -Fq "\"${APPLE_SIGNING_IDENTITY}\"" \
  || die "APPLE_SIGNING_IDENTITY is not available in the codesigning keychain"

[[ -f "$ENTITLEMENTS_PATH" ]] || die "entitlements file not found: ${ENTITLEMENTS_PATH}"
for entitlement in \
  com.apple.security.device.audio-input \
  com.apple.security.personal-information.calendars \
  com.apple.security.automation.apple-events; do
  require_true_entitlement "$ENTITLEMENTS_PATH" "$entitlement"
done

cd "$APP_ROOT"
rm -rf "$APP_ROOT/src-tauri/target/release/bundle"

# Tauri reads APPLE_SIGNING_IDENTITY and signs the main app plus nested code
# during bundling. Keep the Development config, screenpi.pe.dev identifier,
# and Metal feature used by this local build.
APPLE_SIGNING_IDENTITY="$APPLE_SIGNING_IDENTITY" \
  bun tauri build --features metal

[[ -d "$APP_PATH" ]] || die "Tauri did not produce the expected app bundle: ${APP_PATH}"

/usr/bin/codesign --verify --deep --strict "$APP_PATH" \
  || die "codesign verification failed for ${APP_PATH}"

identity_output="$(/usr/bin/codesign -dv --verbose=4 "$APP_PATH" 2>&1 || true)"
grep -Fq "Authority=${APPLE_SIGNING_IDENTITY}" <<<"$identity_output" \
  || die "bundle was not signed by APPLE_SIGNING_IDENTITY"

readonly APP_INFO="$APP_PATH/Contents/Info.plist"
[[ -f "$APP_INFO" ]] || die "Info.plist not found in app bundle"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_INFO")"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_INFO")"
[[ "$bundle_id" == "$EXPECTED_BUNDLE_ID" ]] \
  || die "unexpected bundle identifier: ${bundle_id}"
[[ "$version" == "$EXPECTED_VERSION" ]] \
  || die "unexpected bundle version: ${version}"

readonly VERIFY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/screenpipe-signing.XXXXXX")"
trap 'rm -rf "$VERIFY_DIR"' EXIT
readonly SIGNED_ENTITLEMENTS="$VERIFY_DIR/entitlements.plist"
/usr/bin/codesign -d --entitlements :- "$APP_PATH" >"$SIGNED_ENTITLEMENTS" 2>/dev/null \
  || die "could not read signed entitlements"
for entitlement in \
  com.apple.security.device.audio-input \
  com.apple.security.personal-information.calendars \
  com.apple.security.automation.apple-events; do
  require_true_entitlement "$SIGNED_ENTITLEMENTS" "$entitlement"
done

# Verify every nested executable, dynamic library, and Metal library instead of
# relying only on --deep. The latter can report a valid outer seal while a
# resource that is executed or loaded at runtime is not independently signed.
while IFS= read -r -d '' nested; do
  require_signed_code "$nested"
done < <(
  find "$APP_PATH/Contents" -type f \( -perm -111 -o -name '*.dylib' -o -name '*.metallib' \) -print0
)

METALLIB_PATH="$APP_PATH/Contents/MacOS/mlx.metallib"
[[ -f "$METALLIB_PATH" ]] || die "mlx.metallib is missing from the signed bundle"
require_signed_code "$METALLIB_PATH"

echo "Signed macOS build verified: ${APP_PATH} (${bundle_id} ${version})"
