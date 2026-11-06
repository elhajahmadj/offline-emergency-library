#!/usr/bin/env bash
# Offline native-OS execution check for the manual reader (#158).
# Keep the version folder: Unix release archives do not unpack to a flat engine.
set -eu
cd "$(dirname "$0")/../.."
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) platform=macos-arm64 ;;
  Darwin/x86_64) platform=macos-x64 ;;
  Linux/aarch64|Linux/arm64) platform=linux-arm64 ;;
  Linux/x86_64) platform=linux-x64 ;;
  *) echo "FAIL: unsupported test host"; exit 1 ;;
esac
ROOT="$T/original library"
AO="$ROOT/AI-Offline"
mkdir -p "$AO/Manual-QA" "$AO/models" "$AO/engine/$platform/llama-b99999"
cp doc-qa/start-docs.sh "$AO/Manual-QA/start-docs.sh"
# Both installers install .command as an identical copy of .sh.
cp doc-qa/start-docs.sh "$AO/Manual-QA/start-docs.command"
printf 'fixture model\n' > "$AO/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
cat > "$AO/engine/$platform/llama-b99999/llama-server" <<'STUB'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$@" > "$OEL_DOC_ARGS"
STUB
chmod +x "$AO/engine/$platform/llama-b99999/llama-server"
mkdir "$T/moved here"
mv "$ROOT" "$T/moved here/Library copy"
ROOT="$T/moved here/Library copy"
HERE="$ROOT/AI-Offline/Manual-QA"
export OEL_DOC_ARGS="$T/actual"
printf '%s\n' -m "$HERE/../models/Llama-3.2-3B-Instruct-Q4_K_M.gguf" \
  -c 4096 -ngl 0 -t 4 --offline --host 127.0.0.1 --port 8081 --path "$HERE/../.." > "$T/expected"
for launcher in start-docs.sh start-docs.command; do
  # Launch outside the library to catch accidental dependencies on the caller's cwd.
  (cd "$T"; bash "$HERE/$launcher")
  diff -u "$T/expected" "$OEL_DOC_ARGS"
  echo "PASS: $launcher execs nested $platform engine after relocation; argv:"
  cat "$OEL_DOC_ARGS"
  rm "$OEL_DOC_ARGS"
done
