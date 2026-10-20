# Your First Ban

Time to watch the whole machine work, somewhere
it cannot hurt anyone. The lab has three parts:
a **pretend log** — a file in ordinary sshd
format that a small script appends fake failed
logins to; a **jail** watching that file; and a
**harmless action** — instead of touching the
firewall, it appends one line to a file in the
lab each time it bans or unbans. The filter is
the real sshd filter; the counting is the real
server; only the log is acted and the punch is
pulled.

The action, written for the lab and dropped
into `action.d/` like any other action (it
ships in this guide's `examples/`):

```ini
[Definition]
actionstart =
actionstop =
actioncheck =
actionban   = echo "BAN ip=<ip> jail=<name> failures=<failures>" >> /home/hatch/workspace/fail2ban-lab/bans.log
actionunban = echo "UNBAN ip=<ip> jail=<name>" >> /home/hatch/workspace/fail2ban-lab/bans.log
```

The `<ip>`, `<name>` and `<failures>` markers
are fail2ban's: at ban time it substitutes the
offender's address, the jail's name, and how
many failures convicted it. An action is just
commands with holes for the facts. Chapter 8
returns to what the serious actions put in
those commands.

The jail and its house rules went into
`jail.local` (the full file ships in
`examples/`):

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.0.2.99
bantime  = 2m
findtime = 10m
maxretry = 3
bantime.increment = true
bantime.factor = 2

[labauth]
enabled = true
backend = polling
filter  = sshd
logpath = /home/hatch/workspace/fail2ban-lab/work/lab-auth.log
port    = ssh
action  = lab-banfile
```

Two-minute bans and conviction at three, so
the story completes over a cup of coffee. The
configuration rehearsal passed (`fail2ban-client
-t`, chapter 2), the service started, and the
new jail reported for duty with a clean slate:

```
$ fail2ban-client status labauth
Status for the jail: labauth
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /home/hatch/workspace/fail2ban-lab/work/lab-auth.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

## Two knocks: counted, not convicted

The feeder script appends two failure lines
from the test address `192.0.2.66` (an address
from the range reserved for documentation —
nobody real will ever knock from it):

```
Oct 20 21:41:40 labhost sshd[3375]: Failed password for invalid user admin from 192.0.2.66 port 42375 ssh2
Oct 20 21:41:41 labhost sshd[3795]: Failed password for invalid user admin from 192.0.2.66 port 43769 ssh2
```

```
$ fail2ban-client status labauth
   |- Total failed:     2
   |- Currently banned: 0
```

This is the threshold doing its quiet job:
every matching line is counted (`Total failed`
only ever climbs), and nothing happens until
the count inside the window reaches `maxretry`.
One more consideration in that readout —
`Currently failed` shows 1, not 2: it counts
*addresses* currently carrying failures inside
their window, not the failures themselves.
One knocker, two knocks.

## The third knock

One more failure from `.66`, and three from
`192.0.2.99` — an address the house rules
whitelist, whose story is chapter 5. Seconds
later:

```
$ fail2ban-client status labauth
   |- Total failed:     3
   |- Currently banned: 1
   `- Banned IP list:   192.0.2.66

$ cat ~/workspace/fail2ban-lab/bans.log
BAN ip=192.0.2.66 jail=labauth failures=3
```

Three independent witnesses agree: the client's
status, the action's own record (written by the
ban itself, stamped with the convicting count),
and fail2ban's own log:

```
2026-10-20 21:41:58,032 fail2ban.actions [15494]: NOTICE  [labauth] Ban 192.0.2.66
```

Note what the counters did with `.99`: its
three failure lines are in the log — a `grep`
finds all three — yet `Total failed` says 3,
not 6. The whitelist does not forgive after the
fact; the lines were never counted at all.

**Check:** a ban you can hold in your hand —
status names the address, the action's record
shows the jail and the count, and the server's
log has the NOTICE line. Every real ban in the
later chapters is verified against the same
three witnesses, plus a fourth the lab cannot
supply: the firewall itself. Chapter 8 shows
why that fourth witness matters, and what it
said when this build asked it.
