extends Node
## Pickups reserve a clear approach and exit corridor against current AND future traffic.
const Actor = preload("res://scripts/cycling/traffic_actor.gd")
const Layout = preload("res://scripts/cycling/presentation_layout.gd")
## Longitudinal fallbacks, measured out from the offscreen minimum. They stay
## nearer than the traffic spawn band so a fresh vehicle cannot immediately
## invalidate the reserved corridor.
const AHEAD_STEPS: Array[float] = [0.0, 8.0, 16.0, 24.0, 32.0]
## Lane preference, most exposed lane first, so collecting a pickup is usually a
## decision about crossing traffic rather than a free grab in the bike lane.
const LANE_WEIGHTS: Array[float] = [5.0, 4.0, 3.0, 2.0, 1.0]
## Danishes lean harder into the exposed lanes than rugbrød does.
const LANE_BIAS: Dictionary = {"bread": 1.0, "pastry": 2.0}
## Seconds a pickup sits offscreen before it can enter the frame.
@export var spawn_lead_seconds: float = 0.6
var items: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_bread: float = 7.0
var next_pastry: float = 21.0
var feedback: String = ""
var feedback_left: float = 0.0
var enabled: bool = true
var deferred_opportunities: int = 0

func reset() -> void:
	items.clear()
	rng.seed = 20260906
	next_bread = rng.randf_range(6.0, 6.5)
	next_pastry = rng.randf_range(18.0, 23.0)
	feedback = ""
	feedback_left = 0.0
	deferred_opportunities = 0

func corridor_clear(item: Dictionary, actors: Array, rider_distance: float) -> bool:
	# Includes collision-slowed recovery and two seconds to leave the pickup.
	var horizon: float = maxf(0.0, item.distance - rider_distance) / 3.6 + 2.0
	for actor in actors:
		if actor.definition.lane != item.lane: continue
		var end: float = actor.distance + actor.definition.speed * horizon
		var margin: float = 8.0 + actor.definition.contact_size.x * 0.5
		if maxf(actor.distance, end) >= item.distance - margin and minf(actor.distance, end) <= item.distance + margin:
			return false
	return true

func traffic_clear(candidates: Array, rider_distance: float) -> bool:
	for item in items:
		if not corridor_clear(item, candidates, rider_distance): return false
	return true

## Nearest gap that still keeps a pickup outside the frame while the rider
## boosts towards it, so it is placed and reserved before it is ever visible.
func minimum_ahead(game) -> float:
	return Layout.art_horizon(game.pixels_per_metre)+game.rider.BOOST_SPEED*spawn_lead_seconds

## Weighted sample without replacement. Returns every lane in preference order
## so a blocked corridor falls back to a safer lane instead of losing the
## pickup outright.
func lane_order(kind: String) -> Array:
	var remaining: Array = [0, 1, 2, 3, 4]
	var bias: float = LANE_BIAS.get(kind, 1.0)
	var weights: Array = []
	for lane_id in remaining:
		weights.append(pow(LANE_WEIGHTS[lane_id], bias))
	var order: Array = []
	while not remaining.is_empty():
		var total: float = 0.0
		for weight in weights: total += weight
		var roll: float = rng.randf() * total
		var index: int = 0
		while index < remaining.size() - 1 and roll > weights[index]:
			roll -= weights[index]
			index += 1
		order.append(remaining[index])
		remaining.remove_at(index)
		weights.remove_at(index)
	return order

func spawn_food(kind: String, game) -> bool:
	var lanes: Array = lane_order(kind)
	# Vary longitudinal placement when traffic occupies the default approach.
	# Nearest offscreen slot first; never move hazards.
	var nearest: float = minimum_ahead(game)
	for step_ahead in AHEAD_STEPS:
		var ahead: float = nearest + step_ahead
		for lane_id in lanes:
			var item: Dictionary = {"kind":kind, "lane":lane_id, "distance":game.distance + ahead,
				"amount":20.0 if kind == "bread" else 30.0, "spawn_gap":ahead}
			if item.distance > game.route_length - 12.0: continue
			var separated: bool = true
			for existing in items:
				if absf(existing.distance - item.distance) < 12.0: separated = false
			if not separated or not corridor_clear(item, game.traffic.actors, game.distance): continue
			var reachable: bool = true
			for speed_value in game.traffic.CHECK_SPEEDS:
				if not game.traffic.has_route(game.traffic.actors, game.distance, game.rider.lane, speed_value, game.rider.contact_size, item.distance, lane_id):
					reachable = false
					break
			if reachable:
				items.append(item)
				return true
	return false

func step(delta: float, game) -> void:
	feedback_left = maxf(0.0, feedback_left - delta)
	for i in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[i]
		var start := Vector2(item.distance - game.previous_distance, item.lane - game.rider.previous_lane_position)
		var end := Vector2(item.distance - game.distance, item.lane - game.rider.lane_position)
		if Actor.swept_contact(start, end, Vector2(3.5, 0.30)):
			game.rider.add_food(item.amount)
			feedback = ("RUGBRØD +20" if item.kind == "bread" else "DANISH +30")
			feedback_left = 1.6
			items.remove_at(i)
		elif item.distance < game.distance - 12.0:
			items.remove_at(i)
	if not enabled: return
	# Start looking early inside the agreed 6-8s window, leaving safety retry time.
	if game.elapsed >= next_bread:
		if spawn_food("bread", game): next_bread = game.elapsed + rng.randf_range(6.0, 6.5)
		else:
			next_bread = game.elapsed + 0.5
			deferred_opportunities += 1
	if game.elapsed >= next_pastry:
		if spawn_food("pastry", game): next_pastry = game.elapsed + rng.randf_range(18.0, 23.0)
		else:
			next_pastry = game.elapsed + 0.5
			deferred_opportunities += 1

