import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const toolPath =
  "file:///C:/Users/ROG%20G16%20STRIX/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const {
  PresentationFile,
  row,
  column,
  grid,
  layers,
  panel,
  text,
  shape,
  rule,
  fill,
  fixed,
  wrap,
  hug,
  grow,
  fr,
} = await import(toolPath);

const W = 960;
const H = 540;
const OUT = "artifacts";
const PREVIEW = join(OUT, "previews");
mkdirSync(PREVIEW, { recursive: true });

const deck = await PresentationFile.importPptx(readFileSync(join(OUT, "solution_challenge_template.pptx")));

const C = {
  blue: "#1A73E8",
  gBlue: "#4285F4",
  red: "#EA4335",
  yellow: "#FBBC04",
  green: "#34A853",
  ink: "#202124",
  muted: "#5F6368",
  soft: "#F8FAFD",
  line: "#DADCE0",
  paleBlue: "#E8F0FE",
  paleGreen: "#E6F4EA",
  paleRed: "#FCE8E6",
  paleYellow: "#FEF7E0",
  white: "#FFFFFF",
};

const font = "Google Sans";
const mono = "Roboto Mono";

function clean(slide) {
  slide.shapes.deleteAll();
}

function render(slide, root, frame = { left: 0, top: 62, width: W, height: H - 62 }) {
  slide.compose(root, { frame, baseUnit: 4 });
}

function titleBlock(title, subtitle, accent = C.blue) {
  return column({ name: "title-stack", width: fill, height: hug, gap: 8 }, [
    text(title, {
      name: "slide-title",
      width: fill,
      height: hug,
      style: { fontFamily: font, fontSize: 34, bold: true, color: C.ink },
    }),
    rule({ name: "title-rule", width: fixed(96), weight: 4, stroke: accent }),
    text(subtitle, {
      name: "slide-subtitle",
      width: wrap(770),
      height: hug,
      style: { fontFamily: font, fontSize: 15, color: C.muted },
    }),
  ]);
}

function smallLabel(value, color = C.blue, bg = C.paleBlue) {
  return panel(
    {
      name: `label-${value}`,
      width: hug,
      height: hug,
      padding: { x: 10, y: 5 },
      fill: bg,
      line: color,
      borderRadius: 8,
    },
    text(value.toUpperCase(), {
      width: hug,
      height: hug,
      style: { fontFamily: font, fontSize: 8.5, bold: true, color },
    }),
  );
}

function bullet(label, body, color = C.blue) {
  return row({ width: fill, height: hug, gap: 10, align: "start" }, [
    panel(
      {
        width: fixed(19),
        height: fixed(19),
        fill: color,
        borderRadius: 6,
        padding: 0,
        align: "center",
        justify: "center",
      },
      text("✓", {
        width: hug,
        height: hug,
        style: { fontFamily: font, fontSize: 10, bold: true, color: C.white },
      }),
    ),
    column({ width: fill, height: hug, gap: 2 }, [
      text(label, {
        width: fill,
        height: hug,
        style: { fontFamily: font, fontSize: 15, bold: true, color: C.ink },
      }),
      text(body, {
        width: fill,
        height: hug,
        style: { fontFamily: font, fontSize: 11.5, color: C.muted },
      }),
    ]),
  ]);
}

function card(title, body, color = C.blue, options = {}) {
  return panel(
    {
      width: fill,
      height: options.height ?? hug,
      padding: { x: 14, y: 12 },
      fill: options.fill ?? C.white,
      line: options.line ?? C.line,
      borderRadius: 8,
    },
    column({ width: fill, height: fill, gap: 6 }, [
      row({ width: fill, height: hug, gap: 8, align: "center" }, [
        shape({ width: fixed(10), height: fixed(10), fill: color, geometry: "ellipse" }),
        text(title, {
          width: fill,
          height: hug,
          style: { fontFamily: font, fontSize: 14, bold: true, color: C.ink },
        }),
      ]),
      text(body, {
        width: fill,
        height: hug,
        style: { fontFamily: font, fontSize: 11, color: C.muted },
      }),
    ]),
  );
}

