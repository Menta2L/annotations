call  C:\php-7.1.5-Win32-VC14-x64\phplemon.bat parser.y
move parser.php parser.plex
call  C:\php-7.1.5-Win32-VC14-x64\plex.bat parser.plex
del parser.out
del parser.plex