extends RefCounted
class_name KenneyCityAssets

const Roads = preload("res://scripts/assets/kenney_road_data.gd")

static func create_model(model_name: String) -> MeshInstance3D:
	var info: Dictionary = _get_model_info(model_name)
	if info.is_empty():
		return null
	var compressed: PackedByteArray = Marshalls.base64_to_raw(str(info.data))
	var raw: PackedByteArray = compressed.decompress(int(info.size), FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty():
		push_error("Could not decode model: " + model_name)
		return null

	var vertex_count := int(raw.decode_u32(0))
	var index_count := int(raw.decode_u32(4))
	var offset := 8
	var min_bounds := Vector3(raw.decode_float(offset), raw.decode_float(offset + 4), raw.decode_float(offset + 8))
	var max_bounds := Vector3(raw.decode_float(offset + 12), raw.decode_float(offset + 16), raw.decode_float(offset + 20))
	offset += 24
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(vertex_count)
	colors.resize(vertex_count)
	var bounds_size := max_bounds - min_bounds
	for i in range(vertex_count):
		var qx := float(raw.decode_u16(offset)) / 65535.0
		var qy := float(raw.decode_u16(offset + 2)) / 65535.0
		var qz := float(raw.decode_u16(offset + 4)) / 65535.0
		offset += 6
		vertices[i] = min_bounds + Vector3(qx * bounds_size.x, qy * bounds_size.y, qz * bounds_size.z)
	for i in range(vertex_count):
		colors[i] = Color8(raw.decode_u8(offset), raw.decode_u8(offset + 1), raw.decode_u8(offset + 2), 255)
		offset += 3
	var indices := PackedInt32Array()
	indices.resize(index_count)
	for i in range(index_count):
		indices[i] = raw.decode_u16(offset)
		offset += 2

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		surface.set_color(colors[index])
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh := surface.commit()
	if mesh == null:
		return null
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.name = model_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

static func _get_model_info(model_name: String) -> Dictionary:
	match model_name:
		"road-straight":
			return {"size": Roads.ROAD_STRAIGHT_SIZE, "data": Roads.ROAD_STRAIGHT}
		"road-crossroad":
			return {"size": Roads.ROAD_CROSSROAD_SIZE, "data": Roads.ROAD_CROSSROAD}
		"road-end":
			return {"size": Roads.ROAD_END_SIZE, "data": Roads.ROAD_END}
		"traffic-light":
			return {"size": Roads.TRAFFIC_LIGHT_SIZE, "data": Roads.TRAFFIC_LIGHT}
		"dumpster":
			return {"size": Roads.DUMPSTER_SIZE, "data": Roads.DUMPSTER}
	return {}
