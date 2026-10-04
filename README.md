# Asynchronous Services

Workshop materials for **Asynchronous Services**, presented by Brian Becker and Holden Hoover at the Dyalog26 User Meeting on 12 October 2026.

Most web requests make the client wait for the answer. In this workshop you build services in Dyalog APL that don't: a service that calls you back when the work is done (a **web hook**), one that streams live updates to a web page (**Server-Sent Events**), and a chat service where both sides talk whenever they like (**WebSockets**). You use three open-source tools from Dyalog:

- **[HttpCommand](https://dyalog.github.io/HttpCommand)**: an HTTP client, for calling web services from APL
- **[Jarvis](https://dyalog.github.io/Jarvis)**: a web service framework, for writing web services in APL
- **[WebSocketClient](https://dyalog.github.io/WebSocketClient/)**: a WebSocket client, for two-way messaging from APL

No experience with these tools is needed, and you don't need to know HTML, CSS, or JavaScript: the web pages are supplied.

## Getting started

You need **Dyalog APL 19.0 or later** (Windows, macOS, or Linux) and a web browser.

1. Download this repository (**Code**, then **Download ZIP**, and unpack it) or clone it:

   ```
   git clone https://github.com/dyalog-training/2026-MP2.git
   ```

2. Start Dyalog APL and enter these two lines, replacing `<repo>` with the folder you unpacked or cloned into (forward slashes work on every platform):

   ```apl
   2 ⎕FIX 'file://<repo>/Exercises/Setup.aplf'
   Setup ''
   ```

   `Setup` loads the tools and checks that a web service can run on your machine. When it prints `Ready`, you're all set.

3. Load an exercise and follow its README, for example:

   ```apl
   Load 1
   server←Run1 8080
   ```

The [workshop README](Exercises/README.md) has the full instructions, the schedule, and troubleshooting. Please run `Setup` before the workshop, so any problems can be sorted out early.

## The exercises

Each exercise takes 30 minutes and follows a short talk. Steps marked **core** fit in that time; steps marked **stretch** are for finishing early or continuing afterwards.

| Exercise | What you build | Tools |
|:---------|:---------------|:------|
| [1: Introducing the tools](Exercises/Ex1-Tools/README.md) | Call a public web service, then write your own Jarvis service and call it from your browser and from APL | HttpCommand, Jarvis |
| [2: Web hook](Exercises/Ex2-WebHook/README.md) | A service that gives out tickets at once, does the work in a separate thread, and calls the client back with each result | HttpCommand, Jarvis |
| [3: Server-Sent Events](Exercises/Ex3-SSE/README.md) | A live price ticker that pushes updates from APL to every connected browser | Jarvis |
| [4: WebSockets](Exercises/Ex4-WebSockets/README.md) | A chat server, used from two browser tabs and from APL | Jarvis, WebSocketClient |

Every exercise has a `Start/` folder (most of the code is supplied; you write a few short functions) and a `Solution/` folder. If you fall behind, load the solution and carry on: no exercise depends on your own code from an earlier one.

All the code runs on Dyalog 19.0. Where Dyalog 20 offers a neater way to write something (array notation, `⎕VGET`, `⎕VSET`), the READMEs show both versions.

## What's in this repository

| Folder | Contents |
|:-------|:---------|
| `Exercises/` | `Setup.aplf`, the workshop README, and one folder per exercise |
| `Source/` | The tools, in the versions the exercises were written for: HttpCommand 5.11.2, Jarvis 1.23.1, and WebSocketClient 1.0.1 (a version that runs on Dyalog 19.0) |
| `Presentation/` | The slides for the talks (PowerPoint) |

Each Markdown file has an `.html` copy next to it, for reading in a browser.

Everything runs on your own machine, on `localhost`. The only exception is the first part of Exercise 1, which calls a public web service ([Official Joke API](https://official-joke-api.appspot.com)); its README has an offline alternative.

## Documentation

- HttpCommand: <https://dyalog.github.io/HttpCommand>
- Jarvis: <https://dyalog.github.io/Jarvis>
- WebSocketClient: <https://dyalog.github.io/WebSocketClient/>
- Dyalog documentation: <https://docs.dyalog.com>

## Licence

[MIT](LICENSE)
