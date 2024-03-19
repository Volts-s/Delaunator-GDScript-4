# Port to Godot 4.1.3 - Tom Blackwell - 18 Mar 2024

extends Node2D

const Delaunator = preload("res://Delaunator.gd")

@export var random_points = true
@export var use_mouse_to_draw = false
@export var _draw_triangles = true
@export var _draw_triangle_edges = false
@export var _draw_voronoi_cells = false
@export var _draw_voronoi_cells_convex_hull = false
@export var _draw_voronoi_edges = false
@export var _draw_points = false
@export var _draw_triangle_centers = false
@export var debug_mode = false

@onready var input_points = $GUI/input_points

var default_seed_points = 100000
var initial_points
var points
var delaunay
var coordinates = []
var size

var delay_timer = 0
var delay_timer_limit = 0.5

var moving = false

func _ready():
	input_points.text = str(default_seed_points)

	size = get_viewport().size

#	initial_points = PackedVector2Array([
#		Vector2(0, 0),
#		Vector2(size.x, 0),
#		Vector2(size.x, size.y),
#		Vector2(0, size.y),
#		Vector2(size.x/2+25, size.y/2+25)
#	])
	
	initial_points = PackedVector2Array([
  		Vector2(0, 0), Vector2(1024, 0), Vector2(1024, 600), Vector2(0, 600), Vector2(29, 390), Vector2(859, 300), Vector2(65, 342), Vector2(86, 333), Vector2(962, 212), Vector2(211, 351), Vector2(3, 594), Vector2(421, 278), Vector2(608, 271), Vector2(230, 538), Vector2(870, 454), Vector2(850, 351), Vector2(583, 385), Vector2(907, 480), Vector2(749, 533), Vector2(877, 232), Vector2(720, 546), Vector2(1003, 541), Vector2(696, 594), Vector2(102, 306)]
	)

	if random_points:
		points = get_random_points(int(input_points.text))
	else:
		points = initial_points

	if debug_mode: print("points:", points)

	delaunay = Delaunator.new(points)

	if debug_mode: print("delaunay.triangles(", delaunay.triangles.size()%3,"): ", delaunay.triangles)
	if debug_mode: print("delaunay.halfedges: ", delaunay.halfedges)
	if debug_mode: print("delaunay.hull: ", delaunay.hull)
	if debug_mode: print("delaunay.coords: ", delaunay.coords)
	
#	var githubextris = [11, 16, 12, 11, 13, 16, 22, 20, 16, 16, 15, 12, 20, 18, 16, 13, 22, 16, 20, 22, 18, 18, 15, 16, 15, 5, 12, 9, 13, 11, 8, 19, 5, 5, 19, 12, 12, 0, 11, 18, 14, 15, 15, 8, 5, 17, 14, 18, 0, 23, 11, 11, 23, 9, 9, 4, 13, 14, 17, 15, 21, 17, 2, 23, 7, 9, 23, 6, 7, 7, 4, 9, 17, 8, 15, 19, 1, 12, 6, 4, 7, 2, 17, 18, 17, 21, 8, 22, 2, 18, 21, 1, 8, 4, 10, 13, 13, 3, 22, 22, 3, 2, 4, 3, 10, 10, 3, 13, 2, 1, 21, 8, 1, 19, 1, 0, 12, 23, 0, 6, 6, 0, 4, 4, 0, 3]
#	print("githubtris_size:",githubextris.size(), " mod 3: ", githubextris.size() % 3)

func _input(event):
	if use_mouse_to_draw and event is InputEventMouseMotion:
		moving = true


func _process(_delta):
	if moving:
		if get_global_mouse_position().x >= 0 and get_global_mouse_position().y >= 0:
			delay_timer += 0.1
			if delay_timer > delay_timer_limit:
				delay_timer -= delay_timer_limit
				points.append(get_global_mouse_position())
				delaunay = Delaunator.new(points)
				queue_redraw() # replaces update in Godot 4
			moving = false


