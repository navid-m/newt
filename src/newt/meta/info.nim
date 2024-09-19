import strformat


let version = "v1.0.4"

proc showVersion*() = echo(version)
proc showAbout*() = echo(
    &"newt {version} - Navid M (c) 2024\n\n" &
    "https://github.com/navid-m/newt\n" &
    "https://ko-fi.com/navid_m"
)
