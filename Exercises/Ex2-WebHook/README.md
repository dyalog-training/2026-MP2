# Exercise 2: Web hook

**Time:** 30 minutes. Steps marked **core** fit in the time; steps marked **stretch** are optional.

## Objectives

- Accept a request, hand the work to a separate thread, and reply at once with a **ticket number**
- When the work is done, deliver the result by calling a URL the client gave you: a **web hook**
- Handle the case where the web hook can't be reached

## Background

Some requests take a long time to answer. Making the client wait means a connection held open, a risk of timeouts, and a client that can do nothing else meanwhile. Polling ("is it done yet?") wastes requests. A **web hook** turns this around: the client says where to send the result, gets a ticket straight away, and the server calls back when the result is ready.

You run two Jarvis servers in one APL session:

```
Client ──POST /Submit {"n":…,"callback":"http://localhost:8082/Result"}──▶ Ticket server (port 8081)
       ◀── {"ticket":17}, straight away ───────────────────────────────────
                                       … the work runs in a separate thread …
Ticket server ──POST /Result {"ticket":17,"n":…,"factors":[…]}──▶ Callback server (port 8082)
```

In real life the ticket server and the callback server belong to different organisations, on different machines. Here both run in your session so that you can see everything at once.

The "work" is finding the prime factors of a number, using the supplied function `Factors` (once the servers are running, try `#.Ex2Ticket.Factors 360`), plus a few seconds' pause so that results arrive in a different order from the tickets.

You write three short functions:

| Function | Server | Namespace | What it does |
|:---------|:-------|:----------|:-------------|
| `Result` | callback | `#.Ex2Callback` | receives a result and stores it |
| `Submit` | ticket | `#.Ex2Ticket` | gives out a ticket and starts the work |
| `Work` | ticket | `#.Ex2Ticket` | does the work, then calls the web hook |

`Work` is not an endpoint: `Run2` sets each server's `IncludeFns` so that only `Submit` (and `Status`, a stretch goal) on the ticket server and `Result` on the callback server can be called over HTTP.

## Getting started

If you haven't already, start Dyalog and run `Setup` (see [the workshop README](../README.md#3-run-setup)):

```apl
2 ⎕FIX 'file://<repo>/Exercises/Setup.aplf'
Setup ''
```

Then load this exercise: `Load 2` loads its `Run2` function and the supplied `Client`. From here on, every line can be pasted as is:

```apl
Load 2
```

## Steps

### C1. Start both servers (core)

```apl
(ticket callback)←Run2 8081 8082
Client 3
```

`Client` submits jobs to the ticket server and waits for their results. For now each job gets `no ticket ... Submit is not written yet`: the starting version, waiting for you.

### C2. Write Result, on the callback server (core)

```apl
)ED #.Ex2Callback.Result
```

`payload` is a namespace with `ticket`, `n`, and `factors`. Add it to the variable `Results` (which `Run2` set to `⍬`) with `Results,←payload`, print a line about it, and return something short such as `'received'`. Your change takes effect as soon as you close the editor.

Try it by posting a result yourself:

```apl
⍝ Dyalog 19
p←⎕NS'' ⋄ p.(ticket n factors)←0 360 (2 2 2 3 3 5)
```

```apl
⍝ Dyalog 20 alternative
p←(ticket: 0 ⋄ n: 360 ⋄ factors: 2 2 2 3 3 5)
```

```apl
r←HttpCommand.GetJSON 'post' 'localhost:8082/Result' p
r.(rc HttpStatus Data)
≢#.Ex2Callback.Results
```

Check your work: `0 200` and your reply, your printed line, and `1` result stored.

### C3. Write Submit, on the ticket server (core)

```apl
)ED #.Ex2Ticket.Submit
```

`Submit` is **dyadic**: Jarvis passes the request as the left argument `req`, which lets you reply with an error status. `job` is a namespace with `n` and `callback` (and optionally `seconds`). `Submit` should:

1. Reply with HTTP status 400 if the job isn't valid, for example `'A job needs "n" and "callback"' req.Fail 400`, then exit with `→0`. Check that:
   - `n` and `callback` are both there: `∧/2=⌊job.⎕NC'n' 'callback'`. (If the request has no body, `job` is `''`, not a namespace; check with `9=⌊⎕NC'job'` first.)
   - `n` is a single whole number from 2 to 1E12. Larger numbers take `Factors` too long, and anything else makes it fail. A JSON number arrives as a simple numeric scalar, so test `0=≢⍴job.n` and `2|⎕DR job.n` (numbers have odd `⎕DR` values) before comparing it with `⌊`, 2, and 1E12.
   - `callback` is text: `(1=≢⍴job.callback)∧0=10|⎕DR job.callback`.

   Checking now matters: once `Submit` has given out a ticket, a bad job can only fail later, out of the client's sight.
