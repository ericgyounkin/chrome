extends Navigation2D


var basetransform = null
var navpolyid = 1
var firstrebuild = true
var tst = []


func _ready():
	add_to_group('activenav')
	basetransform = $navigationpolygon.get_relative_transform_to_parent(get_parent())

func _draw():
	# every collision polygon used to update the navpoly is drawn here in red
#	for pools in tst:
#		var temp = Array(pools)
#		for i in range(0, len(temp)):
#			if i == (len(temp) - 1):         # have to transform with the mapnav transform to line up with actualy navpoly holes
#				draw_line(basetransform.xform(temp[0]), 
#					      basetransform.xform(temp[len(temp) - 1]), Color(255,0,0), 1)
#			else:
#				draw_line(basetransform.xform(temp[i]), 
#				          basetransform.xform(temp[i + 1]), Color(255,0,0), 1)
	pass

# https://godotengine.org/qa/26104/how-can-you-get-navigation2d-recognize-updates-the-nav-mesh
func remove_obstructions():
	for build in get_tree().get_nodes_in_group('building'):
		var cutout = build.get_node('CollisionPolygon2D')
		var adjustedpoly = adjustPolygonPosition(cutout.global_transform, cutout.polygon)    # Take every collision2d in buildings and remove the navpoly transform so they line up with the level
		$navigationpolygon.navpoly.add_outline(adjustedpoly)  
		tst.append(adjustedpoly)
		update()
	$navigationpolygon.navpoly.make_polygons_from_outlines()  # Every outline added here is then removed from the navpoly instance
	rebuildNavPath()
		
func adjustPolygonPosition(inTransform, inPolygon):  # Preserve polygon position and rotation by applying transforms yourself
	var outPolygon = PoolVector2Array()
	var finalTransform = $navigationpolygon.transform.affine_inverse() * inTransform  # inverse to back out transformation applied by adding to the navigationpolygon, affine because buildings are scaled!
	for vertex in inPolygon:
		outPolygon.append(finalTransform.xform(vertex))  #  Apply transform to each vertex, again only works on scaled nodes if you use affine inverse!
	#print(outPolygon)
	return outPolygon
	
func rebuildNavPath():
	if !firstrebuild:
		navpoly_remove(navpolyid)
	navpolyid = navpoly_add($navigationpolygon.navpoly, basetransform)
	firstrebuild = false
	
	# have to reset to make changes known    https://godotengine.org/qa/12926/how-to-add-polygon-navigationpolygoninstance-on-gdscript
	$navigationpolygon.enabled = false
	$navigationpolygon.enabled = true