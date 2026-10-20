# Writing Criteria

Every guide in this repo is written to the same
standard. If you're adding or editing a guide —
human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language,
   never dumbed-down concepts. Explain jargon on
   first use; collect terms in the glossary.
2. **No hype.** No marketing adjectives, no
   "revolutionary," no promises about what
   something will do for the reader.
3. **Honest about limits.** Say what the thing
   *can't* do. State uncertainty instead of
   smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults,
   and specs are either measured or qualified with
   "depends on your setup." If it wasn't tested,
   say so.
5. **Checkable.** Commands are meant to be run,
   with "Check:" blocks showing what success looks
   like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out
   Windows/Mac/Linux differences. Don't assume a
   GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get
   stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and
   points elsewhere for the rest. No guide
   pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after
   examples, symptom → fix. Scannable beats essay.

## Verification notes for this guide

Standard 3 and 4 applied to this guide,
specifically. The lab ran on the build machine
with **Fail2Ban 1.0.2** (Ubuntu package
1.0.2-3ubuntu0.1) under a real systemd. The lab
jail watched a planted fixture log (sshd-format
lines appended by a script kept in the lab) and
banned into a custom action that appends to a
lab file, so no lab ban could touch the real
firewall. All transcripts are kept with the lab
(`fail2ban-lab/transcripts/`, 16 files); the
chapters quote them trimmed but unaltered.

**Run for real, captured:**

- *Inventory.* `fail2ban-client --version`
  (1.0.2); the stock `/etc/fail2ban` tree (95
  filters, 64 actions); Ubuntu's
  `jail.d/defaults-debian.conf` verbatim
  (banaction = nftables, backend = systemd,
  sshd enabled); the service inactive before
  the lab, `fail2ban-client ping` answered by
  the socket error.
- *Kernel probes.* An iptables multiport rule
  refused, exit 4 ("Extension multiport
  revision 0 not supported, missing kernel
  module?"), the same wall the UFW guide hit.
  The same machine's `nft` accepted, listed,
  and deleted a table/chain/set/element of
  exactly the shape fail2ban's nftables action
  builds — *when run from a root shell* (see
  the failure below).
- *`fail2ban-regex`* against the shipped
  10-line sample: 6 matched (5 `Failed
  password`, 1 `Invalid user`), 3 ignored (2
  `Accepted`, 1 `Connection closed`), 1 missed
  (a systemd-logind line), with the full
  pattern table and date report.
- *Configuration.* The lab `jail.local` and
  custom `action.d/lab-banfile.conf` written,
  `fail2ban-client -t` passed; a planted typo
  in a `jail.d` file made `-t` fail with the
  file and line named, exit 255; typo removed.
- *Startup.* `systemctl start fail2ban`;
  `ping` → pong; `status` listed 4 jails
  (labauth, labnft, recidive, sshd); per-jail
  status showed the lab files as `File list`
  and sshd's `Journal matches:
  _SYSTEMD_UNIT=sshd.service + _COMM=sshd`.
- *The ban.* Two appended failures from
  192.0.2.66: counted (`Total failed: 2`), no
  ban. A third: banned within seconds. Three
  witnesses — `status labauth` (Banned IP
  list), the action's own record (`BAN
  ip=192.0.2.66 jail=labauth failures=3`), and
  the NOTICE line in `/var/log/fail2ban.log`.
  `Currently failed` read as addresses, not
  failures (1 address, 2 knocks).
- *The whitelist.* Three failures from
  192.0.2.99 (in `ignoreip`): present in the
  log, never counted (`Total failed` stayed
  3), never banned.
- *Unban and manual ban.* `set labauth
  unbanip` released the test address (action
  record gained the UNBAN line); `set labauth
  banip 203.0.113.200` banned with the action
  record showing `failures=0`.
- *Reading settings back.* `get maxretry /
  findtime / bantime / ignoreip / actions`
  against live jails — including the sshd jail
  answering the lab `[DEFAULT]`'s numbers
  (3 / 120) instead of the stock ones
  (5 / 600), proving the .local DEFAULT's
  reach; `get sshd actions` → nftables.
- *Growth, with its twist.* Offence 1 banned
  120 s (base; lifted early by hand). Offence
  2, after that manual unban: banned 21:43:22,
  released 21:45:21 — 119 s, the base again, no
  `Increase Ban` line. Offence 3, after offence
  2 expired naturally: the observer logged
  `Increase Ban 192.0.2.66 (2 # 8m ->
  2026-10-20 21:54:10)`, and the release came
  at 21:54:10 — 479 s served. The database
  (`/var/lib/fail2ban/fail2ban.sqlite3`) showed
  the jail's base bantime (120) throughout:
  the grown duration is evidenced by the
  observer's line and the observed release,
  not by a changed base value.
- *Recidive.* Enabled with maxretry 2 and the
  lab action: on the second labauth ban it
  banned 192.0.2.66 itself (`BAN ip=192.0.2.66
  jail=recidive failures=2`), database row
  bantime 604800 (the stock week).
- *The action failure.* The second lab jail,
  `labnft`, ran the **real** nftables action
  (no override). It counted, convicted, and
  `status` reported the ban — while the
  action's commands were refused: the log
  shows the `nft add table inet f2b-table …`
  block answered by `Operation not permitted`
  and `Failed to execute ban jail 'labnft'
  action 'nftables'`, and `nft list ruleset`
  stayed empty. Cause, evidenced in
  transcript 10b: the fail2ban server process
  runs with a smaller effective capability set
  than a root shell on this machine (CapEff
  read from `/proc` for both), so the netlink
  door is shut to the service though it opened
  to the shell in the probes. Chapter 8 is
  written around exactly this evidence.

**Documented-only (not run), and why:**

- *A ban landing in a real firewall on this
  stack* — the nftables set entry an ordinary
  server would show in `nft list ruleset`.
  Not obtainable here: the service-side
  capability refusal above. The chapter marks
  it documented and teaches the verification
  (check the firewall; grep the log for
  action ERRORs) that the failure motivated.
- *The sshd jail catching a real attacker* —
  this box runs no SSH service and its journal
  holds no sshd entries; the jail is captured
  running and watching a dry well, and the
  counting it would do is proven against the
  identical filter in the lab jail.
- *The non-sshd stock jails of chapter 11* —
  surveyed from their installed filters and
  jail sections, not exercised; the chapter
  says so and prescribes the fail2ban-regex
  rehearsal before enabling any of them.
- *Mail-reporting and third-party actions*
  (abuseipdb, cloudflare, blocklist.de) —
  named from the stock `action.d/` shelf;
  none was run, none sends anything from a
  lab.
- *Other distributions and other init
  arrangements* — Ubuntu's drop-ins are quoted
  because they were installed here; Fedora /
  Arch paths files exist in the tree and are
  named, not walked.

Sandbox state after the build, for the record:
service stopped, the lab's `jail.local` and
custom action removed, the planted typo long
gone, `/var/log/fail2ban.log` truncated back to
the empty file the package left, the runtime
database removed, `nft list ruleset` empty,
and `fail2ban-client ping` back to its socket
error. The fail2ban package itself remains
installed, stock.
