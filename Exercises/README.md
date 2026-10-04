# Asynchronous Services: Workshop Exercises

Dyalog26 User Meeting, 12 October 2026

In this workshop you build asynchronous services in Dyalog APL using three open-source tools:

- **[HttpCommand](https://dyalog.github.io/HttpCommand)**: an HTTP client, for calling web services from APL
- **[Jarvis](https://dyalog.github.io/Jarvis)**: a web service framework, for writing web services in APL
- **[WebSocketClient](https://dyalog.github.io/WebSocketClient/)**: a WebSocket client, for two-way messaging from APL

You don't need to have used any of them before. You also don't need to know HTML, CSS, or JavaScript: any web pages are supplied ready to use.

## Before the workshop

Please do this before you arrive, so that any problems can be sorted out early.

### 1. Check the prerequisites

- **Dyalog APL 19.0 or later** on Windows, macOS, or Linux
- **A modern web browser** (Chrome, Edge, Firefox, or Safari)
- **Network access** for the first part of Exercise 1, which calls a public web service. Everything else runs on your own machine.

### 2. Get the workshop materials

Either:

- **Download a zip:** go to <https://github.com/dyalog-training/2026-MP2>, click **Code**, then **Download ZIP**, and unpack it, or
- **Clone the repository:** `git clone https://github.com/dyalog-training/2026-MP2.git`

Make a note of the folder you unpacked or cloned it into. These instructions call it `<repo>`. For example, it might be `C:/Users/me/2026-MP2` on Windows or `/Users/me/2026-MP2` on macOS.

### 3. Run Setup

Start Dyalog APL and enter these two lines, replacing `<repo>` with your folder (forward slashes work on every platform, including Windows). `Setup ''` finds the workshop folder from where `Setup` was loaded; you can also give it the folder, as in `Setup '<repo>'`:

```apl
2 ⎕FIX 'file://<repo>/Exercises/Setup.aplf'
Setup ''
```

`Setup` loads the three tools and then checks that a web service can run on your machine. You should see something like:

```
Loaded:
  HttpCommand 5.11.2 2026-09-29
  Jarvis 1.23.1 2026-10-03
  WebSocketClient 1.0.1 2026-10-03
Checking that a Jarvis server can run on localhost:8089
Ready
```

If you see `Ready`, you're all set. If you see a line starting with `Problem:`, see [Troubleshooting](#troubleshooting) below.

## At the workshop

The workshop lasts 3 hours 30 minutes, with two 15-minute breaks. Each exercise follows a short talk and has 30 minutes of hands-on time.

| Start | Session |
|:------|:--------|
| 0:00 | Welcome and setup |
| 0:10 | Talk: asynchronous services and the tools |
| 0:25 | Exercise 1: Introducing the tools |
| 0:55 | Talk: web hooks |
| 1:05 | Break |
| 1:20 | Exercise 2: Web hook |
| 1:50 | Talk: Server-Sent Events |
| 2:00 | Exercise 3: Server-Sent Events |
| 2:30 | Break |
| 2:45 | Talk: WebSockets |
| 2:55 | Exercise 4: WebSockets (a chat service) |
| 3:25 | Wrap-up and questions |

At the start of each exercise, run `Setup` again in a fresh session (step 3 above), then follow that exercise's `README.md`:

| Exercise | Folder | Uses |
|:---------|:-------|:-----|
| 1: Introducing the tools | `Ex1-Tools/` | HttpCommand, Jarvis |
| 2: Web hook | `Ex2-WebHook/` | HttpCommand, Jarvis (two servers) |
| 3: Server-Sent Events | `Ex3-SSE/` | Jarvis, your browser |
| 4: WebSockets | `Ex4-WebSockets/` | Jarvis, WebSocketClient, your browser |

### How each exercise is organised

- **`README.md`**: the steps to follow. Every APL expression can be copied and pasted into your session. Steps marked **core** fit in the 30 minutes; steps marked **stretch** are optional, for if you finish early or want to continue after the workshop.
- **`Start/`**: your starting point. Most of the code is supplied; you fill in a few short functions.
- **`Solution/`**: a complete working version.
- **`Load`**: after `Setup`, `Load 1` (and so on) loads what an exercise needs into your session.
- **`Run1` to `Run4`**: each exercise has a Run function, named after its number, that starts its server(s) for you, so you don't need to retype any configuration. The names differ so that you can load more than one exercise in the same session.

**Behind or stuck?** That's fine. When the time is up, load the exercise's `Solution/` (its README shows how) and move on. No exercise depends on your own code from an earlier one.

### Dyalog 19 and Dyalog 20

All the supplied code runs on Dyalog 19.0 and later. Where Dyalog 20 offers a neater way to write something (array notation, `⎕VGET`, or `⎕VSET`), the README shows both versions:

```apl
⍝ Dyalog 19
job←⎕NS'' ⋄ job.n←42 ⋄ job.callback←'http://localhost:8082/Result'
⍝ Dyalog 20 alternative
job←(n: 42 ⋄ callback: 'http://localhost:8082/Result')
```

In the solution files, the Dyalog 20 version appears as a comment starting `⍝ v20:` under the line it replaces. Use whichever matches your version.

## Troubleshooting

**`Problem: cannot find the workshop files`**: the folder `Setup` used isn't the one that contains `Exercises` and `Source`. Check the path in the `2 ⎕FIX` line, or give `Setup` the folder yourself, remembering the quotes: `Setup 'C:/Users/me/2026-MP2'`.

**`Problem: could not start a Jarvis server ... port 8089 is already in use`**: another program is using that port. Give `Setup` a different port on the left, for example `8090 Setup ''`. Exercise servers use ports 8080 to 8084; if one of those is in use, each exercise's `Run` function takes a different port as its argument, as shown in its README.

**A firewall prompt appears** (usually on Windows, sometimes on macOS) the first time a server starts: allow it. The exercises only ever connect to `localhost`, your own machine. A Jarvis server does listen on your network too, so stop your servers when you finish an exercise (each README shows how), especially on shared Wi-Fi.

**`Problem: could not copy Conga`**: Conga is part of every Dyalog installation, so this usually means an incomplete installation. Ask for help.

**Anything else**: ask! That's what the breaks are for, too.

## Documentation

- HttpCommand: <https://dyalog.github.io/HttpCommand>
- Jarvis: <https://dyalog.github.io/Jarvis>
- WebSocketClient: <https://dyalog.github.io/WebSocketClient/>
- Dyalog documentation: <https://docs.dyalog.com>
