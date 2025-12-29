---
title: I wrote a Vibe Check for your code (Runs on a Potato 🥔)
published: false
description: A 149KB static binary that scans your codebase for unfinished vibes like TODOs and hardcoded secrets.
tags: zig, cli, devops, humor
cover_image: https://raw.githubusercontent.com/copyleftdev/vibecheck/master/media/logo.png
---

You know that feeling when you push code at 3 AM and you're pretty sure you left a `// FIXME: this is garbage` somewhere? 

Yeah. We all do.

So I wrote a tool to find it. But not just "find it"—I wanted a tool that would look me in the eye and tell me my vibes were off.

## Meet VibeCheck 🤙

**VibeCheck** is a high-performance **Zig** CLI tool that scans your codebase for "unfinished vibes"—To-Dos, hardcoded secrets, debug prints, and other signs of developer desperation.

It builds to a single **~149KB static binary**. No runtime. No `node_modules` black hole. It runs on my laptop, my server, and probably my smart fridge.

![VibeCheck Logo](https://raw.githubusercontent.com/copyleftdev/vibecheck/master/media/logo.png)

### Why? (The Vibe)

Linters check syntax. Static analysis checks logic. **VibeCheck checks your soul.**

It comes with a built-in pack called **Crucial Vibes**:
*   **Desperation**: `FIX ME`, `XXX`
*   **Mock Data**: `lorem ipsum`, `John Doe`
*   **Fragile Paths**: `localhost:3000`
*   **Security Laziness**: `verify=False`, `chmod 777`

If it finds them, it lets you know. Loudly.

### The Specs (The Flex)

I built this in **Zig** because I wanted it to be fast and small.

*   **Size**: 149KB (Statically linked, stripped)
*   **Speed**: Scanned a 50,000 file monorepo in < 1 second.
*   **Deps**: Zero. None. Nada.
*   **AI Mode**: It has a built-in **MCP Server** so you can plug it into Claude Desktop and let the AI vibe check your code. 🤖

### Usage

It's simple. 

```bash
# Human readable scan
vibecheck .
```

Output:
```
[WARN]  Desperation Marker (FIXME)
  src/main.js:42:10
    | // FIXME: terrible hack, remove before launch
```

Or plug it into CI/CD to fail the build if the vibes are off:
```bash
vibecheck . --json
```

### Get It

It's open source (MIT).

{% github copyleftdev/vibecheck %}

Go give it a star, or better yet, run it on your focused project and see just how "unfinished" those vibes really are.

Happy coding. 🤙