function metric(value, label, color) {
  return column({ width: fill, height: hug, gap: 4 }, [
    text(value, {
      width: fill,
      height: hug,
      style: { fontFamily: font, fontSize: 31, bold: true, color },
    }),
    text(label, {
      width: fill,
      height: hug,
      style: { fontFamily: font, fontSize: 10.5, color: C.muted },
    }),
  ]);
}

function root(children, gap = 18) {
  return column(
    {
      name: "content-root",
      width: fill,
      height: fill,
      padding: { x: 42, y: 24 },
      gap,
    },
    children,
  );
}

function googleMark() {
  return grid(
    {
      name: "google-mark",
      width: fixed(54),
      height: fixed(54),
      columns: [fr(1), fr(1)],
      rows: [fr(1), fr(1)],
      columnGap: 5,
      rowGap: 5,
    },
    [
      shape({ fill: C.gBlue, borderRadius: 4, width: fill, height: fill }),
      shape({ fill: C.red, borderRadius: 4, width: fill, height: fill }),
      shape({ fill: C.green, borderRadius: 4, width: fill, height: fill }),
      shape({ fill: C.yellow, borderRadius: 4, width: fill, height: fill }),
    ],
  );
}

function flowStep(title, body, color, idx) {
  return column({ width: fill, height: hug, gap: 8, align: "center" }, [
    panel(
      {
        width: fixed(58),
        height: fixed(58),
        fill: color,
        borderRadius: 10,
        align: "center",
        justify: "center",
      },
      text(String(idx), {
        width: hug,
        height: hug,
        style: { fontFamily: font, fontSize: 24, bold: true, color: C.white },
      }),
    ),
    text(title, {
      width: fill,
      height: hug,
      style: { fontFamily: font, fontSize: 13.5, bold: true, color: C.ink, align: "center" },
    }),
    text(body, {
      width: fill,
      height: hug,
      style: { fontFamily: font, fontSize: 9.8, color: C.muted, align: "center" },
    }),
  ]);
}

function uiSurface(title, subtitle, color, variant) {
  const rows =
    variant === "scanner"
      ? [
          panel({ width: fill, height: fixed(50), fill: "#F8FAFD", line: C.line, borderRadius: 6, padding: { x: 10, y: 8 } }, text("Bias score 72/100", { width: fill, height: hug, style: { fontFamily: font, fontSize: 12, bold: true, color: C.red } })),
          panel({ width: fill, height: fixed(38), fill: C.paleRed, line: "#F2C2BE", borderRadius: 6, padding: { x: 10, y: 7 } }, text("Flagged: young, energetic, physical demands", { width: fill, height: hug, style: { fontFamily: font, fontSize: 9, color: C.red } })),
        ]
      : variant === "results"
        ? [
            row({ width: fill, height: hug, gap: 8 }, [metric("0.55", "Disparate impact", C.red), metric("-0.33", "Statistical parity", C.red)]),
            panel({ width: fill, height: fixed(28), fill: C.paleGreen, line: "#B7DEC0", borderRadius: 6, padding: { x: 10, y: 6 } }, text("Remediation lifts DI to 0.81", { width: fill, height: hug, style: { fontFamily: font, fontSize: 9.2, color: "#0D652D" } })),
          ]
        : [
            row({ width: fill, height: hug, gap: 8 }, [metric("12", "Audits", C.blue), metric("84%", "Fairness", C.green)]),
            panel({ width: fill, height: fixed(28), fill: C.paleBlue, line: "#BCD2F5", borderRadius: 6, padding: { x: 10, y: 6 } }, text("3 reviews need owner action", { width: fill, height: hug, style: { fontFamily: font, fontSize: 9.2, color: C.blue } })),
          ];

  return panel(
    { width: fill, height: fixed(245), fill: C.white, line: C.line, borderRadius: 10, padding: 0 },
    column({ width: fill, height: fill, gap: 12 }, [
      panel(
        { width: fill, height: fixed(42), fill: color, borderRadius: 10, padding: { x: 14, y: 10 } },
        text(title, { width: fill, height: hug, style: { fontFamily: font, fontSize: 13.5, bold: true, color: C.white } }),
      ),
      column({ width: fill, height: fill, padding: { x: 14, y: 0 }, gap: 10 }, [
        text(subtitle, { width: fill, height: hug, style: { fontFamily: font, fontSize: 10.5, color: C.muted } }),
        ...rows,
      ]),
    ]),
  );
}

