import strutils


proc extractVideoId*(url: string): string =
  ## Extract video ID from URL
  result = url.split("=")[^1]


proc parseMimeType*(input: string): (string, string) =
  ## Parse mime type and return separate mime and codec
  let parts = input.split(";")
  return (
    parts[0].strip(),
    parts[1].strip().split("=")[1].strip(chars = {'"'})
  )
