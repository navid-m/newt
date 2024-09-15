import newt

let vidInf = newt.getVideoInfo("https://www.youtube.com/watch?v=5ANuXhk9qWM")
let bestAudioFormat = newt.getBestFormat(vidInf.formats, FormatType.audio)

downloadYtStreamByFormat(bestAudioFormat, vidInf.title)
