#!/usr/bin/env bash
# Coverage gate over coverage/lcov.info. Run after: flutter test --coverage
#
# Generated and bootstrap files are excluded from the denominator: they are not
# hand-written logic and l10n alone is 171 lines no unit test reaches.
set -euo pipefail

LCOV="${1:-coverage/lcov.info}"
[ -f "$LCOV" ] || { echo "missing $LCOV; run: flutter test --coverage" >&2; exit 1; }

# progress_repository.dart is a bare interface: no executable lines, so lcov
# never emits it and the unmeasured check below would flag it forever.
EXCLUDE='^lib/(l10n/|firebase_options[.]dart$|main[.]dart$|core/persistence/progress_repository[.]dart$)'

covered_files() { sed -n 's|^SF:||p' "$LCOV" | sed 's|^.*/lib/|lib/|' | sort -u; }

# Check for files without test imports.
# Domain files strictly fail if unmeasured; UI/other files output an informational warning.
unmeasured=$(comm -23 <(find lib -name '*.dart' | sort) <(covered_files) \
             | grep -Ev "$EXCLUDE" || true)

fail=0

if [ -n "$unmeasured" ]; then
  unmeasured_domain=$(echo "$unmeasured" | grep '^lib/domain/' || true)
  if [ -n "$unmeasured_domain" ]; then
    echo "FAIL unmeasured domain: no test imports these critical domain files:"
    echo "$unmeasured_domain" | sed 's/^/                           /'
    fail=1
  fi

  unmeasured_other=$(echo "$unmeasured" | grep -v '^lib/domain/' || true)
  if [ -n "$unmeasured_other" ]; then
    echo "WARN unmeasured other (non-blocking):"
    echo "$unmeasured_other" | sed 's/^/                           /'
  fi
fi

# Domain coverage is strictly enforced (fail if below floor).
# viewmodels+data and total are informational to allow rapid UI prototyping.
report() { # name  path-regex  floor  target  strict
  local is_strict="${5:-false}"
  awk -v pat="$2" -v name="$1" -v floor="$3" -v target="$4" -v ex="$EXCLUDE" -v strict="$is_strict" '
    /^SF:/ { f = substr($0, 4); sub("^.*/lib/", "lib/", f)
             keep = (f ~ pat && f !~ ex) }
    keep && /^LF:/ { lf += substr($0, 4) }
    keep && /^LH:/ { lh += substr($0, 4) }
    END {
      pct = lf ? lh * 100 / lf : 0
      passed = (pct + 0.05 >= floor)
      status = passed ? "ok" : (strict == "true" ? "FAIL" : "info")
      printf "%-4s %-22s %5.1f%% (%d/%d)  floor %s%%  target %s%%\n",
             status, name, pct, lh, lf, floor, target
      if (!passed && strict == "true") exit 1
    }' "$LCOV"
}

# Strict check for pure-Dart math & engine (failure blocks CI):
report "domain (strict)"          '^lib/domain/'                              95  95 true || fail=1

# Informational tracking for app layers (does not block CI):
report "viewmodels+data (info)"   '^lib/(viewmodels|data|core/persistence)/'  85  85 false || true
report "total (info)"             '.'                                         75  75 false || true

exit $fail
