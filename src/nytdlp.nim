import os
import nytdlp/providers/ivtube


# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let isVideo = paramStr(1) == "-v"

  if isAudio or isVideo:
    downloadIvStream(url)
  else:
    echo "Invalid args."
    quit(1)


main()
