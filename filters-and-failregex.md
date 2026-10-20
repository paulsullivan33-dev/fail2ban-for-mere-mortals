# Filters and failregex

A filter is a list of patterns that say "this
log line is a failure, and the culprit is
*here*." It is the part of fail2ban that knows
SSH from Apache, and the only part whose
mistakes convict individuals — so it is the
part you test before you trust.

## Anatomy

Open `filter.d/sshd.conf` and, past the
comments, two kinds of line do the work:

- **`failregex`** — one or more regular
  expressions. A line matching one is a
  failure. Every failregex contains **`<HOST>`**,
  a placeholder fail2ban expands into "an
  address, captured here" — the spot in the
  line where the offender's address lives.
  Patterns may also capture a user with
  `<F-USER>`, and guard parts that must *not*
  be treated as failures with `<F-NOFAIL>`.
- **The prefix machinery** — sshd's filter
  first recognises the envelope of an sshd line
  (timestamp, host, `sshd[pid]:`, an optional
  `error: PAM:` preface, the `[preauth]`
  suffix) so the failregexes can be written
  against the message alone. You see it in the
  test output below as the `Prefregex`.

The filter also carries a **date pattern**:
fail2ban must find each line's timestamp to
know whether the failure is inside `findtime`,
and different daemons write dates differently.
And the sshd filter ships several *modes*
(chapter 6) — normal, ddos, extra, aggressive —
which are really several sets of failregexes
in one file, switched by a jail setting.

You almost never write a filter from scratch.
You do, sometimes, need to prove the vendor's
filter still matches what your service
actually writes — after a version upgrade,
against a daemon configured unusually, or
when a jail sits at zero failures while the
log is visibly full of knocks. That proof has
a tool.

## `fail2ban-regex`: the rehearsal

`fail2ban-regex LOGFILE FILTER` runs a filter
against a log without banning anything, and
reports, line class by line class, what the
filter made of it. Against this guide's
ten-line sample (five `Failed password` lines,
an `Invalid user` pair, two `Accepted` lines,
one line from another daemon — it ships in
`examples/sshd-sample.log`):

```
Lines: 10 lines, 3 ignored, 6 matched, 1 missed

Failregex: 9 total
|   4) [5] ^Failed (?:<F-NOFAIL>publickey</F-NOFAIL>|\S+) for (invalid user )?<F-USER>...</F-USER> from <HOST>...
|   6) [1] ^[iI](?:llegal|nvalid) user <F-USER>...</F-USER> from <HOST>...
|  20) [1] ^(Connection (?:closed|reset)|Disconnected) ...(by|from)... <HOST>...
|  21) [2] ^Accepted \w+ ... from <HOST>...
```

(The expressions are trimmed here; the tool
prints every character.) Read the four verbs
in its vocabulary carefully, because they are
the whole diagnostic:

- **matched** (6) — a failregex hit. These
  count toward a ban. The five `Failed
  password` lines matched the main expression,
  and the `Invalid user` line matched its own —
  in normal mode, sshd's filter counts that
  line as a failure too.
- **ignored** (3) — recognised, and
  deliberately *not* a failure. The two
  `Accepted` lines matched expressions 21 (and
  the `Connection closed` line, 20), which
  exist so the filter can note a success — a
  success line is how multi-line modes know an
  address eventually got in legitimately, and
  it must never be mistaken for a failure.
- **missed** (1) — the line matched *nothing*:
  not a failure, not a known-good line, just
  not this daemon's shape. Here it is a
  `systemd-logind` line in the middle of an
  sshd sample: the correct verdict.
- Patterns 20 and 21 sit in the failregex
  table with hits, yet their lines are counted
  ignored, not matched — the markers inside
  them (`<F-NOFAIL>`, the forget/gained
  machinery) tell fail2ban these hits are
  bookkeeping, not offences. It is a small
  print worth reading once: a hit is not
  always a conviction.

A date report rides along — `[10]` lines whose
dates the default detectors could read. If
your rehearsal shows lines *missed* that
should have matched, or dates unrecognised,
you have found a filter problem on a rehearsal
stage, where the cost is embarrassment — not
in production at 3 a.m., where the cost is a
jail that never fires or one that convicts
the wrong lines.

**Check:** point `fail2ban-regex` at a slice
of your *real* log before enabling any jail
whose filter you have not watched work: your
service's failures matched, its successes
ignored, and nothing you care about missed.
