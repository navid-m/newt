import
  osproc,
  strutils


proc CurrentSysHasFfmpeg*(): bool =
  try:
    let res = execCmdEx("ffmpeg -version")
    return res.exitCode == 0 and res.output.toLower().contains("ffmpeg version")
  except OSError:
    return false
