# Iteration 33: independent review request

Prepared 2026-10-02. No reviewer engaged; no request sent. This text is ready
for the owner to send after selecting and authorizing a recipient.

## Message

Hello,

We are building an offline educational blackjack trainer. We would like an
independent mathematical review of a small initial specification before
implementing paid lessons. There is no live-table input, real-card recognition,
casino integration, payment flow or promise of winnings.

The first scope is the standard 6D/S17/DAS/late-surrender/peek/3:2 profile,
Hi-Lo observation rules, deck estimation, a separate floor true-count convention,
and definitions for finite-horizon risk. No playing index values or blackjack
risk distributions are approved yet. We specifically want to avoid importing
indices generated with different rounding or rules.

Could you review this scope or recommend a qualified independent reviewer?
Please indicate your relevant solver/research experience, potential conflicts,
proposed method, deliverables, timing and fee before any engagement is agreed.

We can provide these public project files at baseline commit `87a5230`:

- `docs/PRO_MATH_CONTRACT.md` and `.json` — definitions and pending decisions;
- `test/data/pro_math_contract_test.dart` — baseline and exact arithmetic checks;
- `docs/STRATEGY_VALIDATION.md` and the two standard strategy fixtures;
- the pure-Dart engine files for the actual rules and card-observation behaviour.

We need a written scope-by-scope conclusion, assumptions and limitations,
reproducible independent boundary checks, and a list of required corrections.
Our automated checks are evidence supplied to you, not a replacement for your
independent calculation. A specification review is also separate from later
validation of numerical indices, distributions and complete lesson content.

Thank you.

## Potential contact channels

Public sources checked 2026-10-02; availability, fee, suitability for this
assignment and conflicts have not been confirmed.

- [Wizard of Odds business contact](https://wizardofodds.com/site/contact):
  its contact page permits business inquiries to Michael Shackleford.
  The [biography](https://wizardofodds.com/site/about/bio/) describes consulting.
- [QFIT contact/about](https://www.qfit.com/blackjack-odds.htm): the site
  describes blackjack practice/simulation software and provides a contact channel.

These are candidates to ask, not endorsements or appointed reviewers. If a
reviewer authored a source used by the project, disclose it and require separate
reproduction rather than accepting that source as its own independent confirmation.
Do not send participant data or contacts. No outreach or payment is authorized
by this document.
