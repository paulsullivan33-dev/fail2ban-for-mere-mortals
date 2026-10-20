# Repeat Offenders

A two-minute ban teaches a patient bot nothing;
it waits, and knocks again. Fail2Ban has two
answers to the repeat customer, and the lab ran
both against the same stubborn test address.
This chapter is their story, told in the lab's
timestamps — because the story has a twist in
the middle that the documentation alone would
not have told us.

## Bans that grow: `bantime.increment`

Turn it on and a jail stops issuing flat
sentences. Each new offence by an address with
bans on its record is priced from its history:

```ini
bantime.increment = true
bantime.factor = 2
```

The growth is computed by a formula (the stock
default multiplies the base `bantime` by a
power of two per counted offence, scaled by
`bantime.factor`; a `bantime.maxtime` caps how
far it can grow). The settings were in the
lab's `[DEFAULT]` from the start. Here is what
they did — three offences by `192.0.2.66`,
three knocks each:

| Offence | Banned at | Released at | Time served |
|---|---|---|---|
| 1st | 21:41:58 | 21:43:07, *by hand* | (base: 120 s) |
| 2nd | 21:43:22 | 21:45:21 | **119 s — the base again** |
| 3rd | 21:46:11 | 21:54:10 | **479 s — grown** |

The third offence is where the growth shows
itself, and fail2ban announces it in its own
log, from a component called the *observer*:

```
2026-10-20 21:46:11,370 fail2ban.observer [15494]: NOTICE  [labauth] Increase Ban 192.0.2.66 (2 # 8m -> 2026-10-20 21:54:10)
```

Eight minutes promised; released at 21:54:10
on the second. But the middle row is the
chapter. The second offence — committed
minutes after the first — got the **base**
bantime again, flat. The difference between
offence two and offence three is not time or
counting of knocks. It is that offence one's
ban was **lifted by hand** (chapter 5's rescue,
performed during the lab), while offence
two's ban was left to **expire on its own** —
and only the expired ban was still on the
books when the next offence was priced. A
manual unban forgives the record as well as
the sentence. (Observed behaviour, on this
version, in this lab; it is recorded here
because it follows from something you will
actually do — unban a colleague — and because
nobody's release notes phrase it that plainly:
*hands that lift a ban early also erase its
contribution to the next one.*)

For a real sshd jail the practical reading is
simple: growth is aimed at the bot that keeps
a schedule with your door, and it works on the
history fail2ban keeps in its database (under
`/var/lib/fail2ban/`). Leave repeat offenders
to ripen; do not expect a forgiven offence to
compound.

## The jail for the jail log: recidive

The stock catalogue contains one jail whose
service is fail2ban itself. **Recidive**
watches `/var/log/fail2ban.log` with a filter
that recognises other jails' ban notices —
this is its pattern, trimmed to the idea:

```
failregex = ^...NOTICE\s+\[(?!recidive)\].*\]\s+Ban\s+<HOST>\s*$
```

(read: a `Ban` line for some address, from any
jail *except* recidive itself — it is expressly
forbidden to count its own bans, which would
compound forever). Stock recidive settings:
conviction at 5 bans inside a day, sentence a
week. The lab enabled it with its threshold
lowered to 2 and its action swapped for the
harmless lab action:

```ini
[recidive]
enabled  = true
backend  = polling
action   = lab-banfile
maxretry = 2
```

When `192.0.2.66` collected its second lab
ban, recidive struck on its own — the lab
action's record gained a line no human and no
sshd jail wrote:

```
BAN ip=192.0.2.66 jail=labauth failures=3
UNBAN ip=192.0.2.66 jail=labauth
BAN ip=192.0.2.66 jail=labauth failures=3
BAN ip=192.0.2.66 jail=recidive failures=2
```

```
$ fail2ban-client status recidive
   |- Total failed:     6
   |- Currently banned: 1
   `- Banned IP list:   192.0.2.66
```

(`Total failed: 6` in a jail whose log is the
ban log counts every ban notice it read along
the way — including other addresses' single
bans, which never reached its threshold of 2.)
On a production machine recidive's action is
the all-ports flavour of the firewall action,
so its week-long sentence closes *every* door,
not just the one that was knocked on: the
difference between "SSH ignores you" and "this
machine does not speak to you at all." That is
the correct escalation shape for an address
that has made a career of your services, and
the reason its stock threshold counts *bans*,
not knocks: the evidence has already been
judged once by the jails below it.

**Check:** growth and recidive reward the
same virtue — a memory. Verify yours is
working the way this chapter's lab did: the
observer's `Increase Ban` lines and recidive's
own bans both live in `/var/log/fail2ban.log`,
timestamped, where a `grep` can audit them.
