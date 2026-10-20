# Meet Fail2Ban

Fail2Ban is two programs. The **server**,
`fail2ban-server`, is the one that does the
work: it starts at boot, reads the
configuration, opens the logs, counts, and runs
actions. The **client**, `fail2ban-client`, is
how you talk to it — ask what it is doing, test
the configuration, ban or unban an address by
hand. The client does nothing on its own; it
passes messages to the server over a socket and
prints what comes back. That is why the
client's first lesson is what happens when the
server is not there:

```
$ fail2ban-client ping
2026-10-20 21:41:31,334 fail2ban                [15473]: ERROR   Failed to access socket path: /var/run/fail2ban/fail2ban.sock. Is fail2ban running?
```

Start the service, and the same command answers
`Server replied: pong`. Almost everything in
chapter 9 is variations on this conversation.

## The files, and which ones are yours

Everything lives in `/etc/fail2ban/`:

```
$ ls /etc/fail2ban/
action.d
fail2ban.conf
fail2ban.d
filter.d
jail.conf
jail.d
paths-arch.conf
paths-common.conf
paths-debian.conf
paths-opensuse.conf
```

Three kinds of file matter day to day:

| File or directory | Whose it is | What it holds |
|---|---|---|
| `jail.conf` | The vendor's | Every stock jail and the default settings. **Never edit it.** |
| `jail.local`, `jail.d/*.conf` | **Yours** | Your overrides and your own jails. |
| `filter.d/*.conf` | The vendor's (with `.local` siblings yours) | The failure patterns, one file per service. |
| `action.d/*.conf` | The vendor's (same rule) | The ban/unban scripts, one file per kind of action. |
| `fail2ban.conf` | The vendor's (`.local` yours) | The server's own settings: its log file, its log level, its socket. |

The rule that follows: **`jail.conf` is read
first, and your files override it.** Settings
you put in `jail.local` replace the same
settings in `jail.conf`; files in `jail.d/` are
read afterwards, in name order, and can override
both. The package manager owns `jail.conf` and
will replace it on upgrade, silently discarding
anything you typed into it — which is why every
instruction in this guide writes to `jail.local`
or `jail.d/`, never to `jail.conf`. The same
pattern applies per file: `filter.d/sshd.conf`
can be adjusted by writing `filter.d/sshd.local`
with just your changed lines.

What your distribution adds matters too. On
Ubuntu, the package drops one file into
`jail.d/` before you ever touch anything:

```
$ cat /etc/fail2ban/jail.d/defaults-debian.conf
[DEFAULT]
banaction = nftables
banaction_allports = nftables[type=allports]
backend = systemd

[sshd]
enabled = true
```

Three facts hide in that little file, and all
three surprise people arriving from other
distributions' documentation: on Ubuntu the
default ban action is **nftables** (not the
iptables action most older guides describe),
the default way of reading logs is the
**systemd journal**, and the **sshd jail is
already enabled**. Chapter 6 starts from those
facts rather than pretending otherwise.

The stock inventory is generous. This install
carried **95 filters** and **64 actions** —
patterns for services you may never run
(asterisk, ejabberd, three proxies) alongside
the ones you will (sshd, apache, postfix,
dovecot, nginx). You do not write most of what
you use; you select it, enable it, and tune
its three numbers.

## Testing the configuration before it bites

Because your files are layered over the
vendor's, a typo of yours can break the whole
read. Fail2Ban has a rehearsal mode:

```
$ fail2ban-client -t
2026-10-20 21:40:51,276 fail2ban.configreader   [15381]: WARNING 'allowipv6' not defined in 'Definition'. Using default one: 'auto'
OK: configuration test is successful
```

(a warning about the lab's hand-written action
file, harmless; a warning is a note, not a
failure). Feed it a genuine typo — a stray line
in a `jail.d` file that is not a setting at
all — and the rehearsal earns its keep:

```
$ fail2ban-client -t
2026-10-20 21:41:14,055 fail2ban                [15405]: ERROR   Failed during configuration: Source contains parsing errors: '/etc/fail2ban/jail.d/99-lab-typo.conf'
	[line  3]: 'this line is not a setting\n'
2026-10-20 21:41:14,055 fail2ban                [15405]: ERROR   ERROR: test configuration failed
```

It names the file and the line, and it exits
non-zero, so a script can catch it too. Run
`-t` after every edit, before every reload:
the same error at reload time takes the whole
server down, not just the jail you were editing.

**Check:** two habits from this chapter carry
the whole book — write only in `.local` files
and `jail.d/`, and run `fail2ban-client -t`
after every change, before you ask the running
server to swallow it.
