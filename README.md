# Calculator 2.0

A new-generation **canvas calculator** for the AI age — inspired by the best of
[Tydlig](http://tydligapp.com/) and [Calvance](https://apps.apple.com/us/app/calvance-calculator-on-canvas/id6739774242).
Type expressions anywhere on an infinite canvas, edit any number and watch every
result recompute **live**, and **link** results between equations so changes
cascade.

Built with **Flutter** (one codebase for iOS, Android, and web).

## Status — Milestone 1 (foundation)

- ✅ Infinite pan/zoom canvas with draggable elements
- ✅ Equation elements with **live results** (`+ − × ÷ %`, parentheses, contextual percent)
- ✅ **Linked / referenced numbers** — drag a result onto another equation to link it;
  edits cascade down the chain (cycles are isolated, not fatal)
- ✅ Text note / label elements
- ✅ Local persistence (`.calc2x` JSON document) + dark mode
- ✅ Pure-Dart engine with full unit + widget test coverage

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for what's next (Projects & tabs, Excel
export, charts, scientific functions, and the AI / Claude-MCP layer).

## Architecture

```
lib/
  domain/        pure Dart, no Flutter imports (engine, model, graph, codec)
    engine/      lexer → parser (Pratt) → evaluator + EvalContext seam
    graph/       DependencyGraph + RecomputeEngine (topological cascade)
    model/       Project → CanvasDoc (tab) → CanvasElement (equation / text)
    serialization/  .calc2x JSON codec
  data/          persistence repository
  state/         Riverpod controllers (single command bus → recompute → save)
  features/      canvas UI (view, element widgets, painters)
  ai/            AiAssistant interface + DocumentCommand bus (deferred impl)
```

Every document mutation flows through the sealed `DocumentCommand` bus, so the
UI and the future AI/MCP layer share one path and recompute identically.

## Develop

```bash
flutter pub get
flutter test                 # unit + widget tests
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0   # run in a browser
flutter run                  # run on a connected device / simulator
```

> iOS/Android release packaging needs a Mac or a cloud build service
> (e.g. Codemagic); all logic and UI are verifiable via the web build.
