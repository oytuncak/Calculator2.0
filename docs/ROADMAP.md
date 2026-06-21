# Roadmap

Calculator 2.0 is built in verifiable milestones. M1 (the foundation) is done;
the architecture below is already seamed for everything that follows.

## ✅ M1 — Foundation (shipped)
Infinite canvas, live results, linked/referenced numbers (cascade + cycle
isolation), text notes, basic arithmetic engine, `.calc2x` persistence, dark mode.

## ✅ M2 — Structure & export (shipped)
- **Projects** browser (side drawer): create / switch / rename / delete; the
  workspace persists all projects and the open project/canvas.
- **Tabs**: multiple named canvases per project (add / rename / delete / switch).
- **Excel (`.xlsx`) export** with labelled rows & bold headers (`excel` package,
  pure Dart); `@id` references rewritten to readable names; web download / device
  share via `file_saver`.
- _Next for export_: map the canvas spatially to cells and emit live spreadsheet
  formulas (`=B4*…`) for linked numbers (currently literal values).

## ✅ M3 — Graphics (shipped)
- `ChartElement` rendered with `fl_chart` (bar / line / pie). A chart stores only
  references to its source equations and reads their results at render time, so it
  updates live as values cascade. Drop an equation's result pill onto a chart to add
  a series; switch chart type inline. Charts move/persist like any element.
- _Next for charts_: per-series labels/legend, axis ranges, and exporting charts
  into the `.xlsx` (currently visual-only).

## ✅ M4a — Scientific functions (shipped)
- **Functions** (`sin`/`cos`/`tan`, `asin`…/`sinh`…, `sqrt`/`cbrt`, `ln`/`log`/`log10`,
  `exp`, `abs`/`round`/`floor`/`ceil`, `min`/`max`/`avg`/`sum`, `pow`/`root`/`mod`/`hypot`,
  `rad`/`deg`), **constants** (`pi`, `e`, `tau`), and the **`^` exponent** operator —
  all via the `FunctionRegistry` + lexer-identifier seam. They work in any equation
  immediately (the recompute engine uses the standard registry).
- Note: comma is now a function-argument separator (typed thousands separators dropped).

## ✅ M4b — Named variables (shipped)
- Name an equation (the italic "name" field on each card) and reference it by name in
  others (`subtotal * 1.2`). Names resolve through `EvalContext.resolveVariable`; the
  recompute engine adds dependency edges so name edits cascade and name cycles are
  isolated. Only plain identifiers (not reserved constants) are usable as names.

## M5 — AI ("talk to the calculator")
- Real `AiAssistant` + a Node/TS **MCP server** driving `DocumentCommand`s; natural-language
  input, explain-steps, smart unit & **live currency** conversion, cleanup suggestions.

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
