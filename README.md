# Student loan: overpay or invest?

A single-file web app that answers one question for UK graduates: **"Am I better off
overpaying my student loan, or investing that money instead?"**

Enter your loan plan, balance, salary and spare monthly cash, and it simulates both
futures month by month — mandatory repayments, plan-specific interest, and the
write-off date — then gives a direct, plain-English verdict backed by interactive
charts and a year-by-year table.

Everything lives in **one self-contained `index.html`** — no build step, no backend,
no external requests — so it can be dropped into any hosting and embedded in a
WordPress page with an iframe.

## Supported plans (2026/27 rates, verified July 2026)

| Plan | Threshold | Repayment | Interest | Write-off |
|---|---|---|---|---|
| Plan 1 | £26,900 | 9% above | RPI (capped at base rate + 1%) | 25 years |
| Plan 2 | £29,385 | 9% above | RPI → RPI + 3%, sliding £29,385–£52,885 | 30 years |
| Plan 4 (Scotland) | £33,795 | 9% above | RPI (capped at base rate + 1%) | 30 years |
| Plan 5 | £25,000 | 9% above | RPI only | 40 years |
| Postgraduate | £21,000 | 6% above | RPI + 3% | 30 years |

Current RPI used for interest: **3.2%** (set each September from the previous
March's RPI). Sources: [gov.uk — what you repay](https://www.gov.uk/repaying-your-student-loan/what-you-pay),
[loan terms & conditions](https://www.gov.uk/government/publications/student-loans-a-guide-to-terms-and-conditions).

### Updating the rates (once a year, ~5 minutes)

All figures live in one clearly-marked block near the top of the `<script>` in
`index.html`, between `CONFIG START` and `CONFIG END`:

- **each April**: update the five `threshold` values (and Plan 2's
  `lowerIncome`/`upperIncome` interest bands) for the new tax year
- **each September**: update `currentRPI` from the official announcement
- update `taxYear` and `lastVerified` so the footer stays honest

Then open `tests/run-tests.html` (see below) — the threshold tests will tell you
which expected values to bump.

## Embedding in WordPress

`index.html` must be hosted somewhere first (WordPress blocks `.html` uploads to
the Media Library by default). Two easy options:

1. **GitHub Pages (recommended, free)** — in this repo on github.com go to
   *Settings → Pages*, set the source to the `main` branch, and the app will be
   served at `https://<your-username>.github.io/student-loan-app/`.
2. **Your own hosting** — upload `index.html` anywhere via your host's file
   manager or FTP and use that URL.

Then, in the WordPress editor, add a **Custom HTML block** to the page and paste:

```html
<div style="max-width:920px;margin:0 auto;">
  <iframe id="slcalc"
          src="https://arthur-grainger.github.io/student-loan-app/"
          title="Student loan: overpay or invest?"
          style="width:100%;border:0;display:block;" height="2400" loading="lazy"></iframe>
</div>
<script>
window.addEventListener('message', function (e) {
  if (e.data && e.data.type === 'slcalc-height') {
    document.getElementById('slcalc').style.height = e.data.height + 'px';
  }
});
</script>
```

**Centering**: the calculator centres itself inside the iframe (its content column
is max 880px wide), and the wrapper `<div>` centres the iframe inside your page,
so it stays centred whatever width your theme gives the content area. If the
calculator looks squeezed into a narrow theme column, select the block in the
WordPress editor and choose **Wide width** or **Full width** alignment (if your
theme offers it) — the wrapper div will keep it centred.

The `<script>` part is optional but recommended: the app reports its height to the
parent page, so the iframe grows and shrinks to fit with no inner scrollbar. If
your theme strips scripts, keep just the wrapper and `<iframe>` lines — the fixed
`height="2400"` fallback still works. Because it's an iframe, your theme's CSS
cannot break the app (and vice versa).

## How the comparison works

Both strategies start from identical circumstances and get the same spare money:

- **Overpay** — spare cash (and any lump sum) goes into the loan while it exists;
  once the loan is gone, the spare cash *and* the freed-up mandatory repayments
  are invested.
- **Invest** — spare cash is invested from day one (assumed in a stocks & shares
  ISA, so tax-free); mandatory repayments continue until the loan is repaid or
  written off, after which they're invested too.

The verdict compares total wealth at the moment the last loan disappears, and a
binary search finds the **break-even investment return** — the tipping point
between the two strategies. Interest follows the official formulas (including
Plan 2's income-based sliding scale, with bands uprated over time); salary,
thresholds and bands are uprated once a year; all figures are nominal (cash terms).

### Tax, pension and deductions

Income tax and National Insurance deliberately **don't appear** in the model,
because they cancel out of this particular comparison: the spare money being
decided on is post-tax cash in both strategies, student loan repayments come out
of post-tax pay in both strategies (they get no tax relief), and returns are
assumed to be inside an ISA, so they're tax-free. Modelling PAYE would add
complexity without changing any verdict.

The one deduction that genuinely changes the numbers is a **pension paid by
salary sacrifice**: it reduces the pay your repayments (and Plan 2's interest
bands) are calculated on. That's a configurable assumption under "Adjust
assumptions" — enter your contribution % and how it's paid. Pensions paid by
net pay or relief at source don't reduce payroll student-loan deductions, so
selecting "Other" leaves the loan calculation unchanged.

Known simplifications: annual uprating happens on the anniversary of "today"
rather than every April/September; Plans 1 and 4 assume RPI applies (the base
rate + 1% cap is ignored); the Plan 2/5 "prevailing market rate" cap is not
modelled; one loan at a time (no undergrad + postgrad combination yet);
contributions are assumed to stay within the £20,000-a-year ISA allowance.

**This is a projection tool, not financial advice.**

## Development

- `dev/serve.ps1` — tiny PowerShell static server, no installs needed:
  `powershell -ExecutionPolicy Bypass -File dev\serve.ps1` then open
  <http://localhost:8123/>.
- `tests/run-tests.html` — engine test suite. It fetches `index.html`, extracts
  the real CONFIG and ENGINE blocks, and runs 35 assertions (thresholds, interest
  formulas, write-off timing, repayment maths, pension deductions, lump sums,
  break-even logic).
  Open it via the dev server; the page and the tab title show pass/fail.

Ideas for later: undergrad + postgrad loans together, pension-vs-loan comparison,
career breaks, shareable results.
