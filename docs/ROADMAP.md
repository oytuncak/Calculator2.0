# Roadmap

Calculator 2.0 is built in verifiable milestones. M1 (the foundation) is done;
the architecture below is already seamed for everything that follows.

## ✅ M1 — Foundation (shipped)
Infinite canvas, live results, linked/referenced numbers (cascade + cycle
isolation), text notes, basic arithmetic engine, `.calc2x` persistence, dark mode.

## M2 — Structure & export
- **Projects → Tabs hierarchy**: a Projects browser; each project holds multiple
  named canvases shown as tabs. (`Project`/`CanvasDoc` already model this.)
- Native file persistence via `path_provider` alongside the current storage.
- **Excel (`.xlsx`) export** with labels & formatting (`excel` package).
  Linked numbers become live spreadsheet formulas (`=B4*…`) where the layout maps
  cleanly to cells; text elements become label cells.

## M3 — Graphics
- `ChartElement` rendered with `fl_chart`, subscribing to result providers so
  charts update live as values cascade (line / bar / pie).

## M4 — Engine extension
- Named **variables** and **scientific functions** (`sin`, `cos`, `sqrt`, `^`, …)
  via the `FunctionRegistry` + `EvalContext` seams — no parser surgery required.
- Unit grammar groundwork for conversions.

## M5 — AI ("talk to the calculator")
The app already depends on the `AiAssistant` interface and mutates only through
the `DocumentCommand` bus, so AI plugs in without touching the canvas/engine.
- **Natural-language input**: "18% tip on 240 split 3 ways" → an equation.
- **Explain / show steps** for any result.
- **Smart unit & currency conversion** with **live exchange rates**.
- **Suggestions & cleanup** (name variables, tidy the canvas).
- A separate **Node/TypeScript MCP server** exposes tools (`add_equation`,
  `link`, `read_canvas`, `export_xlsx`) that map 1:1 to `DocumentCommand`s, letting
  Claude drive the calculator through the same pipeline the UI uses. Model access
  lives in the MCP server, not the app.
