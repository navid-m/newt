proc getVideoThumbnailUrls*(id: string): seq[string] =
  if id == "":
    return @[]

  return @[
    "https://img.youtube.com/vi/" & id & "/default.jpg",
    "https://img.youtube.com/vi/" & id & "/hqdefault.jpg",
    "https://img.youtube.com/vi/" & id & "/mqdefault.jpg",
    "https://img.youtube.com/vi/" & id & "/sddefault.jpg",
    "https://img.youtube.com/vi/" & id & "/maxresdefault.jpg"
  ]
