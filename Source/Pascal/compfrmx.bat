@echo OFF
rem there's a Standard version IF %1X == X GOTO CUSTERR
@echo ON
SET HLPATH=\hsllib
C:\FPC\2.6.0\bin\i386-win32\fpc -B -n @FpNoDef.CFG -d%1 -Fu%HLPATH% -Fi%HLPATH% -Fl%HLPATH% -dMULTIPASSWORD FORMIXW8
C:\FPC\2.0.0\bin\i386-win32\fpc -B -n @FpNoDef.CFG -d%1 -Fu%HLPATH% -Fi%HLPATH% -Fl%HLPATH% -dMULTIPASSWORD FORMIX
@echo OFF
GOTO LASTLINE

:CUSTERR
ECHO Customer not defined.

:LASTLINE
