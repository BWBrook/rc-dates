# Editorial reworking for the general editor and specialist reader

18 October 2026. First proposition for discussion with Claude, based on clean
commit `e40bfb6`. These are alternative passages for criticism, not an accepted
replacement manuscript. Board discussion 88 records Barry's brief and the
collaboration. Scientific results and scope remain those of the current paper.

## The argument to test

Giving sites equal representation and retaining a representative distribution
of ages are different operations. The paper can make that distinction tangible:
the same simulated dated events produce opposite inferred trends when the rule
for retaining a date from each site changes. Keeping both ends can recover the
direction while still misleading the analysis about the form of change.

The contribution should be explained through these consequences. Order
statistics provide the established mechanism; the radiocarbon experiment tests
its passage through calibration and regional inference, and the AustArch
benchmark measures its scale in an assembled archaeological dataset. We should
not claim invention of the mechanism, a survey of actual retention practices,
or a general correction for all forms of sampling bias.

## Route A — start with the inferential problem

### Working title

Date selection can reverse inferred trends in radiocarbon histories

### Abstract

Giving each archaeological site one radiocarbon date does not make the resulting
temporal sample representative. We tested how the choice of retained dates
affects regional inference, using controlled simulations and 540 charcoal or
wood determinations from 68 AustArch sites in Australia. In simulations of
constant, increasing and decreasing histories, retaining every site's oldest
date produced inferred decline, whereas retaining its youngest produced growth,
in all 1,000 replicates of each history. Selection therefore created trends from
constant histories and reversed opposing trends. Retaining both extrema
preserved the direction of change but selected exponential models for every
simulated linear history when applied to all sites. Random retention preserved
the direction of ten-fold changes, with declining ability to distinguish their
linear or exponential form as dates were discarded. In AustArch, oldest and
youngest retention shifted the mean summed probability distribution 3,133 years
older and 2,439 years younger, respectively; retaining the same number of dates
at random shifted it 103 years older on average. The oldest and youngest effects
exceeded differences among three temporal summaries in all nine sensitivity
configurations. The simulations isolate post hoc selection among independent
regional dates, without site occupation histories or realised measurement
scatter. Regional inference therefore needs information about which dates each
site contributes, alongside how many: a trend that survives alternative summary
methods can still depend on the rule used to assemble the dataset.

### Proposed opening

A regional radiocarbon dataset can give every archaeological site equal weight
and still favour particular periods. Keeping one date from each site limits the
contribution of intensively dated sites, but the resulting temporal sample
depends on which date is kept. An oldest date, a youngest date and a randomly
chosen date answer different questions about the same set of determinations.
In the controlled simulations presented here, that choice alone can turn
growth into inferred decline or decline into growth. This is a problem for
regional histories whenever a site's contribution is interpreted without
knowing how it was selected.

Radiocarbon dates are used to reconstruct changes in human activity and, by
proxy, population size: other things being equal, more people leave more
dateable evidence [@rick1987DatesDataExamination;
@robinson2019SpatiotemporalDynamicsPrehistoric; @ulm1996RadiocarbonCulturalChronologies;
@williams2016RadiometricDatesAre]. These reconstructions underpin accounts of
European Neolithic demography, Holocene Sahul and other regional histories
[@shennan2013RegionalPopulationCollapse; @timpson2014ReconstructingRegionalPopulation;
@johnson2011ReconstructingDynamicsAncient; @williams2013NewPopulationCurve;
@brown2019MaoriPopulationGrowth; @chaput2016RadiocarbonDatesEstimates;
@porcic2016DemographyEarlyNeolithic]. Their interpretation depends on the
connection between past activity and the dates that enter an analysis.
Preservation, research effort and calibration have received sustained
attention, alongside the choice of binning, smoothing and population models
[@surovell2009CorrectingTemporalFrequency; @bluhm2019ValidationGlobalModel;
@park2026RescalingRadiocarbonData; @carleton2021SumThingsAre;
@crema2022StatisticalInferencePrehistoric]. The distribution supplied to each
method also depends on selection among the determinations already available
for a site.

That selection cannot be recovered from date counts alone. In the original
AustArch compilation, 53% of sites had one determination and 86% had fewer than
four [@williams2014AustArchDatabase14C]. A site with one recorded date may have
been dated once, or that record may be the retained member of a larger set.
Those possibilities carry different information about regional activity.
Selection of material expected to lie near a layer's beginning or end has long
been recognised as a challenge to random-thinning assumptions in chronological
models [@nicholls2001RadiocarbonDatingTemporal]. Here we examine selection
*after* dating. Retaining the oldest or youngest completed determination is a
different operation from choosing an archaeological context in advance, and
neither retained extreme necessarily marks the beginning or end of occupation.

The statistical mechanism is straightforward: extremes drawn from a
distribution are not distributed like arbitrary members of it. What matters
for archaeological inference is how this selection propagates through
calibration and model fitting, whether retaining both ends removes the problem,
and how large the resulting deformation can be in a real compilation. We pair
simulations with known regional histories and an AustArch benchmark to separate
the choice of ages from the number retained. We assess three consequences:
changes in temporal shape, recovery of the direction of change, and
discrimination between linear and exponential histories. Together they ask
whether an inferred history reflects the underlying dates or the rule that
selected them.

### Why this route may work

The editor encounters the conceptual distinction and the strongest result
before an inventory of methods. The specialist can see the post hoc/prospective
boundary, the relevant antecedent, the matched-count design and the distinct
outcomes. This opening still needs a concise explanation of calibrated dates
and how regional summaries/models use them; that bridge should follow before
the Methods, rather than be silently deleted.

