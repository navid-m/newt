import terminal


var loudLogger = false;
var suppressErrors = false;
var logs: seq[string]
var errors: seq[string]


proc announceLogs*(loud: bool) = loudLogger = loud
proc getAllLogs*(): (seq[string], seq[string]) = (logs, errors)


proc logInfo*(info: varargs[string, `$`]) =
    logs.add(info)
    if loudLogger:
        echo info


proc logError*(error: string) =
    errors.add(error)
    if not suppressErrors:
        styledEcho(fgRed, error)
