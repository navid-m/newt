import
  ../providers/[innertube],
  ../models/mediamods

proc getMediaInfo*(url: string): VideoInfo = getInnerStreamData(url)
