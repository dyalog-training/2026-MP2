# Exercise 1: Introducing the tools

**Time:** 30 minutes. Part A (about 10 minutes) uses **HttpCommand** to call a public web service. Part B (about 20 minutes) uses **Jarvis** to build your own web service and call it from your browser and from APL.

Steps marked **core** fit in the time. Steps marked **stretch** are optional.

## Objectives

- Make HTTP requests from APL with HttpCommand, and read the response
- Tell the difference between "the request failed" and "the server said no"
- Write a Jarvis web service with two endpoints and start it on `localhost`
- Call your service from a browser and from APL, with a JSON body and with a query string

## Getting started

If you haven't already, start Dyalog and run `Setup` (see [the workshop README](../README.md#3-run-setup)):

```apl
2 ⎕FIX 'file://<repo>/Exercises/Setup.aplf'
Setup '<repo>'
```

Then load this exercise's `Run` function. From here on, every line can be pasted as is:

```apl
2 ⎕FIX 'file://',#.WorkshopRoot,'/Exercises/Ex1-Tools/Run.aplf'
```

## Part A: HttpCommand and a public web service

We use the [Official Joke API](https://official-joke-api.appspot.com/random_joke), which needs no sign-up or key. Its endpoints:

| Endpoint | Returns |
|----------|---------|
| `/random_joke` | one joke: `type`, `setup`, `punchline`, `id` |
| `/types` | the joke types |
| `/jokes/{type}/random` | a list holding one joke of that type |
| `/jokes/random/{n}` | a list of `n` jokes |
| `/jokes/{id}` | one joke, or HTTP status 404 if there's no such joke |

> **No network?** Do Part B first, then come back and run steps A1 to A4 against your own service: use `http://localhost:8080/` (your service's home page) instead of a joke URL. For the step A4 "server said no" example, use `http://localhost:8080/NoSuchEndpoint`: you get status 400 (Bad Request) rather than 404, but the lesson is the same.

### A1. Make a request (core)

```apl
r←HttpCommand.Get 'https://official-joke-api.appspot.com/random_joke'
r
r.(rc HttpStatus)
r.Headers
r.Data
```

`r` is a namespace describing the response:

- `rc` is 0 if the request itself worked (HttpCommand reached the server and got an answer)
- `HttpStatus` is the server's answer: 200 means OK
- `Headers` are the response headers, as a two-column matrix
- `Data` is the response body. Here it's JSON, as a character vector

### A2. Get APL data instead of JSON text (core)

Create an HttpCommand instance and set `TranslateData` so that a JSON response is converted to a namespace:

```apl
h←HttpCommand.New 'get' 'https://official-joke-api.appspot.com/random_joke'
h.TranslateData←1
r←h.Run
r.Data.setup
r.Data.punchline
```

Run `r←h.Run` again for another joke.

### A3. Several calls to the same host with BaseURL (core)

When you make several calls to the same server, set `BaseURL` once and then give just the rest of the address in `URL`:

```apl
h←HttpCommand.New 'get'
h.BaseURL←'https://official-joke-api.appspot.com'
h.TranslateData←1
h.URL←'random_joke' ⋄ r←h.Run
r.Data.(setup punchline)
```

How `URL` and `BaseURL` combine:

- `URL` is added to the end of `BaseURL`, with a `/` between them if needed, so `'random_joke'` and `'/random_joke'` both work
- a `URL` that starts with `http://` or `https://` is used as it is, ignoring `BaseURL`
- settings such as `TranslateData` apply to every call made with the instance

You can also give `HttpCommand.New` a namespace of settings, so the instance is set up in one step. Dyalog 20's array notation makes this especially neat:

```apl
⍝ Dyalog 19
s←⎕NS''
s.(Command BaseURL TranslateData)←'get' 'https://official-joke-api.appspot.com' 1
h←HttpCommand.New s
```

```apl
⍝ Dyalog 20 alternative
h←HttpCommand.New (Command: 'get' ⋄ BaseURL: 'https://official-joke-api.appspot.com' ⋄ TranslateData: 1)
```

A settings namespace can be kept and used to create several instances. If you misspell a setting, `New` doesn't signal an error; it returns a result with a non-zero `rc` instead, so check what you got back:

```apl
s←⎕NS'' ⋄ s.BaseUrl←'https://official-joke-api.appspot.com'
b←HttpCommand.New s
b.(rc msg)
```

This shows `rc` ¯1 and the message `Invalid HttpCommand setting(s): BaseUrl` (it should be `BaseURL`).

### A4. "The request failed" or "the server said no"? (core)

Ask for a joke that doesn't exist, using the instance `h` from A3:

```apl
h.URL←'jokes/999999' ⋄ r←h.Run
r.(rc HttpStatus)
```

Check your work: `rc` is 0, because the request worked, but `HttpStatus` is 404 (Not Found), because the server said no. Always check both. Exercise 2 relies on this.

### A5. More endpoints (stretch)

With the same instance, try `types`, `jokes/programming/random`, and `jokes/random/3`. These return lists (arrays) of jokes, not single jokes. Build the URL in APL from a type or a count, for example:

```apl
h.URL←'jokes/random/',⍕3 ⋄ r←h.Run
↑r.Data.setup
```

## Part B: Your own web service with Jarvis

In Jarvis's JSON mode, every function in your code namespace is an **endpoint**: a client sends JSON in an HTTP POST to `/FunctionName`, Jarvis converts the JSON to APL and calls your function with it, and converts your function's result back to JSON for the reply.

Your service has two endpoints, in `#.Ex1`:

- `Hello`: takes `{"name":"Ada"}` and returns `{"greeting":"Hello, Ada!"}`; with no name, it greets "World"
- `Sum`: takes a list such as `[1,2,3]` and returns `{"count":3,"total":6}`

### B1. Start the service (core)

```apl
server←Run 8080
```

Jarvis prints a few log lines as it starts. One says `Click http://...:8080 to access web interface`, with your machine's network address; that works too, but use `localhost` as shown here. (The network address is a reminder that the server can be reached from your network: stop it when you're done, as in B6.)

Open <http://localhost:8080> in your browser. Jarvis's built-in page lets you pick an **Endpoint**, type a **JSON Payload**, and click **Send via HTTP**. Pick `Hello`, type `{"name":"Ada"}`, and send it: the response is `"Hello is not written yet"`. That's the starting version, waiting for you.

### B2. Write Hello (core)

Edit the function in your session:

```apl
)ED #.Ex1.Hello
```

Replace the placeholder line with code that returns a namespace with a `greeting`. Your change takes effect as soon as you close the editor; there's no need to restart the server.

Things to know:

- The argument `payload` is a namespace made from the JSON body: `{"name":"Ada"}` gives a namespace with `name←'Ada'`.
- If the request has no body at all, `payload` is `''`, not a namespace. Check with `9=⌊⎕NC'payload'`.
- A namespace result is sent back as a JSON object.

Getting `name` with a default of `'World'`, and building the result:

```apl
⍝ Dyalog 19
name←{6::'World' ⋄ ⍵.name}payload
r←⎕NS''
r.greeting←'Hello, ',(⍕name),'!'
```

```apl
⍝ Dyalog 20 alternative
name←payload ⎕VGET ⊂'name' 'World'
r←(greeting: 'Hello, ',(⍕name),'!')
```

Check your work: in the browser, `{"name":"Ada"}` gives `{"greeting":"Hello, Ada!"}` and `{}` gives `{"greeting":"Hello, World!"}`.

### B3. Write Sum (core)

```apl
)ED #.Ex1.Sum
```

The argument `numbers` is the JSON list, already an APL vector. Return a namespace with `total` and `count`.

Check your work: in the browser, pick `Sum` and send `[1,2,3]`: the response is `{"count":3,"total":6}`.

### B4. Call your service from APL (core)

`HttpCommand.GetJSON` sends an APL array as JSON and converts the JSON response back to APL:

```apl
⍝ Dyalog 19
p←⎕NS'' ⋄ p.name←'Ada'
```

```apl
⍝ Dyalog 20 alternative
p←(name: 'Ada')
```

```apl
r←HttpCommand.GetJSON 'post' 'localhost:8080/Hello' p
r.Data.greeting
r←HttpCommand.GetJSON 'post' 'localhost:8080/Sum' (1 2 3)
r.Data.(total count)
```

Check your work: `Hello, Ada!`, then `6 3`.

### B5. Use a query string (core)

Browsers usually send data in the URL, as a **query string**: `/Hello?name=Ada`. Jarvis refuses this by default; try it, and you get HTTP status 400 (Bad Request):

```apl
(HttpCommand.Get 'localhost:8080/Hello?name=Ada').HttpStatus
```

Allow it by setting `AllowGETs` and restarting the server:

```apl
server.Stop
server.AllowGETs←1
server.Start
```

Now open <http://localhost:8080/Hello?name=Ada> in your browser, and try it from APL:

```apl
r←HttpCommand.GetJSON 'get' 'localhost:8080/Hello?name=Ada'
r.Data.greeting
```

Jarvis turns the query string into the same namespace as the JSON body, so `Hello` didn't need to change.

### B6. Stop the service (core)

```apl
server.Stop
```

Stop your server whenever you finish with it: it listens on your network as well as on `localhost`.

### B7. An endpoint that says no (stretch)

Write a `Divide` endpoint that takes `{"a":6,"b":3}` and returns `2`, but responds with HTTP status 400 if `b` is 0. To get at the request, make the endpoint **dyadic**: Jarvis passes the request object as the left argument, and `'message' req.Fail 400` sets the status. Create it with `)ED #.Ex1.Divide`, then try it from the browser (reload the page and it appears in the Endpoint list) and from APL, and look at `rc` and `HttpStatus` as in A4. The solution is in `Solution/Divide.aplf`.

## Debugging your endpoints

By default Jarvis traps errors in your endpoints and replies with HTTP status 500. To stop in the tracer instead, set:

```apl
server.Debug←1
```

then send the request **from your browser**. (If you call the service from the same APL session, that session is busy waiting for the reply.) Set `server.Debug←0` to go back to normal.

## Catching up

If time is up or you're stuck, load the solution:

```apl
server.Stop
server←'Solution' Run 8080
```

Changes you make with `)ED` live in your session; the files in `Start/` don't change. The finished versions are in `Solution/`.

## Documentation

- HttpCommand: <https://dyalog.github.io/HttpCommand>
- Jarvis: <https://dyalog.github.io/Jarvis>
