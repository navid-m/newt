# Package

version       = "1.0.5"
author        = "Navid M"
description   = "Youtube downloader library and CLI"
license       = "GPLv3"
srcDir        = "src"
bin           = @["newt"]

# Dependencies

requires "nim >= 2.0.8"
requires "nancy >= 0.1.1"

task make, "Build the project in release mode":
  exec "nimble build -d:ssl -d:release --opt:size --stackTrace:off -d:strip --mm:arc"

task dev, "Build the project in dev mode":
  exec "nimble build -d:ssl"
