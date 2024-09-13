import
  ../providers/[innertube],
  ../models/mediamods

proc getMediaInfo*(url: string): seq[Media] = getInnerStreamData(url)
