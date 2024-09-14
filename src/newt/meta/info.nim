import strformat


proc getVersion*(): string = return "v1.0.0"
proc showAbout*() = echo(
    &"newt {getVersion()} - Navid M (c) 2024\n\n" &
    "https://github.com/navid-m/newt\n" &
    "https://ko-fi.com/navid_m"
)