func _draw():
	if _draw_triangles: draw_triangles(points, delaunay)

	if _draw_triangle_edges: draw_triangle_edges(points, delaunay)

	if _draw_voronoi_cells: draw_voronoi_cells(points, delaunay)

	if _draw_voronoi_cells_convex_hull: draw_voronoi_cells_convex_hull(points, delaunay)

	if _draw_voronoi_edges: draw_voronoi_edges(points, delaunay)

	if _draw_points: draw_points()

	if _draw_triangle_centers: draw_triangle_centers()


func get_random_points(seed_points = default_seed_points):
	var new_points = []
	new_points.resize(initial_points.size() + seed_points)

	for i in range(new_points.size()):
		if i >= initial_points.size():
			var new_point = Vector2(randi() % int(size.x), randi() % int(size.y))
			# Uncomment these lines if you need points outside the boundaries.
#			new_point *= -1 if randf() > 0.5 else 1
#			new_point *= 1.15 if randf() > 0.5 else 1
			new_point.x = int(new_point.x)
			new_point.y = int(new_point.y)
			new_points[i] = new_point
		else:
			new_points[i] = initial_points[i]

	return new_points


func draw_triangles(points, delaunay):
	for t in delaunay.triangles.size() / 3:
		var color = Color(randf(), randf(), randf(), 1)
		# Toggle these lines to draw poly lines or polygons.
#		draw_polyline(points_of_triangle(points, delaunay, t), Color.black)
		draw_polygon(points_of_triangle(points, delaunay, t), PackedColorArray([color]))


func draw_triangle_edges(points, delaunay):
#	print("point size:", points.size(), " Triangles:", delaunay.triangles.size())
	for e in delaunay.triangles.size():
#		print()
#		print ("triangle edge: ", e)
		if e > delaunay.halfedges[e]: #
			var next_e = next_half_edge(e)
			#print("e:", e, " next_half_edge(e):", next_e, " point:", delaunay.triangles[next_e])
			#if next_e > delaunay.triangles.size()-1:
			#	continue
			var p = points[delaunay.triangles[e]]
			var q = points[delaunay.triangles[next_half_edge(e)]]
			#print("Line ", p, q)
			draw_line(p, q, Color.BLUE, 10.0)


func draw_voronoi_edges(points, d):
	for e in d.triangles.size():
		if (e < d.halfedges[e]):
			var p = triangle_center(points, d, triangle_of_edge(e));
			var q = triangle_center(points, d, triangle_of_edge(d.halfedges[e]));
			draw_line(
				Vector2(p[0], p[1]),
				Vector2(q[0], q[1]),
				Color.WHITE)


func draw_voronoi_cells(points, delaunay):
	var seen = []
	for e in delaunay.triangles.size():
		var triangles = []
		var vertices = []
		var p = delaunay.triangles[next_half_edge(e)]
		if not seen.has(p):
			seen.append(p)
			var edges = edges_around_point(delaunay, e)
			for edge in edges:
				triangles.append(triangle_of_edge(edge))
			for t in triangles:
				vertices.append(triangle_center(points, delaunay, t))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PackedVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))
			draw_polygon(voronoi_cell, PackedColorArray([color]))


func draw_voronoi_cells_convex_hull(points, delaunay):
	var index = {}

	for e in delaunay.triangles.size():
		var endpoint = delaunay.triangles[next_half_edge(e)]
		if (!index.has(endpoint) or delaunay.halfedges[e] == -1):
			index[endpoint] = e

	for p in points.size():
		var triangles = []
		var vertices = []
		var incoming = index.get(p)

		if incoming == null:
			triangles.append(0)
		else:
			var edges = edges_around_point(delaunay, incoming)
			for e in edges:
				triangles.append(triangle_of_edge(e))

		for t in triangles:
			vertices.append(triangle_center(points, delaunay, t))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PackedVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))
			draw_polygon(voronoi_cell, PackedColorArray([color]))


