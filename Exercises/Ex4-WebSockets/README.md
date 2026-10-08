# Exercise 4: WebSockets

**Time:** 30 minutes. Steps marked **core** fit in the time; steps marked **stretch** are optional.

## Objectives

- Build a chat service with **WebSockets**: messages flow both ways over one connection
- Handle a connection opening, a message arriving, and a connection closing, with three Jarvis hooks
- Send a message to one client, or to everyone
- Join the same chat from APL, using **WebSocketClient**

## Background

In Exercise 3, the server pushed events, but the browser could only listen. A **WebSocket** is a two-way connection: it starts as an ordinary HTTP request that asks to "upgrade", and once the server agrees, either side can send a message at any time until one of them closes it. That's what you need for a chat: everyone sends, and everyone receives.

Jarvis supports WebSockets through settings that `Run4` makes for you, and three **hook** functions that you write, in `#.Ex4`:

| Jarvis setting | Your function | Jarvis calls it when |
|:---------------|:--------------|:---------------------|
| `OnWsUpgradeFn` | `Connect ns` | a client opens a WebSocket |
| `OnWsReceiveFn` | `Receive msg` | a client sends a message |
| `OnWsCloseFn` | `Disconnect ns` | a connection closes |

`ns` is the connection's namespace: `ns.conx` is the connection's **name**, and `ns.Server` is the Jarvis server. In `Receive`, `msg.Payload` is the text the client sent, and `msg.##` is the connection's namespace. All three hooks must return a result: 0 means "carry on"; anything else from `Connect` or `Receive` closes the connection.

To send, use the server's `WsSend`: `names server.WsSend data` sends `data` (a namespace is sent as JSON) to one or more connections, given by name. Keep a list of the names in `Clients`, a variable in `#.Ex4` that `Run4` sets to `⍬`. (Use the names, not the connection namespaces: `WsSend` accepts one namespace, but not a list of them.)

Everything sent is JSON. The page sends `{"type":"join","user":"Ada"}` when you join, and `{"type":"msg","text":"Hello"}` for each message. Your server sends each one on to everyone, adding the sender's name and the time: `{"type":"msg","user":"Ada","text":"Hello","time":"14:05:12"}`.

Two helpers are supplied in `#.Ex4`: `Now` returns the time as `hh:mm:ss`, and `ns Reply 'text'` sends `{"type":"error","text":"..."}` to that one connection.

## Getting started

If you haven't already, start Dyalog and run `Setup` (see [the workshop README](../README.md#3-run-setup)):

```apl
2 ⎕FIX 'file://<repo>/Exercises/Setup.aplf'
Setup ''
```

Then load this exercise: `Load 4` loads its `Run4` function and the supplied `Chat` namespace, which you'll use in W5. From here on, every line can be pasted as is:

```apl
Load 4
```

## Steps

### W1. Start the chat server (core)

```apl
server←Run4 8084
```

Open <http://localhost:8084> in your browser, type a name, and click **Join**. The page shows `Error: Receive is not written yet`: the starting version replies to every message with that error.

Your changes to the three hooks take effect as soon as you close the editor; there's no need to restart the server. Each time, click **Leave** and **Join** again on the page to start a fresh connection.

### W2. Write Connect (core)

```apl
)ED #.Ex4.Connect
```

Add the connection's name to `Clients`, so that `Receive` can send to everyone. Two clients can connect at once, so do it under a hold:

```apl
:Hold 'Ex4Clients'
    Clients,←⊂ns.conx
:EndHold
```

Keep `r←0` at the end. Check your work: Leave and Join on the page, then `≢#.Ex4.Clients` is at least 1.

### W3. Write Receive (core)

```apl
)ED #.Ex4.Receive
```

Replace the two lines at the end with code that:

1. Finds the connection and reads the JSON, replying with an error if it isn't a JSON object:

   ```apl
   r←0
   ns←msg.##
   in←{0::⍬ ⋄ ⎕JSON ⍵}msg.Payload
   :If 9≠⌊⎕NC'in'
       ns Reply'Messages must be JSON objects'
       →0
   :EndIf
   ```

2. Gets the message's `type`, or `''` if there isn't one:

   ```apl
   ⍝ Dyalog 19
   type←{6::'' ⋄ ⍵.type}in
   ```

   ```apl
   ⍝ Dyalog 20 alternative
   type←in ⎕VGET ⊂'type' ''
   ```

