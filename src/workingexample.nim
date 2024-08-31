import os
import strutils
import httpclient
import htmlparser
import xmltree
import strtabs
import uri
import strformat

# Extravt video ID
proc extractVideoID(url: string): string =
  if url.contains("v="):
    let startPos = url.find("v=") + 2
    return url[startPos ..< startPos + 11]
  elif url.endsWith("/"):
    return url.split("/")[^1]
  else:
    return url

# Scrape the Invidious page and find the video download link
proc findVideoLink(videoID: string): string =
  let url = fmt"https://yewtu.be/watch?v={videoID}"
  let client = newHttpClient()
  let pageContent = client.getContent(url)
  let parser = parseHtml(pageContent)

  for a in parser.findAll("source"):
    if a.attrs.hasKey("src"):
      let src = a.attrs["src"]
      if src.contains("local=true"):
        let toret = fmt"https://invidious.adminforge.de{src}"
        echo "HELLOW", toret, "HELLOW"
        return toret

  return ""

# Download the video
proc downloadVideo(videoLink: string, videoID: string) =
  let client = newHttpClient()
  let videoData = client.getContent(videoLink)
  let fileName = fmt"{videoID}.mp4"
  writeFile(fileName, videoData)
  echo fmt"Video downloaded as {fileName}"

proc main() =
  if paramCount() != 1:
    echo "Usage: nimtube <YouTube URL>"
    return

  let videoURL = paramStr(1)
  let videoID = extractVideoID(videoURL)

  if videoID.len != 11:
    echo "Invalid YouTube URL"
    return

  let videoLink = findVideoLink(videoID)

  if videoLink.len == 0:
    echo "Could not find a valid video link."
    return

  downloadVideo(videoLink, videoID)

main()
