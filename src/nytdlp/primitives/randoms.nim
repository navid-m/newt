import
  random,
  strformat


proc randomUserAgent*(): string =
  ## Generate random agent
  result = sample(@[
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Mobile/15E148 Safari/604.1"
  ])


proc randomIvInstance*(): string =
  ## Generate random IV instance
  result = sample(@[
    "iv.nboeck.de",
    "yewtu.be",
    "invidious.adminforge.de",
    "iv.nboeck.de"
  ])


proc randomConsentID*(): string =
  ## Get random consent ID
  let randomInt = rand(899) + 100
  return fmt"{randomInt}"
