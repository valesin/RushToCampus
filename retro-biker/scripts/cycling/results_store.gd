extends RefCounted
## Shared best-distance persistence. Last-run statistics intentionally remain in memory.
const PATH: String = "user://cycling_best.json"

static func read_best(path: String = PATH) -> float:
	if not FileAccess.file_exists(path): return 0.0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return 0.0
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return 0.0
	var parsed = parser.data
	if not parsed is Dictionary: return 0.0
	var value = parsed.get("best_distance", 0.0)
	if not (value is float or value is int): return 0.0
	return maxf(0.0, float(value)) if is_finite(float(value)) else 0.0

static func write_best(distance: float, path: String = PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"best_distance": distance}))
	file.flush()
	return file.get_error() == OK
