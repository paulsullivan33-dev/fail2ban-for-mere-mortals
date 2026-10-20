# Fail2Ban for Mere Mortals

Every machine on the internet gets knocked on.
Bots sweep the address ranges day and night,
trying SSH passwords — `root`, `admin`, a
thousand leaked lists — against any door that
answers. **Fail2Ban** is the bouncer who watches
the doorman's logbook: it reads the logs your
services already write, counts the failed
attempts from each address, and when one address
fails too many times in too short a while, it
tells the firewall to turn that address away for
a while. The knocking from that address stops.
The log goes quiet.

This guide teaches the bouncer's whole job: the
**jail** (one service under watch), the **filter**
(the pattern that recognises a failure), the
**action** (what a ban actually runs), and the
three numbers that decide everything — how many
failures, in how long, banned for how long. It
builds a safe lab jail that watches a pretend
log and bans into a text file, so you can watch
a complete ban happen with no risk to anything,
then walks the real `sshd` jail the same way.

A note on how this guide was verified, because
it matters more here than usual. Fail2Ban 1.0.2
was installed for real on the build machine, a
lab jail really banned a test address (three
knocks, counted and banned), the whitelist was
proven the same way, a banned address came back
for a third offence and its ban really did grow,
and a second jail — the **recidive** jail, which
watches fail2ban's own log — really did jail the
repeat offender for a week. One thing the build
machine would not do: its firewall actions were
refused by the kernel when fail2ban's own
service tried to run them, even though the same
commands work in a root shell. So the ban that
landed in a real firewall is marked
**(documented)** — and the failure itself is
captured and taught, because "the client says
banned" turning out not to mean "the firewall
is blocking" is the single most useful lesson
in this guide. `criteria.md` keeps the exact
ledger.

## What this guide covers

- [**What fail2ban is**](what-fail2ban-is.md) —
  the bouncer, what it is not, and where it
  sits next to a firewall
- [**Meet fail2ban**](meet-fail2ban.md) — the
  server, the client, and the files: which ones
  are the vendor's and which are yours
- [**Anatomy of a jail**](anatomy-of-a-jail.md) —
  a jail line by line, the three numbers, and
  where a jail reads its failures from
- [**Your first ban**](your-first-ban.md) — the
  lab: a pretend log, a harmless action, and a
  ban watched end to end
- [**Don't ban yourself**](dont-ban-yourself.md) —
  `ignoreip`, the whitelist you write before
  anything else, and getting back in
- [**The sshd jail**](the-sshd-jail.md) — the
  canonical jail, the journal versus the log
  file, and the numbers it ships with
- [**Filters and failregex**](filters-and-failregex.md) —
  what a filter actually matches, and testing
  one against a real log before trusting it
- [**Actions**](actions.md) — what runs at ban
  time, nftables and iptables, writing your own
  action, and checking the firewall afterwards
- [**The client**](the-client.md) — status,
  unbanning, manual bans, and asking a jail
  what it thinks its settings are
- [**Repeat offenders**](repeat-offenders.md) —
  bans that grow, and the recidive jail that
  watches the watcher
- [**Other jails**](other-jails.md) — the stock
  filters for web and mail services, honestly
  surveyed
- [**What fail2ban can't do**](what-fail2ban-cant-do.md) —
  the limits, and the companions that cover
  them: key-only SSH, a real firewall posture,
  rate limits
- [**Troubleshooting**](troubleshooting.md) —
  bans that don't bite, jails that won't start,
  and the lockout
- [**Glossary**](glossary.md) — the terms,
  collected in one place

## What it doesn't cover

Securing the services themselves (fail2ban
changes nothing about how SSH authenticates —
it only counts the failures), firewalls as a
subject (the companion *UFW for Mere Mortals*
covers the wall itself), centralised or
multi-machine ban sharing, and graphical
front ends. It also won't make a badly
passworded service safe; the chapter on limits
says plainly what the bouncer can and cannot
hold back.

## How to use this guide

Read the first three chapters away from the
keyboard; they are the mental model everything
else hangs on. Then build the lab in chapter 4
on a machine you can afford to experiment on —
a spare box, a VM — and watch a ban happen
where it cannot hurt anyone. Only then turn to
the `sshd` chapter and your real door, and
write your whitelist first.
