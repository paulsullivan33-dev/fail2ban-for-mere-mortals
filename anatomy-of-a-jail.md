# Anatomy of a Jail

A jail is a block of settings under a heading.
Here is the whole lab jail from chapter 4, every
line of which earns its place:

```ini
[labauth]
enabled = true
backend = polling
filter  = sshd
logpath = /home/hatch/workspace/fail2ban-lab/work/lab-auth.log
port    = ssh
action  = lab-banfile
```

Read it as five questions answered:

- **`enabled`** — is this jail on? Jails are
  off by default; nobody's jail guards anything
  until this line says true.
- **`filter`** — what does a failure look like?
  `sshd` means "use `filter.d/sshd.conf`", the
  vendor's pattern for SSH failure lines.
- **`logpath`** — where do the failures get
  written? A file here; the journal, for the
  real sshd jail in chapter 6.
- **`port`** — which door the ban closes. The
  action uses it to build the firewall rule;
  `ssh` is a name from `/etc/services`, `22`
  would mean the same thing.
- **`action`** — what runs when the threshold
  is crossed. Omitted here in most jails,
  meaning "the default action" — on Ubuntu,
  the nftables action. The lab names a harmless
  action of its own, written for the occasion.

## The three numbers

A jail inherits defaults and overrides what it
cares about. The stock defaults, read off this
machine's `jail.conf`:

```
bantime  = 10m
findtime  = 10m
maxretry = 5
```

- **`maxretry`** — failures needed to convict.
  Five is the stock answer: forgiving of a
  human who mistypes, brisk against a bot that
  will happily try ten thousand.
- **`findtime`** — the window those failures
  must fall inside. Five failures spread over
  a week is a forgetful administrator; five in
  ten minutes is a guessing machine. Failures
  older than the window stop counting — the
  slate wipes itself continuously, not in
  batches.
- **`bantime`** — how long the address stays
  blocked. Stock is ten minutes: long enough
  to bore a bot into moving on, short enough
  that a banned human (it will happen; chapter
  5) is inconvenienced, not exiled.

Durations accept suffixes — `10m`, `1h`, `1d`,
`1w`, or a bare number of seconds. What you set
is what you can later ask back, in seconds:

```
$ fail2ban-client get sshd findtime
600
```

## Where a jail reads: the backend

The `backend` setting answers "how do failures
reach the jail," and it is the quietest source
of "my jail never fires" in the whole tool:

- **`systemd`** — read the journal, matching a
  unit and command. The Ubuntu default. The
  real sshd jail's status says what it watches,
  in so many words:

  ```
  $ fail2ban-client status sshd
  |- Filter
  |  `- Journal matches: _SYSTEMD_UNIT=sshd.service + _COMM=sshd
  ```

- **A log file** (via `logpath`) — the classic
  route, still the only route on systems whose
  services log to files. Fail2Ban notices new
  lines either by being told of file changes
  (inotify, when available) or by **polling** —
  checking the file every second. The lab jail
  above says `backend = polling` outright,
  because on a distribution whose default is
  the journal, a file-watching jail should not
  leave the choice to chance.

- **`auto`** — the upstream default: try the
  journal where it fits, files where it
  doesn't. (Ubuntu's drop-in changes the
  default to `systemd`, which is why the lab
  does not rely on `auto`.)

Two rules of thumb. A jail with a `logpath`
must end up with a file-reading backend; a jail
with `journalmatch` must end up with `systemd`.
And when a jail "does nothing," the backend
mismatch — watching the journal for a service
that logs to a file, or the reverse — is the
first suspect in chapter 13.

## Defaults are a place, not a mood

Settings written under a `[DEFAULT]` heading
apply to **every** jail that does not override
them — and `jail.local`'s `[DEFAULT]` overrides
`jail.conf`'s. The lab file opens with one:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.0.2.99
bantime  = 2m
findtime = 10m
maxretry = 3
```

It deliberately sets short, twitchy numbers —
2-minute bans, conviction at 3 — so a ban
completes while you watch. And because these
are defaults, they reached the stock sshd jail
too, which reported them back when asked:

```
$ fail2ban-client get sshd maxretry
3
$ fail2ban-client get sshd bantime
120
```

On the lab machine that is the demonstration
working as intended. On a real machine it is
the warning: **a `[DEFAULT]` in `jail.local`
is not a private note to one jail** — it is a
new house rule for all of them, sshd included.
Set per-jail numbers in the jail's own section
when that is what you mean.

**Check:** you can read any jail on your system
now — which filter, which log or journal, what
action, and the three numbers — and chapter 9
shows how to make the running server confirm
each answer. Next, the lab puts one to work.