### Strongest objection

An oldest-date or youngest-date subset was selected to be temporally
unrepresentative, so an order-statistic shift is unsurprising. The paper must
show why its *inferential consequences* and the failure of apparently reassuring
comparisons merit attention. It cannot imply that all one-date-per-site
procedures select extremes or that the prevalence of this practice is known.

## Route B — start with the archive and its reuse

### Working title

Which dates represent a site? Selection effects in regional radiocarbon inference

### Abstract

The number of radiocarbon dates recorded for a site does not reveal how those
dates were selected. To test the consequences of that distinction,
we applied alternative retention rules to the same 540 charcoal or wood
determinations from 68 AustArch sites in Australia. Three rules each retained
68 dates, yet keeping the oldest shifted the mean summed probability
distribution 3,133 years older, keeping the youngest shifted it 2,439 years
younger, and random retention shifted it 103 years older on average. Oldest and
youngest retention changed temporal shape more than the choice among three
summary methods in all nine sensitivity configurations. Controlled simulations
then tested what such selection means when the regional history is known.
Retaining every site's oldest or youngest date imposed decline or growth,
respectively, in all 1,000 replicates of each constant or changing history,
including reversals of opposing trends. Keeping both extrema preserved the
direction of change while selecting exponential models for all simulated linear
histories under full-site treatment. Random retention preserved the direction
of the simulated ten-fold changes. These experiments isolate post hoc selection
among independent dates, without occupation histories or realised measurement
scatter. The results show why regional analyses need the selection history of
their inputs: equal date counts and agreement among temporal summaries cannot
establish that retained dates represent the same history.

### Alternative first paragraph

An oldest date can be useful evidence about the early use of a site. If it is
then pooled with the oldest dates from other sites to infer regional activity
through time, its meaning changes: an extreme observation is being used to
represent a site's temporal contribution. The same issue arises at the recent
end of a sequence. A regional compilation may consequently inherit a pattern
created by the purpose for which dates were selected. Knowing that each site
contributed one determination does not resolve that ambiguity.

### Strongest objection

This route makes archaeological reuse concrete, but the present study does not
document a particular instance or estimate its frequency. We cannot claim that
archaeological compilations generally omit selection histories. The opening
example also needs care: an oldest determination alone is not an
occupation-onset estimate. A fuller introduction would make the hypothetical
nature of the reuse explicit and retain the chronological-model precedent.

## Proposed Discussion centrepiece

The contribution of a site has two properties that regional analyses need to
distinguish: the number of dates it supplies and their position in its observed
age distribution. In our simulations, keeping one date per site held the first
property constant while changing the second. Random, oldest and youngest
retention then produced sharply different inferences from the same simulated
events. The AustArch benchmark gives the corresponding empirical scale: equal
68-date subsets shifted the temporal mean by about a century under random
retention and by millennia under the two extrema rules. These shifts describe
the assembled benchmark; they do not identify its true demographic history.

Retaining both extrema exposes a further difficulty. Applied to all sites, it
preserved the direction of every changing simulated history, yet selected
exponential models in every replicate generated from a linear history. Under
constant truth it selected uniform in 999 of 1,000 replicates, although pooling
the extremes of exactly observed uniform ages produces a U-shaped distribution
for the site counts used here. A candidate set containing uniform and monotonic
models cannot represent that shape. Its preferred model can therefore appear
reassuring without showing that the retained distribution has been recovered.
The exact-age calculation explains the mechanism; the simulation selected
extrema by calibrated posterior median and fitted full posteriors under working
independence for the paired extremes.

An analyst faced with a sparse regional database consequently needs to know
whether each date is the only determination obtained or one retained from a
larger collection, and whether age influenced that retention. Where the fuller
set is available, matched-count comparisons can separate the loss of dates from
selection of particular ages. Where it is unavailable, sensitivity to plausible
selection histories can reveal which interpretations depend on unrecorded
choices, but cannot reconstruct those choices. Agreement among summaries of the
same selected dates provides no independent check on their selection history.
The practical change is to make this history part of the information used to
interpret a regional curve.

## Proposed architecture and the next exchange

Route A is my current preference because it begins with the inferential
question and avoids needing an unverified real-world reuse example. Route B
tests whether a more archaeological opening is stronger, while restricting
its claim to what date counts alone can establish.

1. One continuous Introduction, with the selection problem on its first page,
   followed by enough radiocarbon context to make it intelligible.
2. A short design overview distinguishing what the simulations establish from
   what the empirical benchmark illustrates. Preserve essential Methods
   assumptions and definitions; move only genuinely operational duplication.
3. Results organised around direction, shape and empirical scale, if Claude's
   reader test supports putting the simulations first. Figure order would then
   need coordinated revision; existing figures remain untouched at this stage.
4. Discussion led by the inferential consequence and the bracketed result,
   followed by the mechanism, actionable provenance/sensitivity guidance and
   the limits controlling extrapolation.
5. A conclusion stating what an analyst must know before treating retained
   dates as regional temporal evidence. No general minimum number of dates and
   no claim that the study repairs selection bias.

Claude is asked to reject or improve these routes, supply a competing opening,
and identify what a non-specialist editor would still fail to understand. The
next deliverable is a complete candidate manuscript with a claim-preservation
audit, followed by exchanged editor and specialist critiques. No Jev evaluation
has been run on these exploratory passages; scientific adjudication and Claude's
independent response come first.
