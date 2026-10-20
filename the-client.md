# The Client

`fail2ban-client` is the counter you walk up to.
The server holds all the state; the client asks,
tells, and reports. This chapter is the whole
conversation, in the order you will actually
have it. Every command below ran against the
lab server.

## Is anyone there

```
$ fail2ban-client ping
Server replied: pong
```

With the service stopped it answers with the
socket error from chapter 2 — worth knowing
cold, because "client prints a socket error" is
fail2ban for "the server is not running," and
nothing else you try will work until that
changes.

## What is running

```
$ fail2ban-client status
Status
|- Number of jail:  4
`- Jail list:       labauth, labnft, recidive, sshd
```

That is the whole establishment: the jails,
by name. Any jail you thought you enabled and
do not see here is not running — its section is
misspelled, its `enabled` is missing, or the
config failed (chapter 2's `-t` would have
said). Ask about one jail and you get its
filter and its action bookkeeping:

```
$ fail2ban-client status labauth
Status for the jail: labauth
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     3
|  `- File list:        /home/hatch/workspace/fail2ban-lab/work/lab-auth.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   192.0.2.66
```

For a journal jail the `File list` line reads
`Journal matches` instead (chapter 6). Read the
pairs as *weather and climate*: Currently
failed/banned is the state right now; Total is
everything since the server started. And the
roll-up across all jails, one line per jail:

```
$ fail2ban-client banned
[{'sshd': []}, {'recidive': []}, {'labauth': ['192.0.2.66']}, {'labnft': []}]
```

## Ask the jail what it thinks

Every effective setting can be read back from
the running server — the ground truth after
all the layered files have had their say:

```
$ fail2ban-client get labauth maxretry
3
$ fail2ban-client get labauth findtime
600
$ fail2ban-client get labauth bantime
120
$ fail2ban-client get labauth ignoreip
These IP addresses/networks are ignored:
|- 127.0.0.0/8
|- 192.0.2.99
`- ::1
```

Times come back in seconds, whatever suffix
the config used. When a jail behaves oddly,
`get` is how you discover that the number in
force is not the number you remember writing —
that a `[DEFAULT]` somewhere upstream, or a
`jail.d` file you forgot, got there first.

## Giving orders

Chapter 5 already used the rescue command;
here is the family. `set <jail> unbanip <ip>`
releases an address (and answers with the
count released). Its mirror exists too — a ban
with no log lines involved, useful for an
address you have decided about on other
evidence:

```
$ fail2ban-client set labauth banip 203.0.113.200
1

$ cat ~/workspace/fail2ban-lab/bans.log
BAN ip=203.0.113.200 jail=labauth failures=0
```

`failures=0` in the action's record is the
tell: fail2ban says in its own paperwork that
no filter convicted this address; a human did.
Manual bans expire on the jail's normal
`bantime`, like any other.

Two more verbs complete the working set.
`fail2ban-client reload` asks the running
server to re-read the configuration (with
`reload <jail>` for just one) — run `-t`
first, always, because a config that fails at
reload can take jails down with it. And
settings can be changed *live* with the same
`set` shape (`set labauth bantime 300`), with
the standing warning that a live change is not
in any file: the next restart quietly restores
the written configuration, and the difference
between the two is a classic source of "it
worked until the reboot."

**Check:** the client's repertoire settles
most field questions in under a minute — is
the server up (`ping`), what is running
(`status`), what does this jail believe (`get`),
who is banned (`status`, `banned`), and let
them out (`set ... unbanip`).