function simpleTable(rows) {
  return column(
    { width: fill, height: hug, gap: 0 },
    rows.map((r, i) =>
      row(
        {
          width: fill,
          height: fixed(i === 0 ? 34 : 42),
          gap: 0,
          align: "center",
          padding: { x: 10, y: 0 },
        },
        [
          panel(
            {
              width: grow(1.1),
              height: fill,
              fill: i === 0 ? C.paleBlue : C.white,
              line: C.line,
              padding: { x: 10, y: 8 },
            },
            text(r[0], { width: fill, height: hug, style: { fontFamily: font, fontSize: i === 0 ? 10 : 11.5, bold: i === 0, color: C.ink } }),
          ),
          panel(
            {
              width: grow(1.8),
              height: fill,
              fill: i === 0 ? C.paleBlue : C.white,
              line: C.line,
              padding: { x: 10, y: 8 },
            },
            text(r[1], { width: fill, height: hug, style: { fontFamily: font, fontSize: i === 0 ? 10 : 11.5, bold: i === 0, color: i === 0 ? C.ink : C.muted } }),
          ),
          panel(
            {
              width: grow(1.1),
              height: fill,
              fill: i === 0 ? C.paleBlue : C.white,
              line: C.line,
              padding: { x: 10, y: 8 },
            },
            text(r[2], { width: fill, height: hug, style: { fontFamily: font, fontSize: i === 0 ? 10 : 11.5, bold: i === 0, color: i === 0 ? C.ink : C.green } }),
          ),
        ],
      ),
    ),
  );
}

deck.slides.items.forEach(clean);

// 1. Cover
render(
  deck.slides.items[0],
  layers({ width: fill, height: fill }, [
    shape({ name: "cover-blue-field", width: fill, height: fixed(180), fill: C.paleBlue }),
    column({ name: "cover-content", width: fill, height: fill, padding: { x: 56, y: 52 }, gap: 22 }, [
      row({ width: fill, height: hug, align: "center" }, [
        googleMark(),
        column({ width: fill, height: hug, gap: 4, padding: { x: 16, y: 0 } }, [
          text("Google Build AI Hackathon 2026", { width: fill, height: hug, style: { fontFamily: font, fontSize: 13, bold: true, color: C.blue } }),
          text("Prototype submission deck", { width: fill, height: hug, style: { fontFamily: font, fontSize: 10.5, color: C.muted } }),
        ]),
      ]),
      column({ width: wrap(680), height: hug, gap: 12 }, [
        text("Visora", { width: fill, height: hug, style: { fontFamily: font, fontSize: 70, bold: true, color: C.ink } }),
        text("Unbiased AI Decision", { width: fill, height: hug, style: { fontFamily: font, fontSize: 28, bold: true, color: C.yellow } }),
        text("Ensuring fairness and detecting bias in automated decisions before they affect jobs, loans, healthcare, or public access.", {
          width: fill,
          height: hug,
          style: { fontFamily: font, fontSize: 18, color: C.muted },
        }),
      ]),
      row({ width: fill, height: hug, gap: 14 }, [
        smallLabel("Gemini powered", C.blue, C.paleBlue),
        smallLabel("Fairness metrics", C.green, C.paleGreen),
        smallLabel("Firebase ready", C.yellow, C.paleYellow),
      ]),
    ]),
  ]),
  { left: 0, top: 0, width: W, height: H },
);

