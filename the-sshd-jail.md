# The sshd Jail

Everything so far was rehearsal. This chapter
is the jail nearly everyone actually runs: the
one watching SSH, the internet's favourite
door. On Ubuntu it starts in an unusually good
position — the package already enables it, with
sane parts already chosen — so this chapter is
mostly about *knowing what you already have*
and adjusting the few things worth adjusting.

## What the stock jail is

From `jail.conf`, the vendor's definition
(which you never edit):

```ini
[sshd]
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
```

The `%(...)s` names are filled in by the
`paths-*.conf` files for your distribution,
and Ubuntu's drop-in from chapter 2 overrides
the personality that matters most: `banaction
= nftables`, `backend = systemd`, and
`enabled = true`. So the running jail on this
machine watches the **journal**, not a file:

```
$ fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:   _SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

`Journal matches` is the jail telling you its
backend in plain sight: it reads journal
entries from the `sshd.service` unit and the
`sshd` command. On a distribution whose sshd
logs to `/var/log/auth.log` instead, the same
jail definition resolves `logpath` to that
file and the status shows a `File list`. Same
jail, two wells — and "which well is mine
drawing from" is answered by the status
output, not by documentation for some other
distribution. **(Documented:** this build
machine runs no SSH service and its journal
holds no sshd entries at all — the jail above
is genuinely running and genuinely watching an
empty well, and chapter 13 lists the symptom
this produces on a real machine: a healthy
jail, zero failures, while the knocking goes
unlogged because sshd is writing somewhere
else. The lab jail of chapter 4 exists
precisely so the counting could be proven
against a well with water in it.**)**

## The numbers it ships with, and the ones to change

Stock, from `jail.conf`'s `[DEFAULT]`:
`maxretry = 5`, `findtime = 10m`, `bantime =
10m`. Those are reasonable for a door a human
also uses. What most people legitimately tune,
in `jail.local`, under the jail's own heading
(preferring per-jail settings over `[DEFAULT]`
ones, per chapter 3's warning):

```ini
[sshd]
# keep the stock enablement; make repeat visits expensive
bantime = 1h
maxretry = 5
```

Longer bans are the commonest honest tune:
ten minutes barely inconveniences a botnet
that rotates patience by the hour, while a
human who trips the jail is usually back within
one support message anyway. What not to do is
reach for `maxretry = 2` and year-long bans in
the same sitting — twitchy *and* vindictive is
how colleagues get locked out until Thursday.

The filter has one more knob worth knowing:
**mode**. The sshd filter ships in flavours —
`normal` (the default: password and publickey
failures), `ddos` (connection churn), `extra`,
and `aggressive` (all of them) — selected in
the jail:

```ini
[sshd]
mode = aggressive
```

Chapter 7 shows what those patterns actually
match; the short version is that `normal`
covers the password guessing this guide is
about, and the wider modes count pre-auth
noise that may or may not be how your
attackers behave. Wider is not automatically
better: every extra pattern is a new way for
an innocent line to count against a real user.

## The checklist this chapter leaves behind

1. `fail2ban-client status sshd` — the jail
   exists, and its Filter section names a well
   (journal match or file) that matches where
   *your* sshd actually writes.
2. `fail2ban-client get sshd ignoreip` — your
   admin addresses are on the staff list
   (chapter 5).
3. `fail2ban-client get sshd actions` — the
   ban action is the one your firewall stack
   expects (chapter 8), and after the first
   real ban, the firewall itself — not just
   the client — shows the address blocked.

**Check:** on this build machine the first two
answers were captured live (journal matches,
the ignoreip list, `nftables` as the action).
The third is where the build machine's story
turns instructive, and it gets a chapter of
its own.
