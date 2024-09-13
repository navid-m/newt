import
    ../providers/[innertube]

proc getMediaInfo*(url: string) =
    getInnerStreamData(url)
