import strutils


# Extract video ID from URL
proc extractVideoId*(url: string): string = result = url.split("=")[^1]
