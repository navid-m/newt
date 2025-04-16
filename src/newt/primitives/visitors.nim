import
    times,
    random,
    base64,
    strutils


const CONTENT_PLAYBACK_NONCE_ABCS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

randomize()

proc writeVarint(buf: var seq[byte], x: uint64) =
    var v = x
    while true:
        var b = byte(v and 0x7Fu)
        v = v shr 7
        if v != 0:
            buf.add(b or 0x80'u8)
        else:
            buf.add(b)
            break


proc writeKey(buf: var seq[byte], field: int, wireType: int) =
    writeVarint(buf, uint64((field shl 3) or wireType))


proc writeStringField(buf: var seq[byte], field: int, s: string) =
    writeKey(buf, field, 2)
    let bytes = cast[seq[byte]](s)
    writeVarint(buf, uint64(bytes.len))
    buf.add(bytes)


proc writeBytesField(buf: var seq[byte], field: int, data: seq[byte]) =
    writeKey(buf, field, 2)
    writeVarint(buf, uint64(data.len))
    buf.add(data)


proc randString(alphabet: string, n: int): string =
    result = newStringOfCap(n)
    for _ in 0..<n:
        result.add(alphabet[rand(alphabet.len)])


proc urlBase64*(data: seq[byte]): string =
    var b64 = encode(data) # standard Base64
    b64 = b64.replace("+", "-").replace("/", "_")
    while b64.endsWith("="):
        b64.setLen(b64.len - 1)
    result = b64


proc randomVisitorData*(countryCode: string): string =
    var e2 = newSeq[byte]()
    writeStringField(e2, 2, "")
    writeKey(e2, 4, 0); writeVarint(e2, uint64(rand(255) + 1))
    var e = newSeq[byte]()
    writeStringField(e, 1, countryCode)
    writeBytesField(e, 2, e2)

    var buf = newSeq[byte]()
    writeStringField(buf, 1, randString(CONTENT_PLAYBACK_NONCE_ABCS, 11))
    writeKey(buf, 5, 0);
    writeVarint(
        buf,
        uint64(now().toTime().toUnix() - rand(600000))
    )
    writeBytesField(buf, 6, e)
    result = urlBase64(buf)
