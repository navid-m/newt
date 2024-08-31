import os
import strutils
import httpclient
import htmlparser
import xmltree
import strtabs
import uri
import strformat
import nytdlp/clients


# Extract video ID
proc extractVideoID(url: string): string =
  if url.contains("v="):
    let startPos = url.find("v=") + 2
    return url[startPos ..< startPos + 11]
  elif url.endsWith("/"):
    return url.split("/")[^1]
  else:
    return url


# Scrape IV and find the video download link
proc findVideoLink(videoID: string): string =
  let parser = parseHtml(
    PrimaryClient.getContent(
      fmt"https://yewtu.be/watch?v={videoID}"
    )
  )

  for a in parser.findAll("source"):
    if a.attrs.hasKey("src"):
      let src = a.attrs["src"]
      if src.contains("local=true"):
        let toret = fmt"https://invidious.adminforge.de{src}"
        return toret

  return ""


# Download the fucking thing
proc downloadStream(videoURL: string) =
  let videoID = extractVideoID(videoURL)
  let videoLink = findVideoLink(videoID)
  let fileName = fmt"{videoID}.mp4"

  if videoLink.len == 0:
    echo "Could not find a valid video link."
    return

  writeFile(fileName, PrimaryClient.getContent(videoLink))
  echo fmt"Video downloaded as {fileName}"


# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let isVideo = paramStr(1) == "-v"

  if isAudio or isVideo:
    downloadStream(url)
  else:
    echo "Invalid args."
    quit(1)

  echo "Downloaded to current directory."

main()