// 2. Team Details
render(
  deck.slides.items[1],
  root([
    titleBlock("Team Details", "Solution: Visora - AI Bias Audit Platform", C.blue),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1)], columnGap: 16, rowGap: 16 }, [
      card("Team name", "FairLens AI", C.gBlue, { fill: C.paleBlue }),
      card("Team leader", "Shashank", C.green, { fill: C.paleGreen }),
      card("Problem statement", "Unbiased AI Decision: ensuring fairness and detecting bias in automated decisions.", C.yellow, { fill: C.paleYellow }),
      card("Prototype focus", "A clear, accessible tool to measure, flag, explain, and reduce harmful algorithmic bias.", C.red, { fill: C.paleRed }),
    ]),
    panel(
      { width: fill, height: hug, padding: { x: 16, y: 12 }, fill: C.white, line: C.line, borderRadius: 8 },
      text("The deck is filled from the working Visora prototype in this project: Flutter Web app, Gemini AI text scanner, local dataset audit engine, PDF reporting, and Firebase Hosting configuration.", {
        width: fill,
        height: hug,
        style: { fontFamily: font, fontSize: 13, color: C.muted },
      }),
    ),
  ]),
);

// 3. Brief
render(
  deck.slides.items[2],
  root([
    titleBlock("Brief about your solution", "Visora audits datasets and AI decision text for hidden unfairness, then explains and reduces the risk.", C.green),
    row({ width: fill, height: hug, gap: 16 }, [
      panel({ width: grow(1), height: fixed(200), fill: C.paleRed, line: "#F2C2BE", borderRadius: 10, padding: { x: 18, y: 16 } }, column({ width: fill, height: fill, gap: 12 }, [
        text("Problem", { width: fill, height: hug, style: { fontFamily: font, fontSize: 20, bold: true, color: C.red } }),
        text("Automated systems can repeat historical discrimination in hiring, lending, healthcare, and service access.", { width: fill, height: hug, style: { fontFamily: font, fontSize: 14, color: C.ink } }),
      ])),
      panel({ width: grow(1.25), height: fixed(200), fill: C.paleGreen, line: "#B7DEC0", borderRadius: 10, padding: { x: 18, y: 16 } }, column({ width: fill, height: fill, gap: 12 }, [
        text("Solution", { width: fill, height: hug, style: { fontFamily: font, fontSize: 20, bold: true, color: C.green } }),
        text("Upload a CSV, select protected and target columns, compute fairness metrics, scan text with Gemini, and generate reports with remediation guidance.", { width: fill, height: hug, style: { fontFamily: font, fontSize: 14, color: C.ink } }),
      ])),
    ]),
    row({ width: fill, height: hug, gap: 14 }, [
      metric("0.55", "Example disparate impact before remediation", C.red),
      metric("0.81", "Example disparate impact after remediation", C.green),
      metric("92", "Sample text-bias score cap in local engine", C.blue),
    ]),
  ]),
);

// 4. Opportunities
render(
  deck.slides.items[3],
  root([
    titleBlock("Opportunities", "The prototype turns AI fairness from a compliance afterthought into a review workflow.", C.yellow),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1), fr(1)], columnGap: 14, rowGap: 14 }, [
      card("Different from existing tools", "Combines dataset fairness, text-bias scanning, simulation, remediation, human-impact estimation, and PDF evidence in one web app.", C.blue),
      card("Solves the problem directly", "Computes measurable fairness indicators and maps them to clear risk levels, legal warnings, and corrective actions.", C.green),
      card("USP", "Works even when the backend is unavailable: core CSV audit and simulation can run locally in the browser.", C.yellow),
    ]),
    panel({ width: fill, height: hug, padding: { x: 18, y: 14 }, fill: C.paleBlue, line: "#BCD2F5", borderRadius: 10 }, column({ width: fill, height: hug, gap: 8 }, [
      text("Opportunity unlocked", { width: fill, height: hug, style: { fontFamily: font, fontSize: 17, bold: true, color: C.blue } }),
      text("Organizations can check fairness before AI systems affect people, document the review, and demonstrate corrective action.", { width: fill, height: hug, style: { fontFamily: font, fontSize: 14, color: C.ink } }),
    ])),
  ]),
);

