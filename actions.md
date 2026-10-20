# Actions

The filter decides *who* and the numbers decide
*when*; the **action** is what physically
happens in the moment of the ban. An action is
a small file in `action.d/` holding shell
commands for five occasions — start, stop,
check, **ban**, **unban** — with placeholders
(`<ip>`, `<port>`, `<protocol>`, and friends)
that fail2ban fills in. The lab's action filled
them into an `echo` and a text file. Real
actions fill them into firewall commands.

## The two firewall actions you will meet

- **`iptables-multiport`** — the long-standing
  default upstream. It builds a dedicated chain
  per jail and inserts a rule that drops the
  banned address on the jail's ports. On
  present-day Ubuntu this is *not* the default,
  whatever older guides say: chapter 2's
  drop-in sets `banaction = nftables`.
- **`nftables`** — the modern action, and this
  distribution's choice. It maintains one table
  (`inet f2b-table`), one chain hooked into the
  input path, and a **set** of banned addresses
  per jail; banning is adding the address to
  the set, unbanning is removing it. The server
  confirms the choice if you ask any jail:

  ```
  $ fail2ban-client get sshd actions
  The jail sshd has the following actions:
  nftables
  ```

The `action.d/` shelf holds far more than
firewalls — mail-sending actions (the stock
`action_mw`/`action_mwl` variants ban *and*
write to you about it, log excerpt included),
abuse-report actions, cloud-firewall actions —
but they compose around the same five occasions,
and the firewall action is the one carrying the
actual sentence. Email is a notification; the
set is the punishment.

## Writing your own action

The lab's `lab-banfile` (chapter 4, shipped in
`examples/`) is the honest minimum: empty
start/stop/check, a ban command, an unban
command. Real custom actions earn their keep
at the edges — feeding a ban to some other
system, logging to a place the team watches.
Keep them as boring as the lab's: an action
runs as root, at ban time, from a daemon; clever
is how it breaks. And remember the file
etiquette from chapter 2 — your action goes in
as its own file, or as a `.local` sibling of a
stock one, never as an edit to a stock file.

## The lesson this build learned the hard way

Here is where this guide must show you a scar,
because the lab produced a perfect,
well-documented *failure* and the failure is
the lesson.

The lab ran a second jail, `labnft`, identical
to the first but with **no action override** —
so its bans ran the real nftables action. A
test address knocked three times. Everything
announced success:

```
$ fail2ban-client status labnft
   |- Currently banned: 1
   `- Banned IP list:   203.0.113.77
```

…and fail2ban's own log contained, at the same
second, this:

```
2026-10-20 21:44:03,343 fail2ban.utils [15494]: ERROR   ... exec: nft add table inet f2b-table
nft add chain inet f2b-table f2b-chain { type filter hook input priority -1 ; }
...
2026-10-20 21:44:03,343 fail2ban.utils [15494]: ERROR   ... stderr: 'Error: Could not process rule: Operation not permitted'
2026-10-20 21:44:03,344 fail2ban.actions [15494]: ERROR   Failed to execute ban jail 'labnft' action 'nftables' ... 'Script error'
```

…and `nft list ruleset` showed **nothing at
all**. On this build machine, the fail2ban
*service* runs with a smaller set of kernel
capabilities than a root shell gets — the same
`nft` commands the service was refused had
succeeded minutes earlier, typed by hand, in
transcript 02 of the lab — so the netlink door
the action knocks on stayed shut. **(The
resulting state is the documented part: on an
ordinary server, where the service holds the
capabilities its unit asks for, the same ban
puts the address into `addr-set-<jail>` in
`inet f2b-table`, and `nft list ruleset` shows
it there. What is captured here, for real, is
the failure mode and how to catch it.)**

Strip away the sandbox and the shape of the
lesson is universal, because every system has
some version of it — a firewalld that is not
running, an iptables action on an nftables
host, a cloud firewall the credentials expired
for:

1. **The client's "banned" is bookkeeping.**
   It proves the filter counted and the server
   decided. It does not prove a packet was ever
   refused.
2. **The server's log is where actions report.**
   After any jail's first ban, grep
   `/var/log/fail2ban.log` for `ERROR`. A failed
   action logs loudly and the ban carries on
   regardless — quietly, in every other respect.
3. **The firewall is the fourth witness.**
   After the first real ban, look at the
   firewall itself (`nft list ruleset`, or your
   stack's equivalent) and find the address
   there. Three witnesses said "banned" in the
   lab; only the fourth was telling the truth
   about the door.

**Check:** for each jail you run, once, after
its first ban: the address present in the
firewall's own listing, and no `ERROR` lines
from the action in fail2ban's log. That is the
difference between running fail2ban and merely
running its bookkeeping.