3. Uses `:Select type` to build the message `out` to send to everyone:
   - for `'join'`: remember the name with the connection, `ns.User←in.user`, then

     ```apl
     ⍝ Dyalog 19
     out←⎕NS'' ⋄ out.(type user time)←'join' ns.User Now
     ```

     ```apl
     ⍝ Dyalog 20 alternative
     out←(type: 'join' ⋄ user: ns.User ⋄ time: Now)
     ```

   - for `'msg'`: the same, with `'msg'`, the user, and `in.text`. If someone sends a message without joining, `ns.User` doesn't exist; `{6::'anonymous' ⋄ ⍵.User}ns` gives "anonymous" instead (Dyalog 20: `ns ⎕VGET ⊂'User' 'anonymous'`).
   - for anything else (`:Else`): `ns Reply'Unknown message type'` and `→0`.

4. Sends `out` to everyone: `Clients ns.Server.WsSend out`.

Check your work: open <http://localhost:8084> in a **second tab**, and join with a different name in each. Both tabs show both joins, and a message typed in one appears in both, with the sender's name and the time.

### W4. Write Disconnect (core)

```apl
)ED #.Ex4.Disconnect
```

Remove the connection's name from `Clients` (`Clients~←⊂ns.conx`, under the same `:Hold`), and if the user had joined (`2=⌊ns.⎕NC⊂'User'`), send everyone a `leave` message, built like the `join` one in W3.

Check your work: click **Leave** in one tab, or close it. The other tab shows "... left".

### W5. Join from APL (core)

The supplied `Chat` namespace, which `Load 4` loaded, is a chat client written with **WebSocketClient**:

```apl
Chat.Join 'APL'
Chat.Say 'Hello from APL'
```

Your browser tabs show APL joining and its message, and every message anyone sends is printed in your session. `Chat.Messages` keeps them all as namespaces. Type in a browser tab and watch it appear in APL.

Have a look at `Chat.Join` (`)ED Chat.Join`). It creates the client from a namespace of settings, like `HttpCommand.New` in Exercise 1:

```apl
⍝ Dyalog 19
s←⎕NS'' ⋄ s.(URL OnWSReceive)←'ws://localhost:8084/chat' '#.Chat.ShowMessage'
c←WebSocketClient.New s
```

```apl
⍝ Dyalog 20 alternative
c←WebSocketClient.New (URL: 'ws://localhost:8084/chat' ⋄ OnWSReceive: '#.Chat.ShowMessage')
```

(`Chat.Join` also sets `WaitTime←1000`: `Close` waits for the listener, so a short wait makes `Chat.Leave` quick.)

`OnWSReceive` names the function WebSocketClient calls for each message received, and **that function must be dyadic**: `client ShowMessage message`, with the text in `message.buffer`. A monadic function there fails inside WebSocketClient's listener thread, and the connection silently closes, with no error in your session. Like `HttpCommand.New`, `WebSocketClient.New` doesn't signal an error for a misspelled setting; it returns a result with a non-zero `rc` (here ¯11), so check it:

```apl
s←⎕NS'' ⋄ s.Url←'ws://localhost:8084/chat'
(WebSocketClient.New s).(rc msg)
```

### W6. Stop (core)

```apl
Chat.Leave
server.Stop
```

The browser tabs show "not connected". Unlike Exercise 3's `EventSource`, a WebSocket does not reconnect by itself.

### S1. /me actions (stretch)

The page's `EDIT HERE` section (in `html/index.html`) has a ready-made example: remove the `//` from its two `if` lines, and "/me waves" is sent as `{"type":"action","text":"waves"}` and shown as "* Ada waves". Reload the page after saving. Then make `Receive` send `action` messages on to everyone, like `msg`.

### S2. Better names (stretch)

Two people can join with the same name, and joining twice quietly renames you. Make `Receive` refuse a name that someone else is using (`Reply` with an error), and announce a change of name.

### S3. An APL bot (stretch)

Write a second `Chat`-style client (copy `Chat.apln` under a new name) whose `ShowMessage` answers messages starting with `/apl`, for example replying to `/apl 2+3` with `5`.

**Warning:** never use `⍎` on text from the network. Anyone who can reach your server could send `/apl ⎕OFF` to stop your APL, or `/apl ⎕SH 'any command at all'` to run whatever they like on your machine. Instead, check the text against a tight allow-list first, for example only digits, spaces, and `+-×÷`, and refuse anything else. Treat any program that runs code from messages as dangerous.

## Catching up

If time is up or you're stuck, load the solution. `Run4` stops the earlier server first:

```apl
server←'Solution' Run4 8084
```

Then click **Join** again in each tab, and `Chat.Join 'APL'` again in APL: restarting the server closes every connection.

Changes you make with `)ED` will update the in-session copy and the source file in `Start/`. The finished versions are in `Solution/`.

## Documentation

- Jarvis, including WebSockets: <https://dyalog.github.io/Jarvis>
- WebSocketClient: <https://dyalog.github.io/WebSocketClient/>
- WebSockets in the browser: <https://developer.mozilla.org/en-US/docs/Web/API/WebSocket>
