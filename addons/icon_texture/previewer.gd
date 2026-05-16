@tool
extends EditorResourcePreviewGenerator


func _handles(type: String) -> bool:
	return type == "AtlasTexture"


func _generate(resource: Resource, size: Vector2i, metadata: Dictionary) -> Texture2D:
	if resource is IconTexture:
		var image: Image = resource.get_image()
		image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		image.convert(Image.FORMAT_RGBA8)
		return ImageTexture.create_from_image(image);
	
	return null
