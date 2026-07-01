class_name DamagePopupBatcher

## Pending-hits merge rules (batching logic).
## Plain class — initialized with .new() by DamagePopupPool.
## Reads batch_radius_px / batch_time_window_sec directly from the pool reference.

var _pool    # DamagePopupPool
var _spawner # DamagePopupSpawner

var _pending_batches: Array[Dictionary] = []


func init(pool, spawner) -> void:
	_pool = pool
	_spawner = spawner


## Try to merge `amount` into an existing nearby batch; otherwise open a new one.
func try_batch(pos: Vector2, amount: int, is_crit: bool, tint: Color) -> void:
	if amount <= 0:
		return

	var batch_radius_sq: float = _pool.batch_radius_px * _pool.batch_radius_px

	for batch in _pending_batches:
		var batch_pos: Vector2 = batch.get("position", Vector2.ZERO)
		var batch_tint: Color  = batch.get("tint", Color.WHITE)
		var dist_sq := pos.distance_squared_to(batch_pos)

		if dist_sq <= batch_radius_sq and batch_tint == tint:
			batch["amount"]  = batch.get("amount", 0) + amount
			batch["is_crit"] = batch.get("is_crit", false) or is_crit
			batch["time"]    = Time.get_ticks_msec() / 1000.0
			return

	_pending_batches.append({
		"position": pos,
		"amount":   amount,
		"is_crit":  is_crit,
		"tint":     tint,
		"time":     Time.get_ticks_msec() / 1000.0,
	})


## Flush every batch whose time window has expired.
func process_batches() -> void:
	if _pending_batches.is_empty():
		return

	var current_time := Time.get_ticks_msec() / 1000.0
	var to_remove: Array[int] = []

	for i in range(_pending_batches.size()):
		var batch := _pending_batches[i]
		var batch_time: float = batch.get("time", 0.0)

		if current_time - batch_time >= _pool.batch_time_window_sec:
			_spawner.spawn(
				batch.get("position"),
				batch.get("amount"),
				batch.get("is_crit"),
				batch.get("tint", Color.WHITE)
			)
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		var idx: int = to_remove[i]
		if idx >= 0 and idx < _pending_batches.size():
			_pending_batches.remove_at(idx)


## Discard all pending batches (called on pool reset).
func clear() -> void:
	_pending_batches.clear()
