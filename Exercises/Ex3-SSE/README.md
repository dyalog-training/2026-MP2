# Exercise 3: Server-Sent Events

**Time:** 30 minutes. Steps marked **core** fit in the time; steps marked **stretch** are optional.

## Objectives

- Push updates from APL to a web page as they happen, using **Server-Sent Events** (SSE)
- Send an event to one client, and broadcast events to every connected client
- See how a browser reconnects by itself when the stream drops

## Background

In Exercises 1 and 2 the client always asked first. With Server-Sent Events, the client asks once, and then the server keeps the connection open and sends **events** whenever it likes. It's one-way (server to client) and plain HTTP, and every modern browser supports it through the JavaScript `EventSource` object, which also reconnects automatically if the connection drops.

On the wire, each event is a few lines of text followed by a blank line:

```
event: price
data: {"symbol":"IOTA","price":85.6,"change":0.1}

```

`event:` is the event's type and `data:` is its content (here, JSON). A line starting with `:` is a comment; Jarvis sends one every 30 seconds (`SSEHeartbeatInterval`) to keep idle connections alive.

The Jarvis features you'll use:

| Feature | What it does |
|:--------|:-------------|
| `SSEEndpoints` | Names the endpoints that are event streams. `Run3` sets it to `'Ticker'`, so a browser opening `/Ticker` gets a stream, and Jarvis calls your function `Ticker` once when it connects |
| `server.FormatSSE` | Formats an event: `'price' server.FormatSSE data` gives the text above (data that isn't text is converted to JSON) |
| `server.SSEConnections 'Ticker'` | The clients connected to `/Ticker` right now |
| `clients server.SendSSE event` | Sends a formatted event to one or more clients |

You'll build a live price ticker. The web page, `html/index.html`, is supplied: it shows a price table, a news list, and the connection status, and you don't need to change it. You write two APL functions in `#.Ex3`:

- `Ticker`: called when a client connects; sends that client a `welcome` event
- `Broadcast`: a loop, running in its own thread, that sends every client a `price` event for each symbol every second, and a `news` event every 5 seconds

`Run3` sets up the data the loop uses, in `#.Ex3`: `Symbols` (`ALPHA`, `IOTA`, `OMEGA`, `RHO`), their `Prices`, some news `Headlines`, and `Running` (the loop runs while it's 1).

## Getting started

If you haven't already, start Dyalog and run `Setup` (see [the workshop README](../README.md#3-run-setup)):

```apl
2 ⎕FIX 'file://<repo>/Exercises/Setup.aplf'
Setup ''
```

Then load this exercise: `Load 3` loads its `Run3` function. From here on, every line can be pasted as is:

```apl
Load 3
```

## Steps

### S1. Start the service (core)

```apl
server←Run3 8083
```

`Run3` also loads two supplied functions: `Stop`, which stops the loop and the server, and `Restart`, which you'll use in S3.

Open <http://localhost:8083> in your browser. The page shows **Connection: connected** but no prices yet, and your session shows `Ticker is not written yet: a client connected`. That's the starting version, waiting for you.

### S2. Write Ticker: welcome each new client (core)

First, see what an event looks like:

```apl
d←⎕NS'' ⋄ d.text←'Hello'
'welcome' Jarvis.FormatSSE d
```

That's the text sent to the browser: an `event:` line, a `data:` line with the namespace as JSON, and a blank line.

Now edit `Ticker`:

```apl
)ED #.Ex3.Ticker
```

Its argument `req` is the request from the connecting client. `req.Server` is the Jarvis server, and `req` itself identifies this client, so you can send an event to just this client with:

```apl
req req.Server.SendSSE 'welcome' req.Server.FormatSSE data
```

where `data` is a namespace with a `text` field:

```apl
⍝ Dyalog 19
data←⎕NS'' ⋄ data.text←'Welcome to the APL ticker'
```

```apl
⍝ Dyalog 20 alternative
data←(text: 'Welcome to the APL ticker')
```

`Ticker` must not return a result (or must return 0); anything else closes the connection.

Check your work: reload the page. Each new connection calls `Ticker`, so your welcome text appears under the heading, with no need to restart anything.

### S3. Write Broadcast: send to everyone (core)

```apl
)ED #.Ex3.Broadcast
```

The loop, the one-second pause, and the `:Trap` are already there. Inside the `:Trap`, where it says Step S3:

1. Get the clients connected right now: `clients←server.SSEConnections 'Ticker'`.

2. For each symbol (`:For i :In ⍳≢Symbols`), move its price at random, by up to 1% either way, rounded to cents:

   ```apl
   old←i⊃Prices
   Prices[i]←0.01×⌊0.5+old×100+0.01×¯101+?201
   ```

   then build the event data, with the change since last time:

   ```apl
   ⍝ Dyalog 19
   data←⎕NS''
   data.(symbol price change)←(i⊃Symbols)(i⊃Prices)(0.01×⌊0.5+100×(i⊃Prices)-old)
   ```

   ```apl
   ⍝ Dyalog 20 alternative
   data←⎕NS'' ⋄ data ⎕VSET ('symbol' (i⊃Symbols))('price' (i⊃Prices))('change' (0.01×⌊0.5+100×(i⊃Prices)-old))
   ```

   and send it to everyone, as a `price` event: `clients server.SendSSE 'price' server.FormatSSE data`.

3. Every 5 seconds (when `0=5|tick`), send a `news` event whose data has a `text` field: a random headline, `(?≢Headlines)⊃Headlines`.

**Then run `Restart`:**

```apl
Restart
```

The loop that's already running keeps the code it started with, so editing `Broadcast` doesn't change it. `Restart` stops that loop and starts a new one with your edited `Broadcast`, leaving the server running. (Don't use `Run3` for this: `Run3` reloads the functions from the files and would throw your edits away.)

Check your work: within a couple of seconds, the table on the page fills with four symbols, and their prices change every second (green up, red down); a news item appears every 5 seconds. If you made a mistake, the session shows `Broadcast:` and the error each second: fix it with `)ED`, then `Restart` again.

### S4. Many clients, and reconnecting (core)

Open <http://localhost:8083> in a second tab, or another browser: both get the same prices, because `Broadcast` sends to every connection. Then stop just the server for a moment:

```apl
server.Stop
```

Both pages show **reconnecting...**, and the browser keeps trying. Start it again:

```apl
server.Start
```

Within a few seconds both pages are connected again and prices continue, without reloading. Each reconnection calls `Ticker` again, so the welcome is sent again too. The `Broadcast` loop kept running all along; while the server was stopped it just had no clients to send to.

### S5. Stop (core)

```apl
Stop
```

This stops the loop and the server. (Use `Stop`, not `server.Stop`, when you're finished: `server.Stop` alone leaves the loop running.)

### S6. Your own event type (stretch)

Add a new kind of event, end to end:

1. In APL, send a new event type from `Broadcast`, for example an `alert` when a price moves by more than 0.5%. Then `Restart`.
2. In `html/index.html` (open it in any text editor), find the section marked `EDIT HERE`. Remove the `//` from the start of its three code lines, and change `"myevent"` to your event type. Save the file and reload the page: Jarvis serves the file as it is now, so there's no need to restart anything. Your events now appear in the News list.

## Catching up

If time is up or you're stuck, load the solution. `Run3` stops the earlier server and loop first:

```apl
server←'Solution' Run3 8083
```

Changes you make with `)ED` will update the in-session copy and the source file in `Start/`. The finished versions are in `Solution/`.

## Documentation

- Jarvis, including SSE: <https://dyalog.github.io/Jarvis>
- Server-Sent Events in the browser: <https://developer.mozilla.org/en-US/docs/Web/API/EventSource>
