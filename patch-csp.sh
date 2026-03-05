#\!/bin/bash
# Patch OpenClaw dist CSP headers to allow external resources
# Run after openclaw updates to re-apply CSP fixes
#
# Adds:
#   script-src: https://static.cloudflareinsights.com
#   style-src:  https://fonts.googleapis.com
#   font-src:   https://fonts.gstatic.com

DIST_DIR="$HOME/openclaw-src/dist"
PATCHED=0

for f in "$DIST_DIR"/gateway-cli-*.js; do
  [ -f "$f" ] || continue

  if grep -q "\"script-src 'self'\"" "$f"; then
    python3 -c "
import pathlib, sys
f = pathlib.Path(sys.argv[1])
t = f.read_text()
t = t.replace(\"\\\"script-src 'self'\\\"\", \"\\\"script-src 'self' https://static.cloudflareinsights.com\\\"\")
t = t.replace(\"\\\"style-src 'self' 'unsafe-inline'\\\"\", \"\\\"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com\\\"\")
t = t.replace(\"\\\"font-src 'self'\\\"\", \"\\\"font-src 'self' https://fonts.gstatic.com\\\"\")
f.write_text(t)
" "$f"
    echo "Patched: $(basename "$f")"
    PATCHED=$((PATCHED + 1))
  else
    echo "Already patched: $(basename "$f")"
  fi
done

if [ "$PATCHED" -gt 0 ]; then
  echo "Restarting openclaw-gateway..."
  systemctl --user restart openclaw-gateway
  echo "Done. $PATCHED file(s) patched."
else
  echo "No files needed patching."
fi
