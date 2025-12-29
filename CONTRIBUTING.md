# Contributing to VibeCheck

First off, thanks for taking the time to keep the vibes immaculate! 🤙

## How to Contribute

### Reporting Bugs
If you find a bug (or a bad vibe), open an issue. Please include:
- Your OS and VibeCheck version
- A command to reproduce
- What happened (and what you expected)

### Suggesting Enhancements
We love new vibes. If you have an idea for a core pattern or a totally new feature (like MCP integration!), open an issue to discuss it first.

### Pull Requests
1. Fork the repo.
2. Create a branch (`git checkout -b feature/amazing-vibe`).
3. Hack away. Keep it Ziggy.
4. Run tests (or just verify `zig build run` passes cleanly).
5. Push and open a PR.

## Fuzzing 🐝
We use Zig's built-in fuzzer to stress-test the Matcher engine.
To run the fuzzer:
```bash
zig build test --fuzz
```
This will run indefinitely, feeding random input to `Matcher.scanFile`.

## Style Guide
- **Zig Format**: Run `zig fmt .` before committing.
- **Errors**: Handle them properly. No `catch unreachable` unless you are absolutely certain.
- **Vibes**: Keep comments helpful and funny but professional-ish.

## Vibe Packs
If you want to share a custom Vibe Pack:
1. Add it to `examples/`.
2. Document what it catches in `README.md` or a new wiki page.

Happy coding!
