@Echo off
REM  Men£ fulero para...     ---[ Aceleraci¢n Tangencial ]---
REM  La programaci¢n BATCH tiene mucho futuro por delante.

:Otra
REN MENU.BIN MENU.EXE
menu
if errorlevel 3 goto salir
if errorlevel 2 goto circuitos
if errorlevel 1 goto Jugar_de_una_puta_vez
goto salir

:Jugar_de_una_puta_vez
REN CARS.BIN CARS.EXE
cars
REN CARS.EXE CARS.BIN
goto otra

:Circuitos
Echo.
Echo  Opci¢n no disponible todav¡a porque no a avido tienpo.
Echo  Pulsa cualquier tecla para que te meta un dedo en el ojo.
Pause > NUL
Goto Salir

:Salir
REN MENU.EXE MENU.BIn
