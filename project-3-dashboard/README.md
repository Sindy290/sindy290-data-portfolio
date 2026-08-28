# Coffee Shop Sales — Interactive Dashboard

Project 3 in a data analyst portfolio. A single-page, interactive sales
dashboard built on the same 149,116-transaction dataset used in Projects 1
(Excel) and 2 (SQL + Python) — this project's job is presentation and
interactivity, not new analysis.

**Live demo:** deploy `index.html` (see below) or open it directly in any browser — no build step, no server required.

## Business question
Can a store manager or executive answer "how are we doing, and where"
in under 30 seconds, without opening a spreadsheet?

## What it does
- Click a store filter (**All / Lower Manhattan / Hell's Kitchen / Astoria**)
  and every KPI and chart updates instantly from pre-aggregated data —
  no server, no API calls, everything runs client-side.
- Four charts: monthly revenue trend, revenue by category, revenue by
  weekday, and revenue by hour (the staffing view).
- KPI strip: total revenue, transactions, average ticket, units sold.

## Design decisions
- **Why not Power BI/Tableau:** this was originally scoped as a Power BI
  dashboard, but was rebuilt as a standalone web dashboard so it can be
  hosted and linked directly (GitHub Pages, Netlify) rather than requiring
  a viewer to have Power BI Desktop installed. If a specific job posting
  calls for Power BI specifically, the same aggregate tables in
  `dashboard_data.json`-equivalent form (embedded in `index.html`) can be
  rebuilt there quickly — the queries and findings are already worked out.
- **Visual design is grounded in the data's own origin:** this is
  point-of-sale receipt data, so the KPI strip is styled as a receipt
  ("line items" with dotted leaders, a perforated-edge header/footer),
  and figures use a monospace typeface — a deliberate choice tied to the
  subject, not a generic dashboard template.
- **Data is pre-aggregated, not the raw 149K rows:** four small lookup
  tables (by store × month / category / weekday / hour) are embedded
  directly in the HTML as JSON (~10KB total), so the page loads instantly
  and the store filter has no latency. The full transaction-level data
  lives in Projects 1 and 2 for anyone who wants to audit the source.

## Tech stack
Plain HTML/CSS/JS + [Chart.js](https://www.chartjs.org/) (via CDN). No
framework, no build tools — intentionally, so it's viewable by opening
the file directly and easy for anyone to read the source.

## Key findings surfaced in the dashboard
- Store revenue is balanced (32.9%–33.9% split) — no location is
  under- or over-performing.
- Revenue more than doubled from February to June.
- Coffee + Tea drive roughly two-thirds of all revenue.
- 8–10am generates over a third of daily revenue — the clearest
  staffing signal in the data.
- Weekday revenue is flat — this is a commuter business, not a
  weekend one.

## How to deploy
**GitHub Pages** (recommended — free, gives you a live link for your resume):
1. Push this folder to a GitHub repo.
2. Repo → Settings → Pages → set source to the branch/folder containing `index.html`.
3. Your live dashboard will be at `https://<username>.github.io/<repo>/`.

**Or just open `index.html` directly in any browser** — it's fully self-contained.

## Related projects
- Project 1: Excel pivot-table analysis of the same dataset
- Project 2: Normalized SQL database + Python analysis notebook
