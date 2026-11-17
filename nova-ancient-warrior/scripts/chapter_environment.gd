extends Node3D
## Each campaign chapter is a distinct PackedScene with its own collision layout and dressing.

const StageBuilder = preload("res://scripts/stage_builder.gd")
const CampaignLayout = preload("res://scripts/campaign_layout.gd")

@export_range(0, 2, 1) var chapter_index: int = 0
@export_enum("mid", "high") var graphics_quality: String = "mid"


func _ready() -> void:
	StageBuilder.build_stage(self, chapter_index, graphics_quality)
	CampaignLayout.build_stage(self, chapter_index, graphics_quality)