// 5. Features
render(
  deck.slides.items[4],
  root([
    titleBlock("List of features offered by the solution", "Each feature maps to the objective: measure, flag, explain, and fix bias before deployment.", C.red),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1)], columnGap: 20, rowGap: 14 }, [
      bullet("Dataset bias audit", "CSV upload with protected attribute and target selection; computes Disparate Impact, Statistical Parity, and Equalized Odds.", C.blue),
      bullet("Gemini text scanner", "Reviews job descriptions, HR rules, policies, and model outputs for biased phrases, severity, and safer rewrites.", C.green),
      bullet("What-if simulation", "Tests an individual profile and shows how protected attributes can shift predicted outcomes.", C.yellow),
      bullet("Automated remediation", "Applies adversarial debiasing logic and compares before/after fairness and accuracy.", C.red),
      bullet("Human impact report", "Estimates unfair decisions per month, legal risk, and financial exposure.", C.blue),
      bullet("Secure exports", "Generates PDF reports and debiased CSV output; session data is encrypted with AES-256-CBC.", C.green),
    ]),
  ]),
);

// 6. Process flow
render(
  deck.slides.items[5],
  root([
    titleBlock("Process flow diagram or Use-case diagram", "A reviewer moves from raw evidence to measurable fairness decisions in one flow.", C.blue),
    row({ width: fill, height: hug, gap: 10, align: "center" }, [
      flowStep("Upload / paste", "CSV dataset or policy text", C.gBlue, 1),
      text(">", { width: fixed(18), height: hug, style: { fontFamily: font, fontSize: 22, bold: true, color: C.muted, align: "center" } }),
      flowStep("Analyze", "Local metrics + Gemini review", C.green, 2),
      text(">", { width: fixed(18), height: hug, style: { fontFamily: font, fontSize: 22, bold: true, color: C.muted, align: "center" } }),
      flowStep("Explain", "Risk, flags, group rates", C.yellow, 3),
      text(">", { width: fixed(18), height: hug, style: { fontFamily: font, fontSize: 22, bold: true, color: C.muted, align: "center" } }),
      flowStep("Remediate", "Debias + compare metrics", C.red, 4),
      text(">", { width: fixed(18), height: hug, style: { fontFamily: font, fontSize: 22, bold: true, color: C.muted, align: "center" } }),
      flowStep("Report", "PDF, CSV, deploy signal", C.blue, 5),
    ]),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1), fr(1)], columnGap: 14 }, [
      card("Primary user", "Compliance reviewer, ML owner, HR / lending policy team.", C.blue),
      card("Decision point", "Should this model or policy ship as-is, be remediated, or be escalated?", C.yellow),
      card("Output", "Fairness metrics, legal risk notes, human impact, and exportable audit evidence.", C.green),
    ]),
  ]),
);

// 7. Wireframes
render(
  deck.slides.items[6],
  root([
    titleBlock("Wireframes / Mock diagrams of the proposed solution", "The UX is designed as a professional review console, not a marketing page.", C.green),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1), fr(1)], columnGap: 14 }, [
      uiSurface("Dashboard", "Audit status, fairness score, recent scans", C.blue, "dashboard"),
      uiSurface("Results", "Metric violations and remediation guidance", C.green, "results"),
      uiSurface("Text Scanner", "Gemini flags bias and suggests rewrites", C.red, "scanner"),
    ]),
  ]),
);

// 8. Architecture
render(
  deck.slides.items[7],
  root([
    titleBlock("Architecture diagram of the proposed solution", "Flutter Web handles the full prototype path, with Gemini and Firebase providing Google AI/cloud support.", C.blue),
    row({ width: fill, height: hug, gap: 14, align: "center" }, [
      card("Frontend", "Flutter Web\nGoRouter + Riverpod\nResponsive dashboard UI", C.blue, { height: fixed(150), fill: C.paleBlue }),
      text(">", { width: fixed(20), height: hug, style: { fontFamily: font, fontSize: 24, bold: true, color: C.muted, align: "center" } }),
      card("Core services", "DemoAuditEngine\nGeminiService\nAuth + Encryption\nReportGenerator", C.green, { height: fixed(150), fill: C.paleGreen }),
      text(">", { width: fixed(20), height: hug, style: { fontFamily: font, fontSize: 24, bold: true, color: C.muted, align: "center" } }),
      card("Outputs", "Metrics + explanations\nPDF report\nDebiased CSV\nDeploy readiness", C.yellow, { height: fixed(150), fill: C.paleYellow }),
    ]),
    row({ width: fill, height: hug, gap: 14 }, [
      card("Google AI", "Gemini 2.0 Flash performs text-bias analysis and chat assistance, with local fallback for demo resilience.", C.blue),
      card("Google Cloud", "Firebase Hosting is configured for static Flutter Web deployment under project visora-ai-platform.", C.green),
      card("Optional backend", "FastAPI + ML backend is available for production expansion, while core audits remain browser-capable.", C.red),
    ]),
  ]),
);

