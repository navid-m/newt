import strutils
import httpclient
import htmlparser
import xmltree
import strtabs
import uri
import strformat
import ../primitives/clients


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
proc downloadIvStream*(videoURL: string) =
  let videoID = extractVideoID(videoURL)
  let videoLink = findVideoLink(videoID)
  let fileName = fmt"{videoID}.mp4"

  if videoLink.len == 0:
    echo "Could not find a valid video link."
    return

  writeFile(fileName, PrimaryClient.getContent(videoLink))
  echo fmt"Video downloaded as {fileName}"
