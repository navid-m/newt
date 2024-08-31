import json


let Agent* = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
let DownloaderAgent* = "com.google.android.youtube/18.11.34 (Linux; U; Android 11) gzip"
let APIKey* = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"

let ClientContext* = %*{
  "client": {
    "hl": "en",
    "gl": "US",
    "clientName": "WEB",
    "clientVersion": "2.20200720.00.02",
    "androidSDKVersion": 30,
    "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "timeZone": "UTC",
    "utcOffset": 0
  }
}

let DownloaderClientContext* = %*{
  "client": {
    "hl": "en",
    "gl": "US",
    "clientName": "ANDROID",
    "clientVersion": "18.11.34",
    "androidSDKVersion": 30,
    "userAgent": DownloaderAgent,
    "timeZone": "UTC",
    "utcOffset": 0
  }
}
