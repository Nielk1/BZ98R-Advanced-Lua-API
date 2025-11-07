@echo off

ECHO Clean up previous output and prepare new files for bare docs
del /Q ..\temp\*
copy .luarc.json ..\temp
copy ..\dev\scriptutils.lua ..\temp

for %%F in (..\temp\*.lua) do (
    powershell -File blank_ignore.ps1 -InputFile "%%F" -OutputFile "%%F.clean"
    REM powershell -File make_global.ps1 -InputFile "%%F" -OutputFile "%%F.dirty"
    move "%%F.clean" "%%F"
)

del doc.json
"%LLS%" --doc ..\temp
"%BakeLuaApiData%" "doc.json" "..\temp" "%JSON1%" --nodeprecate --name="BZ98R ScriptUtils"

ECHO Clean up previous output and prepare new files for full docs
del doc.json
del /Q ..\temp\*
copy .luarc.json ..\temp
copy ..\dev\scriptutils.lua ..\temp
copy ..\baked\*.lua ..\temp
REM echo Drop monkey-patches that make LLS Doc crap out
REM del ..\temp\_fix.lua

for %%F in (..\temp\*.lua) do (
    powershell -File blank_ignore.ps1 -InputFile "%%F" -OutputFile "%%F.clean"
    REM powershell -File make_global.ps1 -InputFile "%%F" -OutputFile "%%F.dirty"
    move "%%F.clean" "%%F"
)

del doc.json
"%LLS%" --doc ..\temp
"%BakeLuaApiData%" "doc.json" "..\temp" "%JSON2%" --name="BZ98R _api Wrapper" --desc="Wrapper for Battlezone 98 Redux's LUA API, and optionally other native API modules, with added functionality."
