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
