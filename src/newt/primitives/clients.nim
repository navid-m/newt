import
  httpclient,
  randoms


let PrimaryClient* = newHttpClient()

PrimaryClient.headers.add("User-Agent", randomUserAgent())
PrimaryClient.headers.add("Connection", "keep-alive")