2. Take the next ticket number. `LastTicket` (set to 0 by `Run2`) holds the last one. Two requests can arrive at once, so take the number inside `:Hold 'Ex2Ticket'` ... `:EndHold`.
3. Start the work in a new thread: `Work&ticket job`. The `&` means "run this in a new thread", so `Submit` carries on at once.
4. Return a namespace with the ticket number:

```apl
⍝ Dyalog 19
r←⎕NS'' ⋄ r.ticket←ticket
```

```apl
⍝ Dyalog 20 alternative
r←(ticket: ticket)
```

Try it:

```apl
⍝ Dyalog 19
job←⎕NS'' ⋄ job.(n callback)←360 'http://localhost:8082/Result'
```

```apl
⍝ Dyalog 20 alternative
job←(n: 360 ⋄ callback: 'http://localhost:8082/Result')
```

```apl
r←HttpCommand.GetJSON 'post' 'localhost:8081/Submit' job
r.(rc HttpStatus)
r.Data.ticket
```

Check your work: `0 200` and ticket `1`, and the session shows `Ticket 1: Work is not written yet` (that's the starting version of `Work`, running in its new thread). Sending `⎕NS''` instead of `job` gives `0 400`, and so does a job with `n` set to `'abc'` or `1E13`.

### C4. Write Work, the web hook (core)

```apl
)ED #.Ex2Ticket.Work
```

`Work` runs in its own thread, with the ticket number and the job. It should:

1. Pause for `job.seconds` seconds if given, otherwise 2 to 4 at random:

   ```apl
   ⍝ Dyalog 19
   seconds←{6::1+?3 ⋄ ⍵.seconds}job
   ```

   ```apl
   ⍝ Dyalog 20 alternative
   seconds←job ⎕VGET ⊂'seconds' (1+?3)
   ```

   then `⎕DL seconds`.

2. Build the result, using the supplied `Factors`:

   ```apl
   ⍝ Dyalog 19
   payload←⎕NS''
   payload.(ticket n factors)←ticket job.n (Factors job.n)
   ```

   ```apl
   ⍝ Dyalog 20 alternative
   payload←⎕NS'' ⋄ payload ⎕VSET ('ticket' ticket)((,'n') job.n)('factors' (Factors job.n))
   ```

   (`⎕VSET` needs each name as a vector, so the one-letter name `n` is written `(,'n')`.)

3. Post it to the callback URL with `r←#.HttpCommand.GetJSON 'post' job.callback payload`, and print a message if `r.rc` isn't 0 (the request failed) or `r.HttpStatus` isn't 200 (the callback server said no), as in Exercise 1 step A4.

4. Put all of the above inside `:Trap 0` ... `:Else` ... `:EndTrap`, printing the ticket number and `⎕DMX.EM` in the `:Else` part. Jarvis catches errors in endpoints such as `Submit`, but nothing catches an error in a thread you start yourself with `&`. Left untrapped, one failed job would suspend its thread in your session, or stop APL altogether if the service ran as a script.

**If your `Work` has an error** while you're writing it (before you've added the `:Trap`), APL suspends that thread and shows the error in the session. The ticket server keeps running. Fix `Work` with `)ED #.Ex2Ticket.Work` and submit the job again: new jobs use the corrected `Work`. The failed job's thread stays suspended, which does no harm, so you can leave it.

### C5. Run the client (core)

```apl
Client 5
```

Check your work: each job gets its ticket in a few milliseconds, then the results arrive a few seconds later, printed by your `Result`, and **not in ticket order**. `Client` finishes with something like `All 5 results arrived, in this order of tickets: 1 3 4 5 2`.

### C6. Stop the servers (core)

```apl
(ticket callback).Stop
```

### S1. When the web hook can't be reached (stretch)

Restart the servers if you stopped them (`(ticket callback)←Run2 8081 8082`, or `'Solution' Run2` if you're catching up), then stop just the callback server and submit jobs:

```apl
callback.Stop
Client 2
callback.Start
```

Your `Work` should print that it couldn't reach the callback URL, and `Client` gives up waiting after 10 seconds. The results are lost: nobody kept them.

### S2. Retry (stretch)

Change `Work` so that if the callback fails, it tries again a few times, waiting longer each time (for example 1, 2, then 4 seconds) before giving up. Try it with S1, starting the callback server again while `Work` is still retrying.

### S3. A Status endpoint (stretch)

Web hooks are often combined with polling as a fallback. Add a `Status` endpoint on the ticket server (it is already in the ticket server's `IncludeFns`) that takes `{"ticket":17}` and says whether that job is still working, delivered, or failed. You'll need `Work` to record each ticket's state, for example in a namespace in `#.Ex2Ticket`. There is no supplied solution for S2 and S3.

## Catching up

If time is up or you're stuck, load the solution. `Run2` stops the servers it started earlier:

```apl
(ticket callback)←'Solution' Run2 8081 8082
Client 5
```

Changes you make with `)ED` will update the in-session copy and the source file in `Start/`. The finished versions are in `Solution/`.

## Documentation

- HttpCommand: <https://dyalog.github.io/HttpCommand>
- Jarvis: <https://dyalog.github.io/Jarvis>
