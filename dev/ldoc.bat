@echo off
"%LUA%" "%LDOC%" . --dir .\..\docs --not_luadoc
copy /Y ldoc.css .\..\docs\ldoc.css