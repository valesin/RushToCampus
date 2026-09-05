# Difficulty ramp and risk-weighted pickups

Status: approved 5 September 2026. Scoped deliberately small — the project is close to submission, so every number below is an exported knob with a conservative default, and no existing system is restructured.

## Problem

Only one thing scales with difficulty today. The traffic spawn interval interpolates from 5.0 s to 2.8 s over `elapsed / 120.0`, and because a clean 1500 m ride finishes near 104 s the ramp never completes — it stalls around 3.03 s. Everything else is flat: the seven authored patterns are sampled uniformly and all hold one or two actors, actor speeds are per-kind constants, the wind runs a fixed 44 s cycle at a constant -4 energy/s headwind, and food arrives every 6-6.5 s regardless of progress. A measured route peaks at 6 live actors against a cap of 24.

There is also a ceiling. Every candidate pattern is rejected unless a survivable line exists at all seven sampled speeds from 3.6 to 21.6 m/s, and the check pads each hazard by a metre of clearance per side plus 0.15 lane units. The game therefore guarantees a comfortable path through every hazard at every speed, and density alone cannot make it hard while that padding stands.

Separately, pickups are not a decision. Rugbrød only ever spawns in lanes 3 and 4 — the bike and pedestrian lanes — so the game's main energy source is always collected in safety.

## Decisions

Challenge means **precision** and **density**, not resource scarcity, planning load or raw speed.

The ramp is driven by **distance along the route**, not elapsed time. Boost decouples the two, and a time-driven ramp would let a boosting player outrun their own difficulty curve.

The ramp runs **linearly across the whole route**, so every stretch is slightly harder than the last, and it completes at university rather than overshooting.

At maximum difficulty the guaranteed safe line retains **half** today's slack. The player must choose a lane early and be roughly on time; a slightly late input still survives.

Extra density comes from **shorter gaps between encounters only** — not larger patterns, and not overlapping encounters.

Pickups are **distributed across all five lanes, weighted towards the exposed upper lanes**, so collecting one is usually a decision about crossing traffic.

## Design

### Progress dial

`run_controller` computes `clampf(distance / route_length, 0.0, 1.0)` and passes it into `traffic.step()`. The director stays free of any knowledge of route geometry.

### Precision

The route-check padding moves out of the collision loop and becomes a field on the director, recomputed once per step by interpolating `Vector2(1.0, 0.15)` down to `Vector2(0.5, 0.075)`.

A field rather than a parameter, because `food_director` calls `has_route()` too: this way pickup corridors are validated at the current difficulty automatically, with no signature churn. The field defaults to the start value, so a director constructed standalone — including in existing tests — behaves exactly as it does today.

The `dt = 0.20` lane-change budget against the real 0.18 s is deliberately left alone. It is a second-order effect and it also sets the 18 s planning horizon (`90 * dt`), so moving it would change two things at once.

### Density

`final_interval` goes from 2.8 s to **2.2 s**, and the ramp keys off progress instead of `elapsed / 120.0` so it completes at the finish. `initial_interval` stays at 5.0 s.

A rejected pattern currently forfeits its whole slot, which would silently eat the density gain. Rejected patterns, and patterns blocked by `maximum_actors`, instead reschedule `next_spawn` **1.0 s** out, mirroring the deferral `food_director` already uses.

`safe_start_seconds` stays at 5.0 so the opening still eases the player in.

### Risk-weighted pickups

One preference curve, most exposed lane first, with a per-kind strength:

- `LANE_WEIGHTS = [5.0, 4.0, 3.0, 2.0, 1.0]` for lanes 0 through 4
- `LANE_BIAS = {"bread": 1.0, "pastry": 2.0}`, applied as `pow(LANE_WEIGHTS[lane], LANE_BIAS[kind])`

That gives bread roughly 33/27/20/13/7 percent across lanes 0 to 4, and pastry a sharper 45/29/16/7/2, preserving the existing intent that the rarer +30 Danish is the riskier prize.

Each spawn attempt draws a weighted shuffle of all five lanes — sampling without replacement by weight — and tries them in that order, so it reaches for the bus lane first and degrades gracefully to safer lanes when a corridor is blocked rather than giving up. The order is drawn once per attempt from the existing seeded `rng`, so runs stay reproducible.

Pickup amounts stay tied to kind. Scaling reward by lane risk is a separate decision and the HUD labels are keyed on kind in `draw_food`.

## Invariants preserved

The fairness guarantee is untouched. Every accepted pattern still requires a survivable line at all seven sampled speeds, so the game stays winnable at maximum difficulty — only the comfort shrinks.

The offscreen-spawn work stays intact: nothing is created inside the player's field of view at any difficulty.

Live actors stay under `maximum_actors`.

## Known interactions

**The two ramps compound rather than trade off.** A smaller margin makes `has_route` more permissive, so late-route patterns are both tighter and accepted more often. Acceptance is already 20 of 25, so the headroom is bounded, but the effect runs the same direction as the interval change.

**The realized pickup distribution will be less top-heavy than the weights suggest.** The risky lanes are also the most frequently blocked: `corridor_clear` pads each hazard by `8.0 + contact_size.x * 0.5`, which is 14.5 m for a bus, and a bus sweeps roughly 240 m backward over the approach horizon. Nearly any bus within 240 m ahead vetoes a lane-0 pickup. The weights express a preference, not an outcome.

**Pickup availability should hold up despite that**, because the weighted shuffle falls back to lanes 3 and 4 at the same distance step. Only the lane changes, not the success rate. This is the main risk to the energy economy and must be measured, since rugbrød is the primary energy source.

**Risky-lane pickups get accepted more often late in the route**, when margins are tighter and traffic is densest. More temptation into the bus lane exactly as the bus lane gets worse.

## Out of scope

Wind behaviour, food cadence, actor speeds, pattern contents and size, encounter overlap, `maximum_actors`, rider speeds, and reward-by-lane scaling.

## Verification

Invariants: margin at progress 0 matches today's values exactly, margin at progress 1 hits the floor, and both margin and interval are monotonically non-increasing. `all_patterns_all_lanes_speed_extremes` re-runs at progress 1.0 to prove all seven patterns stay survivable in all five lanes at maximum difficulty. Live actors stay under the cap and nothing spawns in view at peak density.

Measurements to report: encounters per 100 m early versus late, accepted and rejected counts, peak live actors, realized pickup distribution per lane, and total pickups placed against the current baseline of 14 rugbrød and 4 Danishes.

## Baseline for comparison

Measured on the seeded route at 14.4 m/s before this change: 20 accepted encounters, 5 rejected, 6 peak live actors, 14 rugbrød and 4 Danishes placed, 8 deferred pickup opportunities, 104 s route time.
