# Package

version       = "0.1.0"
author        = "Navid M"
description   = "Python's yt-dlp ported to pure nim"
license       = "MIT"
srcDir        = "src"
bin           = @["newt"]

# Dependencies

requires "nim >= 2.0.8"

requires "nancy >= 0.1.1"