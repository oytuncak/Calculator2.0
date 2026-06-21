# Calculator 2.0

A new-generation **canvas calculator** for the AI age — inspired by the best of
[Tydlig](http://tydligapp.com/) and [Calvance](https://apps.apple.com/us/app/calvance-calculator-on-canvas/id6739774242).
Type expressions anywhere on an infinite canvas, edit any number and watch every
result recompute **live**, and **link** results between equations so changes
cascade.

Built with **Flutter** (one codebase for iOS, Android, and web).

## Status

**Milestone 1 — foundation**
- ✅ Infinite pan/zoom canvas with draggable elements
- ✅ Equation elements with **live results** (`+ − × ÷ %`, parentheses, contextual percent)
- ✅ **Linked / referenced numbers** — drag a result onto another equation to link it;
  edits cascade down the chain (cycles are isolated, not fatal)
- ✅ Text note / label elements
- ✅ Local persistence (JSON document) + dark mode

**Milestone 2 — structure & export**
- ✅ **Projects** — multiple projects via a side drawer (create / switch / rename / delete)
- ✅ **Tabs** — multiple canvases per project, with add / rename / delete
- ✅ **Excel export** — export the current canvas to a formatted `.xlsx` (web download / device share)

**Milestone 3 — charts/graphics**
- ✅ **Chart elements** — bar / line / pie charts on the canvas; drop an equation's
  result onto a chart to add it as a series, and the chart **updates live** as values cascade

**Milestone 4 — scientific functions & named variables**
- ✅ **Functions** (`sin`, `cos`, `sqrt`, `ln`, `log`, `min`/`max`, `pow`, …), **constants**
  (`pi`, `e`, `tau`), and the **`^` exponent** operator — usable directly in any equation
- ✅ **Named variables** — name an equation (e.g. `subtotal`) and reference it by name in
  others (`subtotal * 1.2`); edits cascade like links, cycles are isolated

**Milestone 5 — AI**
- ✅ **Natural-language input** (✨ Ask AI) — describe a calculation in plain English and it
  becomes a live equation. **Bring-your-own-key**: paste your Anthropic API key (stored
  locally); the app calls Claude directly.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for what's next (explain-steps, live currency, MCP server).

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

## Credits

Developed by **Gastronaut**.
