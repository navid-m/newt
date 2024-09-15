var highQualMerging = false

proc useHighQualityVideoMerging*(toggle: bool) = highQualMerging = toggle
proc getHighQualMergeStatus*(): bool = highQualMerging
