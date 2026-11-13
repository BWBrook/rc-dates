# Can choosing which radiocarbon dates to keep rewrite the story of the past?

Barry W. Brook, Rebecca Wheatley, Christopher N. Johnson, Alan N. Williams, Sean Ulm and Luke A. Yates, with Claude (Anthropic) and Codex (OpenAI). Draft of 13 November 2026, not yet reviewed by all co-authors; a plain-language summary of a living research repository, <https://github.com/BWBrook/rc-dates>.

<div id="figures"></div>

*Graphical abstract.* (1) A site dated several times can enter a database as one date chosen by a rule. (2) The AustArch benchmark[]{.C01} after keeping one date per site: summed-probability curves, each row on its own vertical scale[]{.C02}[]{.C03}. (3) What model comparison concluded in simulated archives of known history[]{.C10}[]{.C12}[]{.C13}[]{.C22}. (4) Runs in which the trend was reversed, by its true size and the share of sites keeping the extreme that runs against it; bands span four histories[]{.C18}[]{.C19}[]{.C20}.

## The puzzle

Archaeologists reconstruct how human activity rose and fell over thousands of years by counting dated traces of people: charcoal from a hearth, shell from a midden. More people leave more traces, so a curve showing how many *radiocarbon dates* (age estimates from the decay of carbon-14 in once-living material) fall in each century is read as a history of human activity. Regional databases now pool thousands of such dates.

A site may have been dated many times while a database lists only some of its dates. A listed date may be the site's only one, or one kept from several: the oldest, say, because a study asked when people first arrived. Nothing in the date itself records which.

## Why it is hard

Each date has its own measurement uncertainty, and careful methods already handle that. The problem here is different: which dates were kept. An extreme is not a typical member of a set. Of five dates from a steady history, the oldest falls in the oldest fifth of the time span about two times in three[]{.C27}, against one time in five for a date picked at random. A curve built from oldest dates therefore tends to be pushed back in time even if nothing in the past changed. Agreement among standard ways of drawing the curve cannot, by itself, reveal this, because every method starts from the same dates.

## What we did

We redrew the regional curve from [540]{.C01} well-replicated charcoal and wood dates at [68]{.C01} Australian archaeological sites after keeping each site's oldest date, its youngest date or one picked at random. We then simulated archives whose true history we knew (steady, or rising or falling by between one and a half and ten times over 11,000 years), applied the same rules, and asked whether standard model comparison recovered the true direction. Finally, we repeated the main tenfold simulations with measurement scatter added to every date.

## What we found

1. **Keeping each site's oldest or youngest date moved the Australian curve by millennia.** Its average age shifted [3,133]{.C02} years older or [2,439]{.C02} years younger, although both versions kept exactly 68 dates; one random date per site moved it by about [100]{.C03} years. Either extreme changed the curve's shape more than the choice among three standard ways of drawing it did[]{.C06}. This shows how far selection can move this collection of dates, not which curve is the true history.

2. **When every site was affected, the selection rule decided the answer.** In the simulations, keeping every site's oldest date always produced an apparent decline, and keeping its youngest always an apparent rise, whatever the true history; true trends running the other way were reversed[]{.C10}. Applying the rule to only half the sites still created a trend from a steady history in over [97]{.C11}% of runs.

3. **Weaker true trends were reversed even when only some sites were affected.** With three-quarters of sites affected, gentle trends (a one-and-a-half- to twofold change over 11,000 years) were reversed in [93]{.C19 .V013}–[100]{.C19 .V014}% of runs, although no tenfold trend was. The proportions we tested do not establish a safe threshold.

4. **Keeping both the oldest and youngest dates avoided reversals but blurred the picture.** It never reversed a trend[]{.C21}. With every site affected, it detected only [11]{.C22}–[17]{.C22}% of the gentlest trends, against [61]{.C22}–[67]{.C22}% for two dates per site picked at random, and it always made tenfold straight-line trends look exponential[]{.C13}.

5. **Random selection almost never reversed a trend, and measurement scatter did not change the main results.** Picking dates at random reversed at most [0.6]{.C21}% of runs, though with every site affected it often missed gentle trends. Measurement scatter moved no tenfold headline result by more than [0.1]{.C25} percentage points; weaker trends were not rerun, and errors shared between dates through the calibration curve, laboratory offsets and outliers remain untested.

## What it means

A regional curve inherits the choices made in assembling its dates. Equal numbers of dates per site do not make those dates representative, and agreement among different methods applied to the same dates cannot, by itself, show that they are. Databases should record whether a site's date is the only one obtained or one chosen from several, and on what basis. Analysts should test whether their conclusions survive plausible selection rules. The simulations treat dates as independent draws without site histories, and we do not know how often real archives keep only extreme dates.

## How this work was done

Barry Brook set the questions and directs the work; the human co-authors contribute archaeological and statistical expertise and will review this draft. Codex (OpenAI GPT-5.6 and GPT-6) and Claude (Anthropic Fable 5.1 and Opus 5.5) designed and ran the analyses, audited each other's evidence and drafted the text. Every number here traces to an independently checked claims ledger in the repository.

## Sources

The article, supplement and an agent guide are in the repository (`manuscript/`). The dates come from the AustArch database [@williams2014AustArchDataset].
