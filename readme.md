# Newt

YouTube downloader library and command-line interface (CLI) built on Nim.

### Usage

```nim
import newt

# Download audio from a video
let audioUrl = "https://www.youtube.com/watch?v=example"
downloadYtAudio(audioUrl)

# Download best quality video
let videoUrl = "https://www.youtube.com/watch?v=example"
downloadBestYtVideo(videoUrl)

# Get available streams for given video
let info = getMediaInfo(videoUrl)
info.showAvailableFormats()

# Get video information
let videoInfo = getMediaInfo(videoUrl)
videoInfo.showVideoDetails()
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
