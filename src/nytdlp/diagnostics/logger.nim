import terminal


var LoudLogger = false;
var SuppressErrors = false;


proc AnnounceYTLogs*(loud: bool) = LoudLogger = loud


proc LogInfo*(info: varargs[string, `$`]) =
    if LoudLogger:
        echo info


proc LogError*(error: string) =
    if not SuppressErrors:
        styledEcho(fgRed, error)
