# Don't Ban Yourself

Every fail2ban story has the same second act:
the administrator, mid-debugging, mistypes a
password a few times too often — and the door
they are standing at locks against the address
they are standing behind. This is not a flaw in
the bouncer. It is the bouncer working exactly
as told, on someone who forgot to tell it who
the staff are.

## `ignoreip`: the staff list

**`ignoreip`** is the list of addresses and
networks a jail will never ban, and it is
checked before counting even starts. The lab
file put it in `[DEFAULT]`, so every jail
inherited it:

```ini
ignoreip = 127.0.0.1/8 ::1 192.0.2.99
```

Loopback is on the stock list already — the
machine cannot ban itself out of its own
services. What you add, first, before the jail
ever runs, is **where you administer from**:
your home address if it is stable, your
office network, the jump host you come through.
Ask the running server what any jail thinks
the list is:

```
$ fail2ban-client get labauth ignoreip
These IP addresses/networks are ignored:
|- 127.0.0.0/8
|- 192.0.2.99
`- ::1
```

Chapter 4 already proved the list works the
strong way. The whitelisted `.99` knocked three
times — enough to convict anyone else — and the
jail's `Total failed` did not move: its lines
were in the log, and they were never counted.
Whitelisting is not a pardon issued at ban
time; it is the bouncer not writing your name
in the book at all.

Two disciplines make the list trustworthy:

- **Whitelist networks you control, as narrowly
  as you can.** A whole ISP's range is not a
  staff list; it is a hole in the shape of
  everyone on that ISP. A single address or a
  small subnet is the honest size.
- **Write it before you need it.** The time to
  learn your admin address is banned is never;
  the time to write it down is at installation,
  in the same sitting as enabling the jail.

## When it happens anyway

You will still, someday, ban an address you
need — a colleague's, a monitoring server's,
your own from a new connection. The recovery
is one command, and the lab ran it for real on
its convicted test address:

```
$ fail2ban-client set labauth unbanip 192.0.2.66
1

$ grep Unban /var/log/fail2ban.log
2026-10-20 21:43:07,621 fail2ban.actions [15494]: NOTICE  [labauth] Unban 192.0.2.66
```

The `1` is the count of addresses released.
The action runs its unban half — the lab's
record gained an `UNBAN ip=192.0.2.66
jail=labauth` line, symmetric with the ban —
and the jail's banned list is empty again.

Two honest footnotes to that rescue. If the
address you are locked out *from* is your only
way in, the command above must be run from
somewhere else — a console, a second network,
a phone hotspot — which is a reason the
whitelist is written in advance rather than
an apology written after. And a manual unban
is also a **forgiveness with a memory hole**:
in chapter 10's lab run, the address whose
first ban was lifted by hand offended again
and was treated as a first offender — the
repeat-offender growth counted only the bans
still on the books. Unban your friends freely;
know that you are also wiping their record.

**Check:** before any jail goes live on a real
service, `fail2ban-client get <jail> ignoreip`
shows your own admin addresses on the list —
and chapter 4's experiment is the proof shape
to trust: knocks from a whitelisted address do
not even move the counters.
