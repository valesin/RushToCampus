class_name SpriteUtil
extends RefCounted

# Texture helpers shared by every entity. A real PNG at `path` is cropped to its
# opaque bounding box (generated sprites come with big transparent margins);
# if the PNG is missing, a solid-color placeholder is returned instead. This
# lets the game render before art exists and pick up real art with no scene edits.
static func texture_for(path: String, color: Color, size: int, height: int = -1) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path)
		if t is Texture2D:
			return _crop_to_opaque(t as Texture2D)
	var h := size if height < 0 else height
	var img := Image.create(size, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

# If the texture has transparent margins, return an AtlasTexture cropped to the
# opaque bounding box; otherwise return it unchanged.
static func _crop_to_opaque(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return tex
	if img.is_compressed():
		img.decompress()
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return tex
	if used.position == Vector2i.ZERO and used.size == img.get_size():
		return tex
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(used)
	return atlas

# Sets sprite.texture and scales the sprite so the art displays at
# target_w x target_h pixels regardless of the source image resolution.
# (Used for square tiles where filling the box is fine.)
static func apply(sprite: Sprite2D, path: String, color: Color, target_w: float, target_h: float) -> void:
	var tex := texture_for(path, color, int(target_w), int(target_h))
	sprite.texture = tex
	var sz := tex.get_size()
	if sz.x > 0 and sz.y > 0:
		sprite.scale = Vector2(target_w / sz.x, target_h / sz.y)

# Fits the art to a target HEIGHT while preserving aspect ratio (so trimmed
# sprites aren't stretched), then resizes `collider` (a RectangleShape2D) to
# match the displayed art minus a small inset. This makes the hitbox track what
# you actually see, not the source PNG's dimensions.
static func apply_fitted(sprite: Sprite2D, collider: CollisionShape2D, path: String, color: Color, target_h: float, inset_x: float = 4.0, inset_y: float = 2.0) -> void:
	var tex := texture_for(path, color, int(target_h * 0.6), int(target_h))
	sprite.texture = tex
	var sz := tex.get_size()
	if sz.x <= 0 or sz.y <= 0:
		return
	var s := target_h / sz.y
	sprite.scale = Vector2(s, s)
	if collider != null and collider.shape is RectangleShape2D:
		var r := (collider.shape as RectangleShape2D).duplicate() as RectangleShape2D
		r.size = Vector2(maxf(4.0, sz.x * s - inset_x), maxf(4.0, sz.y * s - inset_y))
		collider.shape = r
