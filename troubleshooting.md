# Troubleshooting

Symptom → fix, every entry traceable to
something this guide's build actually produced
or configured. Start at the client error,
which sorts most of the field before it starts.

## The client prints a socket error

```
ERROR   Failed to access socket path: /var/run/fail2ban/fail2ban.sock. Is fail2ban running?
```

**Fix:** the server is not running, and the
client has nothing to talk to. `systemctl
status fail2ban` for the state; `systemctl
start fail2ban` for the remedy; the service's
own log (`journalctl -u fail2ban`, and
`/var/log/fail2ban.log`) for why it stopped.
A configuration that fails its rehearsal is
the commonest reason — which is what the next
entry is for.

## The server will not start after an edit

**Fix:** `fail2ban-client -t` before anything
else. It names the file and the offending line
(the lab's planted typo was caught at line 3 of
a `jail.d` file, with the server never
involved). Check edits to stock files, too:
if `jail.conf` or a stock filter was edited
directly, diff it against the package's
version — the repair is to move the change
into the `.local` file where it belonged.

## A jail is missing from `fail2ban-client status`

The jail is not running. Causes, in order:
`enabled = true` missing or misspelled in every
file that was supposed to carry it; the
section heading does not match the name you
are asking about; or the whole configuration
failed (above) and no jails started. `status`
lists what *is* running — believe it over the
files you remember writing.

## The jail runs, but `Total failed` never moves

The filter is counting nothing. Work the
evidence in chapter order:

1. **Wrong well.** `status <jail>` shows what
   the jail reads — a `File list` path or a
   `Journal matches` pattern. Confirm the
   service actually writes its failures
   *there*. A syslog-logging sshd behind a
   journal-expecting jail is this era's classic
   (chapter 6).
2. **Wrong shape.** The failures land, but in
   a dialect the filter does not recognise.
   `fail2ban-regex` against the real log
   (chapter 7) shows matched/ignored/missed
   per line — the answer is in the missed
   column and the date report.
3. **Nothing is knocking** in the window you
   are watching. Rarely the answer on an
   internet-facing box, and the only one of
   the three you should accept without the
   other two checked.

## Failures count, but nobody is ever banned

`Total failed` climbs, `Currently failed`
hovers below `maxretry`, `Currently banned`
stays at zero. The counting is healthy and the
threshold is never met inside the window:
knocks too slow for `findtime`, spread across
too many addresses (chapter 12's weather), or
— check this one before touching the numbers —
the knocks are coming from an **ignoreip**
address, in which case the fix is to notice
that it is your own monitoring box.

## The status says banned and the packets still arrive

The lab's signature failure (chapter 8): the
client and the log pronounce a ban while the
firewall holds nothing. `grep ERROR
/var/log/fail2ban.log` around the ban's second
shows the action's own report — a firewall
that is down, a backend mismatch (an iptables
action on a host whose stack is nftables, or
the reverse), or a service without the
capabilities its actions need. The fix is in
the action's error, not the jail's settings;
after fixing it, `unbanip` and let the next
offence re-run the action, or test with a
manual `banip` (chapter 9).

## You have banned yourself

Chapter 5's whole subject. Unban from any
other foothold (console, another network) with
`fail2ban-client set <jail> unbanip <your
address>`, then put the address in `ignoreip`
before you leave. If there is no other
foothold, the ban expires on its own — the
strongest argument for keeping `bantime` on
new jails short enough to wait out.

## A banned address keeps coming back the second its ban lifts

Not a malfunction — a repeat customer.
Chapter 10: `bantime.increment` so each return
costs more time, and the recidive jail so a
career of small offences adds up to a long one.
Check the observer's `Increase Ban` lines in
`/var/log/fail2ban.log` to see the growth being
applied.

## `Currently failed` is not what you expect

It counts *addresses carrying live failures*,
not failures: one knocker with two failures
shows 1 (chapter 4). And a failure leaves the
count when it ages out of `findtime`, which is
why the number breathes even on a quiet
machine.

**Check:** nearly every entry above resolves
to one of three questions, in this order —
*is the server running, is the jail reading
the right well, did the action actually run?*
Ask them in order and the tool gives up its
answers quickly.
