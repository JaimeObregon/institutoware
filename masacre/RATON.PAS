UNIT Raton;

INTERFACE

USES DOS;


VAR
  ContBoton : Integer;          { N£mero de botones del rat¢n }

FUNCTION EsLogitech : Boolean;          { Examina el controlador}

PROCEDURE ResetRaton;                        { Llamada a funci¢n 0 }

PROCEDURE PunteroOn;                                           { 1 }

PROCEDURE PunteroOff;                                          { 2 }

PROCEDURE LeerRaton(VAR X,Y : Word;
                    VAR Izquierda,Centro,Derecha : Boolean);   { 3 }

PROCEDURE PunteroAXY(X,Y : Word);                              { 4 }

PROCEDURE RangoColumna(Sup,Inf : Word);                        { 7 }

PROCEDURE RangoFila(Sup,Inf : Word);                           { 8 }

{PROCEDURE LlamaRaton(VAR M1,M2,M3,M4 : Word); }



{---------------------------------------------------------------}
{                     SECCION DE EJECUCION                      }
{                                                               }
{  Hemos elegido redeclarar la lista de par metros en esta      }
{  secci¢n. Haciendo as¡ que sea m s f cil de leer y entender.  }
{  Obs‚rvese que el procedimiento de bajo nivel para acceder    }
{  al rat¢n, es privativo de la unidad y no puede accederse a   }
{  el desde el mundo exterior. Si el lector quiere probar cosas }
{  m s ex¢ticas con el controlador de rat¢n (como activa y      }
{  desactivar la emulaci¢n de lapiz ¢ptico) off) deber  mover   }
{  el procedimiento a la secci¢n de INTERFACE para hacerlo      }
{  accesible.                                                   }
{---------------------------------------------------------------}

IMPLEMENTATION


VAR
  M1,M2,M3,M4 : Word;



PROCEDURE LlamaRaton(VAR M1,M2,M3,M4 : Word);

VAR
  Regs : Registers;

BEGIN
  WITH Regs DO
    BEGIN
      AX := M1; BX := M2; CX := M3; DX := M4
    END;
  Intr(51,Regs);
  WITH Regs DO
    BEGIN
      M1 := AX; M2 := BX; M3 := CX; M4 := DX
    END
END;


FUNCTION NumeroDeBotones : Integer;

BEGIN
  M1 := 0;  { Se inicializa el rat¢n para contar los botones }
  LlamaRaton(M1,M2,M3,M4);
  NumeroDeBotones := M2
END;



FUNCTION RatonInstalado : Boolean;

TYPE
  BytePtr = ^Byte;

VAR
  VectorPrueba : BytePtr;

BEGIN
  GetIntVec(51,Pointer(VectorPrueba));
  { $CF es el c¢digo binario de la instrucci¢n IRET; }
  { en muchos BIOS, el c¢digo de arranque del sistema }
  { llena con IRETs los vectores no utilizados }
  IF (VectorPrueba = NIL) OR (VectorPrueba^ = $CF) THEN
    RatonInstalado := False
  ELSE
    RatonInstalado := True
END;


{--------------------------------------------------------------}
{    LOS PROCEDIMIENTOS POR ENCIMA DE ESTE PUNTO SON PRIVADOS  }
{--------------------------------------------------------------}

FUNCTION EsLogitech : Boolean;

TYPE
  Signature = ARRAY[0..13] OF Char;
  SigPtr = ^Signature;

CONST LogitechSig : Signature = 'LOGITECH MOUSE';

VAR
  VectorPrueba : SigPtr;
  L          : LongInt;

BEGIN
  GetIntVec(51,Pointer(VectorPrueba));
  LongInt(VectorPrueba) := LongInt(VectorPrueba) + 16;
  IF VectorPrueba^ = LogitechSig THEN
    EsLogitech := True
  ELSE
    EsLogitech := False
END;



PROCEDURE ResetRaton;

BEGIN
  M1 := 0;
  LlamaRaton(M1,M2,M3,M4);
END;


PROCEDURE PunteroOn;

BEGIN
  M1 := 1;
  LlamaRaton(M1,M2,M3,M4)
END;


PROCEDURE PunteroOff;

BEGIN
  M1 := 2;
  LlamaRaton(M1,M2,M3,M4)
END;


PROCEDURE LeerRaton(VAR X,Y : Word; VAR Izquierda,Centro,Derecha : Boolean);

BEGIN
  M1 := 3;              { Realiza la llamada de funci¢n 3 del rat¢n }
  LlamaRaton(M1,M2,M3,M4);
  X := M3; Y := M4;     { Devuelve la posici¢n X,Y apuntada por el rat¢n }
  IF (M2 AND $01) = $01 THEN Izquierda := True ELSE Izquierda := False;
  IF (M2 AND $02) = $02 THEN Derecha := True ELSE Derecha := False;
  IF (M2 AND $04) = $04 THEN Centro := True ELSE Centro := False;
  X:=X Div 2;
  If (X>320-11) Then X:=320-11; If (Y>200-20) Then Y:=200-20;
END;


PROCEDURE PunteroAXY(X,Y : Word);

BEGIN
  M1 := 4;
  M3 := X; M4 := Y;
  LlamaRaton(M1,M2,M3,M4)
END;


PROCEDURE RangoColumna(Sup,Inf : Word);

BEGIN
  M1 := 7;
  M3 := Inf;
  M4 := Sup;
  LlamaRaton(M1,M2,M3,M4)
END;


PROCEDURE RangoFila(Sup,Inf : Word);

BEGIN
  M1 := 8;
  M3 := Inf;
  M4 := Sup;
  LlamaRaton(M1,M2,M3,M4)
END;


{--------------------------------------------------------------}
{                   SECCION DE INICIALIZACION                  }
{                                                              }
{  La funci¢n RatonInstalado comprueba el vector de interrup.  }
{  51: si es igual a NIL (cero) o apunta a un IRET, se supone  }
{  que el rat¢n no est  instalado. Hay que tener presente que  }
{  una tabla de vectores llena de valores sin sentido puede    }
{  ser malinterpretada. Algunos BIOS de ordenadores as¡aticos  }
{  no inicializan la tabla de vectores de interrupci¢n de una  }
{  forma adecuada, lo que da lugar a que se produzcan errores  }
{  en la detecci¢n de los controladores instalados.            }
{--------------------------------------------------------------}


BEGIN
  IF NOT RatonInstalado THEN
    BEGIN
      Writeln('ERROR: No se detecta controlador del rat¢n. Volver al DOS.');
      HALT(1)
    END;
  ContBoton := NumeroDeBotones
END.  {Raton}
