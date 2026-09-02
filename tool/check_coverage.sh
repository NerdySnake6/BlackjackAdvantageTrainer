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

# lcov omits files no test imports, so they vanish from the denominator instead
# of scoring zero. Catch that before trusting any percentage below.
unmeasured=$(comm -23 <(find lib -name '*.dart' | sort) <(covered_files) \
             | grep -Ev "$EXCLUDE" || true)
if [ -n "$unmeasured" ]; then
  echo "FAIL unmeasured           no test imports these, so lcov cannot see them:"
  echo "$unmeasured" | sed 's/^/                           /'
fi

# Floors are a ratchet: raise them as the QA sprint lands tests, never lower.
# Sprint targets are in docs/QA_SPRINT.md section 1.
report() { # name  path-regex  floor  target
  awk -v pat="$2" -v name="$1" -v floor="$3" -v target="$4" -v ex="$EXCLUDE" '
    /^SF:/ { f = substr($0, 4); sub("^.*/lib/", "lib/", f)
             keep = (f ~ pat && f !~ ex) }
    keep && /^LF:/ { lf += substr($0, 4) }
    keep && /^LH:/ { lh += substr($0, 4) }
    END {
      pct = lf ? lh * 100 / lf : 0
      status = (pct + 0.05 < floor) ? "FAIL" : "ok"
      printf "%-4s %-22s %5.1f%% (%d/%d)  floor %s%%  target %s%%\n",
             status, name, pct, lh, lf, floor, target
      if (status == "FAIL") exit 1
    }' "$LCOV"
}

fail=0
[ -n "$unmeasured" ] && fail=1
report "domain"          '^lib/domain/'                              95  95 || fail=1
report "viewmodels+data" '^lib/(viewmodels|data|core/persistence)/'  85  85 || fail=1
report "total"           '.'                                         75  75 || fail=1
exit $fail
