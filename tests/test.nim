import newt

newt.announceLogs(true)

let vidInf = newt.getVideoInfo("https://www.youtube.com/watch?v=5ANuXhk9qWM")
let bestAudioFormat = newt.getBestFormat(vidInf.formats, FormatType.audio)

newt.downloadYtStreamByFormat(bestAudioFormat, vidInf.title)
