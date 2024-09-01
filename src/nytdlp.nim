import os

import
  nytdlp/providers/ivtube,
  nytdlp/providers/innertube


# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"

  try:
    downloadInnerStream(url, isAudio)
  except:
    echo "Falling back to IV, as Innertube request failed. Only video can be downloaded this way"
    echo "Details: ", getCurrentException().msg
    downloadIvStream(url)


main()