// 9. Technologies
render(
  deck.slides.items[8],
  root([
    titleBlock("Technologies to be used in the solution", "The stack is lightweight enough for a hackathon prototype and extensible enough for production review workflows.", C.yellow),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1), fr(1), fr(1)], columnGap: 12, rowGap: 12 }, [
      card("Flutter Web", "Dart 3.x UI for browser-first access.", C.blue),
      card("Riverpod", "State management for upload, scan, audit, auth.", C.green),
      card("Gemini API", "Gemini 2.0 Flash for AI text-bias review.", C.yellow),
      card("Firebase Hosting", "Cloud deployment target for build/web.", C.red),
      card("fl_chart", "Visualizes fairness and rates.", C.blue),
      card("PDF + printing", "Generates compliance-ready reports.", C.green),
      card("AES + SHA-256", "Encrypted session and password hashing.", C.yellow),
      card("FastAPI backend", "Optional ML service expansion path.", C.red),
    ]),
  ]),
);

// 10. Cost
render(
  deck.slides.items[9],
  root([
    titleBlock("Estimated implementation cost", "Prototype cost stays low because the core audit runs locally and cloud spend is usage-based.", C.green),
    simpleTable([
      ["Area", "Assumption", "Prototype estimate"],
      ["Hosting", "Firebase Hosting for static Flutter Web files.", "Eligible for no-cost tier / usage based"],
      ["AI review", "Gemini Developer API for text scanner and chat.", "Free tier for testing, paid by tokens at scale"],
      ["Backend", "Optional FastAPI service for production ML jobs.", "Can be deferred for MVP"],
      ["Storage", "No persistent dataset storage required in MVP.", "Minimal"],
      ["Total", "Student prototype and demo traffic.", "Low-cost / usage-based"],
    ]),
    text("Sources for pricing model: Firebase pricing and Gemini Developer API pricing pages, checked Apr 27, 2026. Final production cost depends on traffic, token volume, and region.", {
      width: fill,
      height: hug,
      style: { fontFamily: font, fontSize: 9.5, color: C.muted },
    }),
  ]),
);

// 11. MVP snapshots
render(
  deck.slides.items[10],
  root([
    titleBlock("Snapshots of the MVP", "Key screens implemented in the Visora Flutter Web prototype.", C.red),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1), fr(1)], columnGap: 14 }, [
      uiSurface("Home", "System overview and audit actions", C.blue, "dashboard"),
      uiSurface("Audit Results", "Fairness metrics and group approval rates", C.green, "results"),
      uiSurface("Gemini Scanner", "Bias flags and safer rewritten copy", C.red, "scanner"),
    ]),
  ]),
);

// 12. Future development
render(
  deck.slides.items[11],
  root([
    titleBlock("Additional Details / Future Development", "The MVP proves the workflow; next steps harden it for real review teams.", C.blue),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1)], columnGap: 18, rowGap: 14 }, [
      bullet("Cloud deployment hardening", "Deploy frontend to Firebase Hosting and backend jobs to Cloud Run when heavier ML analysis is needed.", C.blue),
      bullet("Model connectors", "Add APIs for Vertex AI, TensorFlow, and scikit-learn model uploads.", C.green),
      bullet("Audit history", "Persist reports, reviewer comments, and remediation approvals with secure role-based access.", C.yellow),
      bullet("Explainability depth", "Upgrade SHAP-style prototype logic into real feature attribution and counterfactual evidence.", C.red),
      bullet("Governance workflow", "Add approval routing, policy thresholds, and organization-specific compliance templates.", C.blue),
      bullet("Dataset expansion", "Support more file types, protected attributes, and fairness definitions by domain.", C.green),
    ]),
  ]),
);

