# Other Jails

SSH is the door everyone guards, but the shelf
is stocked for the other services that take
passwords in public. This chapter is a survey,
honestly labelled as one: the filters below
exist in this install and are named here with
what they watch — the deep walk-through was
chapter 6's, for sshd, and this chapter will
not pretend these were each exercised the way
sshd was.

```
$ ls /etc/fail2ban/filter.d/ | grep -E 'apache-auth|nginx|postfix|dovecot'
apache-auth.conf
dovecot.conf
nginx-bad-request.conf
nginx-botsearch.conf
nginx-http-auth.conf
nginx-limit-req.conf
postfix.conf
```

The shape repeats everywhere: a filter that
knows the service's failure lines, a jail
section in `jail.conf` (disabled, waiting), and
your job reduced to enabling it in `jail.local`
and choosing its three numbers.

- **Web authentication.** `apache-auth` and
  `nginx-http-auth` watch for failed HTTP basic
  auth in the web server's error log — the
  knocks against a password-protected path.
  Their neighbours are more specialised:
  `apache-badbots` and `nginx-botsearch` hunt
  scanner behaviour rather than password
  failures, and `nginx-limit-req` pairs with
  nginx's own rate limiting, banning addresses
  the web server is already shedding. Apache
  brings a whole family (`apache-noscript`,
  `apache-overflows`, `apache-shellshock`) —
  historical attack shapes, less central than
  the auth jail.
- **Mail.** `postfix` (and its SASL companion
  patterns) watches the mail log for
  authentication failures and relay abuse;
  `dovecot` watches IMAP/POP3 logins. Mail
  jails deserve a slower hand than SSH: the
  "offender" behind a failed IMAP login is
  often a phone with an old password, at an
  address the whole office shares.
- **And the long tail.** The 95 filters on this
  machine cover databases, VoIP, game servers,
  control panels, and things that had one bad
  year a decade ago. Presence on the shelf is
  not a recommendation; it is a starting point
  for chapter 7's discipline.

Whichever you enable, the working method is
the one this guide has used throughout, and
it does not shrink for stock jails:

1. **Rehearse the filter** — `fail2ban-regex`
   against a real slice of that service's log
   (chapter 7). Confirm your real failures
   match and your real successes do not.
2. **Whitelist first** (chapter 5) — mail and
   web jails have the richest supply of
   innocent repeat offenders in the building.
3. **Modest numbers first** — stock defaults,
   watched for a few days in the logs, before
   any tightening.
4. **Verify the ban at the firewall**
   (chapter 8) after the first one lands.

**Check:** the shelf is wide and mostly
unmaintained-by-you until you choose from it;
an enabled stock jail is a starting point with
a rehearsal owed, not a finished control.
