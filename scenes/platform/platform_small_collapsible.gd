extends PlatformCollapsibleBase

@onready var crumbling_particles := $CrumblingParticles

func collapse() -> void:
	super.collapse()
	$MeshInstance3D.visible = false
	crumbling_particles.amount_ratio = 1.0
	crumbling_particles.explosiveness = 1
	crumbling_particles.amount = 16
	crumbling_particles.one_shot = true

func restore() -> void:
	super.restore()
	$MeshInstance3D.visible = true

func start_collapse() -> void:
	crumbling_particles.amount_ratio = 0.5
	crumbling_particles.explosiveness = 0
	crumbling_particles.amount = 8
	crumbling_particles.one_shot = false
	crumbling_particles.emitting = true

func end_collapse() -> void:
	crumbling_particles.amount_ratio = 0.0
