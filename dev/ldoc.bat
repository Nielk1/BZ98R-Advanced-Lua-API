@echo off
del /Q .\..\temp
"%LUA%" preprocessor.lua
"%LUA%" "%LDOC%" . --dir .\..\docs --not_luadoc
copy /Y ldoc.css .\..\docs\ldoc.css