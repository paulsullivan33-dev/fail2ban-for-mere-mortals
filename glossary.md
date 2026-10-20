# Glossary

**action** — The set of commands a jail runs
when it bans (and unbans): a file in
`action.d/`. The default on Ubuntu is the
**nftables** action; upstream's long-standing
default is **iptables-multiport**.

**backend** — How a jail receives failures:
the **systemd journal**, or a log **file**
(noticed via inotify or by **polling**). Set
per jail; the cause of most "never fires"
mysteries.

**ban** — One address blocked by a jail's
action for the jail's **bantime**. Announced
by the client, recorded in fail2ban's log,
real only when present in the firewall.

**bantime** — How long a ban lasts. With
**bantime.increment**, repeat offences within
the record grow it — the growth is computed
by a formula (or multipliers), scaled by
**bantime.factor**, capped by
**bantime.maxtime**.

**client** — `fail2ban-client`: the command
you talk to the server with. It holds no
state of its own.

**fail2ban-regex** — The rehearsal tool: runs
a filter against a log file and reports which
lines **matched**, which were **ignored**, and
which were **missed**, without banning
anything.

**failregex** — The regular expressions inside
a **filter** that recognise a failure line.
Each contains **`<HOST>`**, the placeholder
marking where the offender's address is
captured.

**filter** — A file in `filter.d/` naming the
patterns that count as failures for one
service, plus how to read that service's
dates. The sshd filter ships **modes**
(normal, ddos, extra, aggressive) — wider or
narrower pattern sets.

**findtime** — The window inside which
failures count toward **maxretry**. Older
failures stop counting.

**ignoreip** — The whitelist: addresses and
networks a jail never counts and never bans.
Loopback is always on it; your admin
addresses should be.

**jail** — One service under watch: a filter,
an action (or the default), a source of
failures, and the three numbers. Jails are
defined in `jail.conf` and your `jail.local`
/ `jail.d/` files, and are off until enabled.

**journalmatch** — The journal pattern a
systemd-backend jail reads (unit and command),
shown by `fail2ban-client status <jail>`.

**logpath** — The file a file-backend jail
watches.

**maxretry** — Failures inside **findtime**
needed to trigger a ban.

**recidive** — The stock jail that watches
fail2ban's own log and bans addresses already
banned repeatedly elsewhere — the jail for
the jail log.

**server** — `fail2ban-server`: the daemon
that reads the logs, counts, decides, and
runs actions. Started by the `fail2ban`
systemd service; keeps its history in a small
database under `/var/lib/fail2ban/`.
