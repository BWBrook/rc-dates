# Can the radiocarbon dates we do not have rewrite the story of the past?

Barry W. Brook, Rebecca Wheatley, Christopher N. Johnson, Alan N. Williams, Sean Ulm and Luke A. Yates. Draft of 13 November 2026, not yet reviewed by all co-authors; a plain-language summary of a living research repository, <https://github.com/BWBrook/rc-dates>.

<div id="figures"></div>

![](../figures/graphical_abstract.pdf){#fig-brief width=100%}

*Graphical abstract.* (1) A site dated several times might reach an analysis as one date: its oldest, its youngest, one at random, or both extremes. (2) The AustArch benchmark[]{.C01} after keeping one date per site: summed-probability curves, each row on its own vertical scale[]{.C02}[]{.C03}. (3) What model comparison concluded in simulated archives of known history[]{.C10}[]{.C12}[]{.C13}[]{.C22}. (4) Runs in which the trend was reversed, by its true size and the share of sites keeping the extreme that runs against it; bands span four histories[]{.C18}[]{.C19}[]{.C20}.

## The question

Archaeologists reconstruct how human populations rose and fell over thousands of years by counting dated traces of people and their activities: charcoal from a hearth, shell from a midden. More people leave more traces, so a curve showing how many *radiocarbon dates* (age estimates from the decay of carbon-14 in once-living material) fall in each century is tempting to read directly as a history of human activity. Such curves are used to date first arrivals, track growth and decline, and compare people's fortunes with past climate. Regional databases now pool thousands of dates from hundreds to thousands of sites.

But the curve also records which dates reach it. A site might have been dated many times while a regional database lists only some of those dates: others stay in unpublished reports, and a compilation built to find when people first arrived might list only each site's oldest. Analysts use every date they can find, but they cannot see the ones that never reached the database, and nothing in a listed date says whether it is a site's only one or the oldest of several.

So we asked: if some sites are represented only by their oldest or youngest date, how far can the curve, and the trend read from it, move from what all the dates would show? The answer is far enough to reverse a trend, so a trend read from such a curve needs testing against plausible gaps in its dates.

An extreme date misleads because it is not a typical date. Suppose a site was occupied at a steady rate and dated five times. The oldest of the five falls in the earliest fifth of the occupation about two times in three[]{.C27}, whereas a date picked at random does so one time in five. A curve built from sites' oldest dates is therefore pulled back in time even when nothing changed. Every standard way of drawing the curve starts from the same dates, so agreement among them cannot, by itself, reveal this.

## What we did

We redrew a regional curve from [540]{.C01} well-replicated charcoal and wood dates at [68]{.C01} Australian archaeological sites, first with all dates and then keeping only each site's oldest date, its youngest date or one picked at random. We then simulated archives whose true history we knew: steady, or rising or falling by between one and a half and ten times over 11,000 years. In each archive, a share of sites (half, three-quarters or all; the *affected* sites) was represented only by what a rule kept: the oldest date, the youngest, both, or one or two picked at random. The other sites kept all their dates. We asked whether standard model comparison still recovered the true direction of change, and repeated the main tenfold simulations with measurement scatter added to every date.

## What we found

1. **Keeping only each site's oldest or youngest date moved the Australian curve by millennia.** Its average age shifted [3,133]{.C02} years older or [2,439]{.C02} years younger than with all 540 dates, although both versions kept exactly 68 dates. One random date per site, by contrast, moved it by just [100]{.C03} years. Either extreme changed the curve's shape more than the choice among three standard ways of drawing it did[]{.C06}.

2. **With every site affected, the rule fixed the apparent trend whatever the true history.** Keeping each site's oldest date always produced an apparent decline, and keeping its youngest always an apparent rise; true trends running the other way were reversed[]{.C10}. With half the sites affected, a steady history still showed a false trend in over [97]{.C11}% of runs.

3. **Weaker true trends were reversed even when only some sites were affected.** With three-quarters of sites affected, gentle trends (a one-and-a-half- or twofold change over 11,000 years) were reversed in [93]{.C19 .V013}–[100]{.C19 .V014}% of runs; the range spans rising and falling, straight-line and exponential histories at both sizes. No tenfold trend was reversed.

4. **Keeping both the oldest and youngest dates avoided reversals but blurred the picture.** It never reversed a trend[]{.C21}. With every site affected, it detected one-and-a-half-fold trends in only [11]{.C22}–[17]{.C22}% of runs, against [61]{.C22}–[67]{.C22}% for two dates per site picked at random, and it always made tenfold straight-line trends look exponential[]{.C13}.

5. **Random selection almost never reversed a trend, but it discarded information.** Picking dates at random reversed at most [0.6]{.C21}% of runs. With every site reduced to one random date, though, one-and-a-half-fold trends were detected in only [40]{.C22}–[49]{.C22}% of runs, and most of the rest were read as steady. Measurement scatter moved no tenfold headline result by more than [0.1]{.C25} percentage points.

## What it means

A regional curve reflects which dates reached it as well as how many people lived when. Equal numbers of dates per site do not make those dates representative. Before reading a rise or fall as a change in human activity, analysts can test whether it survives plausible gaps, such as some sites being represented only by their oldest or youngest date. If databases recorded whether a listed date is a site's only one or one chosen from several, and why, those tests could be targeted. Our simulations treat dates as independent draws without site histories, did not rerun weaker trends with measurement scatter or test errors shared between dates, and cannot say how often real archives hold only extreme dates.

## How this work was done

Barry Brook set the questions and directs the work; the human co-authors contribute archaeological and statistical expertise and will review this draft. Codex (OpenAI GPT-5.6 and GPT-6) and Claude (Anthropic Fable 5.1 and Opus 5.5) designed and ran the analyses, audited each other's evidence and drafted the text. Every number here traces to an independently checked claims ledger in the repository, alongside the article, supplement and an agent guide (`manuscript/`). The dates come from the AustArch database [@williams2014AustArchDataset].