// 13. Links
render(
  deck.slides.items[12],
  root([
    titleBlock("Provide links to your:", "Submission links for the judging form. Replace pending links with final public URLs before submission.", C.yellow),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1)], columnGap: 16, rowGap: 14 }, [
      card("GitHub Public Repository", "Pending public URL\nLocal project: fairlens_ai", C.blue, { fill: C.paleBlue }),
      card("Demo Video Link (3 Minutes)", "Pending recording URL\nSuggested flow: login -> upload CSV -> results -> scanner -> report", C.red, { fill: C.paleRed }),
      card("MVP Link", "Pending hosted URL\nFirebase project: visora-ai-platform", C.green, { fill: C.paleGreen }),
      card("Working Prototype Link", "Pending deployment URL\nConfigured target: Firebase Hosting build/web", C.yellow, { fill: C.paleYellow }),
    ]),
  ]),
);

// 14. Demo readiness
render(
  deck.slides.items[13],
  root([
    titleBlock("Prototype readiness checklist", "A concise proof that the solution is feasible and demonstrable.", C.green),
    grid({ width: fill, height: hug, columns: [fr(1), fr(1)], columnGap: 18, rowGap: 14 }, [
      bullet("CSV fairness audit", "Implemented with local parsing and real group approval metrics.", C.blue),
      bullet("Gemini text scanner", "Implemented with Gemini API call and local fallback.", C.green),
      bullet("Report generation", "Implemented as downloadable PDF with metrics and executive summary.", C.yellow),
      bullet("Security layer", "Implemented encrypted session storage and hashed credentials.", C.red),
      bullet("Cloud readiness", "Firebase Hosting config is present for build/web deployment.", C.blue),
      bullet("Fallback resilience", "Core demo keeps working if backend or AI API is temporarily unavailable.", C.green),
    ]),
  ]),
);

// 15. Close
render(
  deck.slides.items[14],
  layers({ width: fill, height: fill }, [
    shape({ width: fill, height: fill, fill: C.soft }),
    column({ width: fill, height: fill, padding: { x: 70, y: 76 }, gap: 22, align: "start" }, [
      row({ width: fill, height: hug, align: "center", gap: 18 }, [
        googleMark(),
        smallLabel("Prototype ready", C.green, C.paleGreen),
      ]),
      text("Visora helps teams catch bias before AI decisions reach real people.", {
        width: wrap(720),
        height: hug,
        style: { fontFamily: font, fontSize: 44, bold: true, color: C.ink },
      }),
      rule({ width: fixed(140), weight: 5, stroke: C.blue }),
      text("Built for Unbiased AI Decision - Google Build AI Hackathon 2026", {
        width: wrap(680),
        height: hug,
        style: { fontFamily: font, fontSize: 17, color: C.muted },
      }),
      row({ width: fill, height: hug, gap: 12 }, [
        smallLabel("Measure", C.blue, C.paleBlue),
        smallLabel("Flag", C.red, C.paleRed),
        smallLabel("Fix", C.green, C.paleGreen),
        smallLabel("Report", C.yellow, C.paleYellow),
      ]),
    ]),
  ]),
  { left: 0, top: 0, width: W, height: H },
);

const pptx = await PresentationFile.exportPptx(deck);
writeFileSync(join(OUT, "Visora_Solution_Challenge_2026_Prototype.pptx"), Buffer.from(await pptx.arrayBuffer()));

const inspect = await deck.inspect();
writeFileSync(join(OUT, "solution_deck_inspect.ndjson"), inspect.ndjson ?? JSON.stringify(inspect, null, 2));

for (const [i, slide] of deck.slides.items.entries()) {
  const png = await slide.export({ format: "png" });
  writeFileSync(join(PREVIEW, `slide_${String(i + 1).padStart(2, "0")}.png`), Buffer.from(await png.arrayBuffer()));
  const layout = await slide.export({ format: "layout" });
  writeFileSync(join(PREVIEW, `slide_${String(i + 1).padStart(2, "0")}.layout.json`), JSON.stringify(layout, null, 2));
}

console.log("Exported artifacts/Visora_Solution_Challenge_2026_Prototype.pptx");
console.log(`Rendered ${deck.slides.items.length} preview PNGs to artifacts/previews`);
