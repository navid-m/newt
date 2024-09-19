import
  ../providers/[innertube],
  ../models/mediamods


proc getVideoInfo*(url: string): VideoInfo = getInnerStreamData(url)
