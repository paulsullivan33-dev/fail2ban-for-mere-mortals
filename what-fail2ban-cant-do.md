# What Fail2Ban Can't Do

A bouncer with a logbook is a genuinely useful
creature, and this chapter exists so that the
previous eleven do not oversell him. Every
limit below follows from the design in chapter
1 — he reads logs, counts per address, and
acts after the fact — and each has an honest
companion that covers the gap.

## The attempts below the threshold get through

Fail2Ban convicts at `maxretry` failures inside
`findtime`. An attacker who tries four passwords
an hour, forever, against a jail set to five in
ten minutes, is never convicted — and with
botnets, "an attacker" can be a thousand
addresses each trying twice a day: two thousand
guesses a day, zero bans, nothing in the log
but weather. Slow and distributed guessing is
simply under the bouncer's eyes. What actually
holds that back is the password's strength and,
better, there being **no password to guess**:
key-only SSH (disable password authentication
once keys work — the sshd filter's own header
says this in so many words) removes the entire
game for SSH. Fail2Ban then guards a door that
no longer opens with a guess, and its bans
become housekeeping rather than a load-bearing
wall.

## Valid credentials walk straight past

The filter recognises *failures*. A login with
the right password — phished, leaked, reused
from another breach — is an `Accepted` line,
and chapter 7 showed what the filter does with
those: it files them under *ignored*. No jail
protects an account whose password is known.
The companions are the unglamorous ones: unique
passwords, a password manager, second factors
where the service supports them, and attention
to the `Accepted` lines from places you do not
recognise — a human reading the log, which is
the one job the bouncer was never hired for.

## Services that do not log failures cannot be watched

No log line, no failure; no failure, no ban.
A service that fails silently, logs to a place
no jail reads, or logs without the offender's
address gives fail2ban nothing to count. This
is also why the backend question in chapters 3
and 6 — journal or file, and is it the one
*your* daemon writes — decides whether a jail
is a control or a decoration.

## The ban is a pause, not a wall

Bans expire; addresses are cheap; the botnet
has more. A ban list is not an access policy
and does not substitute for one. The standing
posture — which services are reachable from
the internet at all, from where, on which
ports — is the firewall's subject (the
companion *UFW for Mere Mortals*), and the
strongest version of "the bot cannot knock" is
that the service is not exposed: a management
interface reachable only from your network or
through a VPN has no public log for the
bouncer to watch because there are no public
knocks.

## Collateral is real

An address is not a person. Behind one public
address there can be an office, a dormitory, a
carrier's worth of phones. A ban aimed at one
guessing script can lock out everyone sharing
that address — including, on the day you
administer from a café, you (chapter 5).
Aggressive settings multiply this. It is the
practical reason the stock numbers are modest
and why chapter 6 warned against twitchy and
vindictive in the same jail.

## What it is for, restated

Fail2Ban removes the *noise floor*: the
constant, high-rate, single-source guessing
that fills logs and — left alone — eventually
finds the one weak password someone set in
2019. It does that one thing well, cheaply,
and observably. Paired with key-only
authentication, a real firewall posture, and
logs a human glances at, it is a sound layer.
Asked to be the only layer, it is a bouncer
told to be a vault door, and this guide will
not pretend he is.

**Check:** read your own setup against the
four gaps — slow guessing, valid credentials,
silent services, expiring bans — and for each
one, name the companion that covers it. Where
the answer is "fail2ban," look again.
