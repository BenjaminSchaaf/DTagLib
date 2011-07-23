@echo off
setlocal EnableDelayedExpansion
set "TAGLIB=..\taglib"
:: ~ implib taglib_implib.lib tag_c.def
For %%a in (*.d) do dmd -g -of%%~na.exe %%a -I.. %TAGLIB%\taglib.lib taglib_implib.lib && %%~na.exe
:: ~ For %%a in (dtagexceptiontest) do dmd -g -of%%~na.exe %%a -I.. %TAGLIB%\taglib.lib taglib_implib.lib && %%~na.exe && %%~na.exe "e:My Music\Bedrock - Beautiful Strange.mp3"

del *.obj