func draw_points():
	for point in points:
		draw_circle(point, 5, Color("#bf4040"))


func draw_triangle_centers():
	for t in delaunay.triangles.size() / 3:
		draw_circle(
			Vector2(
				triangle_center(points, delaunay, t)[0],
				triangle_center(points, delaunay, t)[1]
			), 5, Color.WHITE)
		draw_circle(
			Vector2(
				triangle_center(points, delaunay, t)[0],
				triangle_center(points, delaunay, t)[1]
			), 4, Color("#4040bf"))


func edges_of_triangle(t):
	return [3 * t, 3 * t + 1, 3 * t + 2]


func triangle_of_edge(e):
	return floor(e / 3)


func next_half_edge(e):
	#(e % 3 === 2) ? e - 2 : e + 1;
	return e - 2 if e % 3 == 2 else e + 1


func prev_half_edge(e : int):
	return e + 2 if e % 3 == 0 else e - 1


func points_of_triangle(points, delaunay, t):
	var points_of_triangle = []
	for e in edges_of_triangle(t):
		points_of_triangle.append(points[delaunay.triangles[e]])
	return points_of_triangle


func edges_around_point(delaunay, start):
	var result = []
	var incoming = start
	while true:
		result.append(incoming);
		var outgoing = next_half_edge(incoming)
		incoming = delaunay.halfedges[outgoing];
		if not (incoming != -1 and incoming != start): break
	return result


func triangle_adjacent_to_triangle(delaunay, t):
	var adjacent_triangles = []
	for e in edges_of_triangle(t):
		var opposite = delaunay.halfedges[e]
		if opposite >= 0:
			adjacent_triangles.append(triangle_of_edge(opposite))

	return adjacent_triangles;


func triangle_center(p, d, t, c = "circumcenter"):
	var vertices = points_of_triangle(p, d, t)
	match c:
		"circumcenter":
			return circumcenter(vertices[0], vertices[1], vertices[2])
		"centroid":
			return centroid(vertices[0], vertices[1], vertices[2])
		"incenter":
			return incenter(vertices[0], vertices[1], vertices[2])


func circumcenter(a, b, c):
	var ad = a[0] * a[0] + a[1] * a[1]
	var bd = b[0] * b[0] + b[1] * b[1]
	var cd = c[0] * c[0] + c[1] * c[1]
	var D = 2 * (a[0] * (b[1] - c[1]) + b[0] * (c[1] - a[1]) + c[0] * (a[1] - b[1]))

	return [
		1 / D * (ad * (b[1] - c[1]) + bd * (c[1] - a[1]) + cd * (a[1] - b[1])),
		1 / D * (ad * (c[0] - b[0]) + bd * (a[0] - c[0]) + cd * (b[0] - a[0]))
	]


func centroid(a, b, c):
	var c_x = (a[0] + b[0] + c[0]) / 3
	var c_y = (a[1] + b[1] + c[1]) / 3

	return [c_x, c_y]


func incenter(a, b, c):
	var ab = sqrt(pow(a[0] - b[0], 2) + pow(b[1] - a[1], 2))
	var bc = sqrt(pow(b[0] - c[0], 2) + pow(c[1] - b[1], 2))
	var ac = sqrt(pow(a[0] - c[0], 2) + pow(c[1] - a[1], 2))
	var c_x = (ab * a[0] + bc * b[0] + ac * c[0]) / (ab + bc + ac)
	var c_y = (ab * a[1] + bc * b[1] + ac * c[1]) / (ab + bc + ac)

	return [c_x, c_y]


func _on_get_random_points_pressed():
	randomize()
	points = get_random_points(int(input_points.text))
	var start = Time.get_ticks_msec()
	delaunay = Delaunator.new(points)
	var elapsed = Time.get_ticks_msec() - start
	if debug_mode: print(ProjectSettings.get_setting("application/config/name"), " execution time: ", elapsed,  "ms")
	queue_redraw() # replaces update in Godot 4
