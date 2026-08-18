extends CollapsiblePlatformBase

func collapse() -> void:
	super.collapse()
	
	$MeshInstance3D.visible = false
	
func restore() -> void:
	super.restore()
	$MeshInstance3D.visible = true
