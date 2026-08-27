# Ian Ryu — Data Science Portfolio

Personal portfolio site presenting five data science and machine learning projects, built as a static site with no framework, no build step, and no dependencies.

**Live site:** _add your deployed URL here_

---

## About

I'm a Computer Science & Informatics student at UMass Amherst (expected May 2028), working across healthcare, sports, and public datasets. This site is the long-form version of my project work — each project has a dedicated page covering the problem, the process, the results, and the limitations.

---

## Projects

| Project | Domain | Focus |
|---|---|---|
| **ParaSensor Activity Classification** | Wearable sensors | Random Forest + PCA on accelerometer and insole data across healthy and stroke-recovery groups |
| **EMEIS Fall-Risk Prediction Application** | Clinical / EHR | Three-model comparison behind a Streamlit review tool for nursing-home fall risk |
| **NBA Points Prediction Model** | Sports analytics | Gradient Boosting with calibrated prediction intervals over 7,289 games |
| **Predicting Professional CS2 Match Results** | Esports analytics | Logistic regression on rolling team differentials across 8,226 matches |
| **Electric Vehicle Population Exploration** | Public data | CAFV eligibility classifier on ~112K Washington State registrations |

---

## Tech stack

The site itself is deliberately plain: **HTML, CSS, and a single small JavaScript file** for the photo lightbox. No React, no Tailwind, no bundler — it can be served by any static host or opened directly from disk.

All charts are **hand-authored SVG** or exported notebook figures, so nothing depends on a charting library at runtime.

The underlying project work uses Python (scikit-learn, XGBoost, LightGBM, pandas, Streamlit), R, SQL, and Docker.

---

## Structure

```
.
├── index.html                  # Home — project cards
├── about.html                  # About page with photo lightbox
├── styles.css                  # All site styling
├── lightbox.js                 # Photo lightbox for the about page
└── projects/
    ├── parasensor.html
    ├── emeis.html
    ├── nba.html
    ├── cs2.html
    ├── ev.html
    ├── code/                   # Downloadable source for the CS2 project
    │   ├── INFO248-project-Desroches-Ryu.Rmd
    │   ├── cs2_match_prediction.R
    │   └── newest_ts_ds.csv
    └── images/                 # Charts and screenshots, grouped by project
        ├── cs2/
        ├── emeis/
        ├── ev/
        ├── nba/
        └── parasensor/
```

---

## Running locally

No install step. Either open `index.html` directly in a browser, or serve the folder to get correct relative paths:

```bash
python3 -m http.server 8000
# then visit http://localhost:8000
```

---

## Deploying

Any static host works. The site is a plain folder of files with relative paths throughout.

- **Netlify** — drag the whole project folder onto [app.netlify.com/drop](https://app.netlify.com/drop). Drop the folder, not just `index.html`, or the `projects/` pages and images won't resolve.
- **GitHub Pages** — enable Pages on this repo and serve from the root of the default branch.
- **Vercel / Cloudflare Pages** — import the repo, no build command, output directory is the root.

---

## Notes on the data

**EMEIS.** The underlying resident data is covered by an internship NDA and is not in this repository. The interface screenshots were produced by running the real application against a fully synthetic dataset — invented resident IDs and invented clinical values — so no real person's data appears anywhere on the site. Model metrics shown are aggregate figures only.

**CS2.** The cleaned dataset and the original R Markdown analysis are included under `projects/code/`. The source data was scraped from HLTV.org and is available under CC0.

Reported limitations on each project page — validation caveats, class imbalance, a model that failed to beat its baseline — are stated deliberately rather than omitted. They're part of the work.

---

## Contact

- **Email:** ianryu@outlook.com
- **GitHub:** [ian-ryu5](https://github.com/ian-ryu5)
- **LinkedIn:** [ianryu1](https://linkedin.com/in/ianryu1)
