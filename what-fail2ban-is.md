# What Fail2Ban Is

Open the authentication log of any machine with
SSH exposed to the internet and you will find
the weather out there: a constant drizzle of
failed logins from addresses you have never
heard of, trying `root`, `admin`, `test`, the
names of services, the names of people. Most of
it is automated. All of it is looking for one
weak password.

A **firewall** decides who may reach a service
at all — that is the wall, and the companion
guide *UFW for Mere Mortals* is about building
it. But a wall whose door is open to the world
(as SSH usually must be, if you administer the
machine from elsewhere) lets everyone knock.
**Fail2Ban** stands next to that door with the
logbook in its hand. Every failed attempt the
service writes down, fail2ban reads. When one
address has failed too many times inside a
window of time, fail2ban instructs the firewall
to refuse that address entirely, for a set
period. Then it forgets about it until the ban
expires.

Fail2Ban is a **bouncer with a logbook**, and
keeping the metaphor straight keeps the tool
straight:

- It **reads logs**. It does not inspect
  traffic, sit in the connection path, or talk
  to the service. If a failure is not written
  to a log fail2ban watches, it never happened
  as far as fail2ban is concerned.
- It **counts per address**. The pattern is
  almost always "the same address, failing
  repeatedly, quickly." One typo from you is
  not an attack, and the thresholds exist to
  know the difference.
- It **acts through the firewall**. A ban is a
  firewall rule (or the equivalent), added at
  ban time and removed when the ban expires.
  Fail2Ban itself blocks nothing.
- It is **reactive**. The first few attempts
  always get through — that is the price of
  distinguishing a bot from a forgetful human.
  What fail2ban removes is the other ten
  thousand attempts.

And just as plainly, what it is **not**:

- **Not an authentication system.** It changes
  nothing about who can log in or how. A
  correct password works on the first try,
  banned or not, throughout the attack — SSH
  checks passwords, not ban lists. (Once
  banned, the address can't reach SSH at all,
  which is the point; but fail2ban never
  participates in the password check.)
- **Not a firewall.** It has no rules of its
  own about ports or services, and when the
  fail2ban process stops, its bans are removed
  with it. The standing posture of the machine
  is the firewall's job.
- **Not a shield for a weak password.** It
  raises the cost of guessing from "millions
  of tries" to "a handful of tries per window
  per address." Chapter 12 is honest about
  what still gets through, and about the
  companions — key-only SSH above all — that
  close the rest.

The machinery has three moving parts, and this
guide is organised around them. A **jail** is
one service under watch: the SSH jail watches
SSH failures, a web jail watches web failures.
Each jail pairs a **filter** — the pattern that
recognises a failure in that service's log —
with an **action** — the thing to run when the
threshold is crossed, normally "tell the
firewall to block this address." Around those,
three numbers per jail decide how twitchy the
bouncer is: **`maxretry`** (how many failures),
**`findtime`** (inside what window), and
**`bantime`** (how long the offender stays out).

**Check:** the whole idea, in one breath, is:
*logs in, counting in the middle, firewall
rules out.* Everything else in this guide is
detail hung on that frame — which files hold
which settings, how to test a filter before
trusting it, and how to prove a ban really
landed in the firewall instead of just being
announced.
