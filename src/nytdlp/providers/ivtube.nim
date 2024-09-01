import
  strutils,
  httpclient,
  htmlparser,
  xmltree,
  strtabs,
  uri,
  strformat

import ../primitives/clients
import ../diagnostics/logger


proc extractVideoID(url: string): string =
  ## Extract video ID
  if url.contains("v="):
    let startPos = url.find("v=") + 2
    return url[startPos ..< startPos + 11]
  elif url.endsWith("/"):
    return url.split("/")[^1]
  else:
    return url


proc findVideoLink(videoID: string): string =
  ## Scrape IV and find the video download link
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


proc downloadIvStream*(videoURL: string, outputPath: string = "") =
  ## Download the fucking thing
  let videoID = extractVideoID(videoURL)
  let videoLink = findVideoLink(videoID)
  var outputPathToUse = outputPath

  if outputPath.len() == 0:
    outputPathToUse = fmt"{videoID}.mp4"

  if videoLink.len == 0:
    LogError("Could not find a valid video link.")
    return

  writeFile(outputPathToUse, PrimaryClient.getContent(videoLink))
  LogInfo(fmt"Video downloaded as {outputPathToUse}")
