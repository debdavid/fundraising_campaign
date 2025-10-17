1. Purpose

This repository provides a small, reproducible analysis of a direct-mail campaign using R. It calculates the campaign’s core KPIs, surfaces data quality issues (notably unmatched transactions), and emits reviewer-ready outputs—following consulting-grade practices for clarity, auditability, and ease of reuse.

2. Approach (ELT rationale)

A pragmatic ELT pattern is used:
Extract/Load: Read raw CSVs into R without alteration.
Transform: Validate schema and types; normalise key text fields; deterministically match transactions to contacts by URN; compute KPIs; report unmatched transactions for reconciliation; (optionally) generate fuzzy suggestions for manual review.
Output/Load: Write a single-row KPI summary and an unmatched transactions file.
This mirrors the modern warehouse pattern (landing raw data first, then transforming in code), while remaining lightweight and easy to run in RStudio.

3. Inputs and outputs

Inputs (place in ./data/):
contacts.csv: contact records mailed in the campaign;
transactions.csv: transactions received in the month following the mailout.
Outputs (written to project root):
campaign_summary.csv — single-row KPI table;
unmatched_transactions.csv — transactions that did not match a contact by URN;
(Optional) fuzzy_candidate_matches.csv — high-similarity suggestions for manual review (only if enable_fuzzy <- TRUE).

4. KPI definitions

Gifts received: number of rows in transactions.csv.
Responders: distinct matched URNs in transactions.
Response rate: responders ÷ contacts mailed.
Average gift per donor: average of (sum of gift amount per matched URN).
Total income: sum of all amount values in transactions.csv.
Net income: total income − (contacts mailed × $3 per letter).

Note: The brief stipulates “one transaction per contact” for this challenge. The script still computes average gift per donor robustly in case of multiple gifts in other datasets.

5. Data quality and matching

Schema checks: Required columns are asserted in both files.
Type coercion: urn, addr_postcode, and age are coerced to integer; amount to numeric.
Normalisation: first, last, addr_line, addr_suburb, addr_state are lower-cased and trimmed to reduce incidental differences.
Uniqueness: Duplicate contact URNs are warned about and collapsed to the first occurrence.
Deterministic match: Inner join on URN drives all KPI calculations.
Transparency: Unmatched transactions are exported for reconciliation and excluded from KPI calculations.
Fuzzy suggestions (optional and non-authoritative)
Where transactions do not match a contact’s URN, the script can propose likely matches by:
Blocking on addr_postcode to limit the candidate set;
Computing Jaro–Winkler similarity on first|last|addr_line|addr_suburb|addr_state;
Emitting only high-similarity pairs (default ≥ 0.90) into fuzzy_candidate_matches.csv.
These are suggestions for manual review and do not affect KPIs unless the data is corrected and re-run.

6. How to run (RStudio)

In RStudio:
Open the project, place CSVs in data/, open transaction_matching.R, and click Source.
To generate fuzzy suggestions, set enable_fuzzy <- TRUE near the top of the script and re-run.

8. Example results (from the provided sample data)

Contacts mailed: 270
Gifts received (total): 30
Responders (matched): 25
Response rate: 9.26%
Average gift per donor (matched): $44.80
Total income: $1,320
Campaign cost (@ $3/letter): $810
Net income: $510
Unmatched gifts: 5 (totalling $200)

These values are printed to the console and written to campaign_summary.csv.
Unmatched transactions are listed in unmatched_transactions.csv for quick QA.

8. Extensibility

Reproducible pipeline: Promote the script into a {targets} pipeline for dependency tracking, caching, and easy re-runs.
Version control of packages: Use {renv} to lock dependencies.
Testing: Add testthat checks for schema, types, and metric formulas.
Segmentation: Enrich KPIs by state, age bands, acquisition channel, or gift amount thresholds.
Experimental reconciliation: Adjust fuzzy thresholds, add name/address weights, or include phonetic keys (e.g., Soundex/Metaphone) if appropriate.

9. Assumptions and limitations

URN is the authoritative contact identifier; KPIs are computed only from deterministic URN matches.
Fuzzy output is advisory and requires human validation before any data correction.
The mailing cost is fixed at $3 per contact as per the brief; in production this should be parameterised from a cost table.

10. Files (for reviewers)

transaction_matching.R — single executable script, fully commented.
campaign_summary.csv — KPI snapshot for quick consumption.

unmatched_transactions.csv — reconciliation list.

(Optional) fuzzy_candidate_matches.csv — only when enable_fuzzy <- TRUE
