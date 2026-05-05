---
description: Review a spec from CEO, CTO, and CFO perspectives in turn
argument-hint: <path-to-spec-file>
---

Review the spec at `$ARGUMENTS` from three stakeholder perspectives in sequence. Be specific to *this* spec — generic templated responses are useless.

If `$ARGUMENTS` is empty, ask the user which spec to review and stop.

## Step 1 — Read the spec

Read the file. Identify: the problem, the proposed solution, the scope, the acceptance criteria, the timeline, and any external dependencies.

## Step 2 — CEO review

Pretend you are the CEO. You care about: customer outcomes, market positioning, revenue impact, competitive risk, brand and regulatory exposure.

Ask:
- Does this solve a problem a paying customer actually has, or is it a nice-to-have?
- What's the revenue / retention / acquisition story? Is it quantified?
- Could this delay something more strategically important?
- What's the regulatory / brand risk if it goes wrong publicly?
- Are we the right ones to build this, or should we partner / buy?

Produce 3-5 specific concerns with quotes from the spec where relevant.

## Step 3 — CTO review

Pretend you are the CTO. You care about: technical feasibility, architectural fit, team capability, operational burden, technical debt.

Ask:
- Does the proposed approach fit the existing architecture, or does it require a new pattern?
- Is the complexity proportional to the value? Could a simpler design deliver 80% of the value?
- Operational load — new infra, new on-call surface, new failure modes?
- Build-vs-buy considered? Is there an off-the-shelf option?
- What does this spec defer to "phase 2" that will haunt us?

Produce 3-5 specific concerns with file or section references.

## Step 4 — CFO review

Pretend you are the CFO. You care about: cost predictability, unit economics, vendor lock-in, regulatory & audit posture, capex vs opex.

Ask:
- What does this cost to build (engineering weeks)? What does it cost to run (monthly infra/vendor fees)?
- What's the per-unit cost (per request, per user, per transaction) at 10×, 100× scale?
- Vendor concentration — does this deepen lock-in to a single provider?
- Audit / SOX / GDPR / PCI implications? What evidence will we need to produce?
- What's the disposal cost if we change direction in 12 months?

Produce 3-5 specific concerns with quantified estimates where the spec gives enough to estimate, and explicit "needs estimate" flags where it doesn't.

## Step 5 — Synthesis

Wrap up with the **top 3 concerns across all hats**, ranked by what would change the spec most if addressed. Recommend either: ship as-is, edit the spec (specify which sections), or send back for re-design (specify why).
