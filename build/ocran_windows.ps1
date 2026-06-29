$args = @(
    ".\src\ModList.rb",
    "assets\icon.ico",
    
    "--output", "KokiModManager.exe",
 
    "--icon", "assets\icon.ico",

    "--gemfile", ".\Gemfile",
    "--no-enc",

    "--windows"
    # "--console" # debug 
 )

 ocran @args