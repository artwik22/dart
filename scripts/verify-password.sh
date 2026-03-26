#!/bin/sh
# Verify current user's password. Reads password from stdin.
# Exits 0 on success, non-zero on failure.
# Uses: sudo -S (reads password from stdin), or Python PAM if python3-pam is available.

if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import os, sys
try:
    import pam
    p = sys.stdin.readline().rstrip('\n')
    u = os.environ.get('USER', '')
    sys.exit(0 if u and pam.authenticate(u, p) else 1)
except Exception:
    sys.exit(1)
" 2>/dev/null
    exit $?
fi
# Fallback: sudo -S true (works when user has passwordless sudo or we pass password)
sudo -S true 2>/dev/null
exit $?
