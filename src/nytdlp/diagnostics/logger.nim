import terminal


var LoudLogger = false;
var SuppressErrors = false;


proc AnnounceYTLogs*(loud: bool) =
    ## Adjust log level
    LoudLogger = loud


proc LogInfo*(info: varargs[string, `$`]) =
    ## Log some information
    if LoudLogger:
        echo info


proc LogError*(error: string) =
    if not SuppressErrors:
        styledEcho(fgRed, error)
