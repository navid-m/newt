import terminal


var loudLogger = false;
var suppressErrors = false;


proc announceYtLogs*(loud: bool) = loudLogger = loud


proc logInfo*(info: varargs[string, `$`]) =
    if loudLogger:
        echo info


proc logError*(error: string) =
    if not suppressErrors:
        styledEcho(fgRed, error)
