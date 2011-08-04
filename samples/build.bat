@echo off
setlocal EnableDelayedExpansion
set "TAGLIB=..\taglib"
:: ~ implib taglib_implib.lib tag_c.def
For %%a in (*.d) do dmd -g -of%%~na.exe %%a -I.. %TAGLIB%\taglib.lib taglib_implib.lib
:: ~ For %%a in (dtagreader.d) do dmd -g -of%%~na.exe %%a -I.. %TAGLIB%\taglib.lib taglib_implib.lib && %%~na.exe "E:\My Music\Arch Enemy\1998 - Stigmata\(01) [Arch Enemy] Beast of Man.flac"

:: ~ dmd -g folderstats.d -I.. %TAGLIB%\taglib.lib taglib_implib.lib && folderstats.exe "E:\My Music\Arch Enemy"

del *.obj
