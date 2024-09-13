var highQualMerging = false

proc UseHighQualityVideoMerging*(toggle: bool) = highQualMerging = toggle
proc GetHighQualMergeStatus*(): bool = highQualMerging
