# Newt

YouTube downloader library and command-line interface (CLI) built on Nim.

### Usage

```nim
import newt

# False by default
announceLogs(true)

# Get the info corresponding to the provided URL
let vidInf: VideoInfo = newt.getVideoInfo("https://www.youtube.com/watch?v=5ANuXhk9qWM")

# Get the highest bitrate audio format
let bestAudioFormat: MediaFormat = newt.getBestFormat(vidInf.formats, FormatType.audio)

# Download the stream specified in the bestAudioFormat value
downloadYtStreamByFormat(bestAudioFormat, vidInf.title)
```

### MediaFormat and VideoInfo types

```nim
type
  MediaFormat* = object
    itag*: int
    url*: string
    fps*: int
    bitrate*: int64
    mimeType*: string
    codec*: string
    contentLength*: int64
    audioSampleRate*: int64
    audioChannels*: int
    projectionType*: string
    width*: int
    height*: int
    quality*: string
    qualityLabel*: string
    audioQuality*: string

type
  VideoInfo* = object
    videoId*: string
    title*: string
    lengthSeconds*: int64
    views*: int
    description*: string
    author*: string
    liveContent*: bool
    private*: bool
    ratingsEnabled*: bool
    channelId*: string
    formats*: seq[MediaFormat]
```

---

### CLI Usage

#### **Download YouTube Video**

```bash
newt -v <yt video url>
```

#### **Download YouTube Audio**

```bash
newt -a <yt video url>
```

#### **Get List of Available Formats**

```bash
newt -f <yt video url>
```

#### **Get Video Details**

```bash
newt -i <yt video url>
```

---
