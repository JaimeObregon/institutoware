TYPE 
  TTiempoString = String[20]; 
VAR 
  ContadorPulsos : LongInt ABSOLUTE $0040:$006C;
  Tinicio, Ttiempo : LongInt;

  PROCEDURE IniTemporizacion;
  BEGIN
    Tinicio := ContadorPulsos;
    {­comienza al principio de un pulso!} 
    REPEAT UNTIL Tinicio <> ContadorPulsos; 
    Tinicio := ContadorPulsos; 
  END;

  PROCEDURE FinTemporizacion;
  BEGIN Ttiempo := ContadorPulsos - Tinicio; END;

  FUNCTION LapsoTiempo : TTiempoString;
  VAR Temp : TTiempoString;
    Sec10 : LongInt;
  BEGIN
    Sec10 := Ttiempo  * 2470 DIV 4497;
    Str(Sec10:2, Temp);
    IF Temp[1] = ' ' THEN Temp[1] := '0';
    Inc(Temp[0]);
    Temp[length(Temp)] := Temp[Pred(length(Temp))];
    Temp[pred(length(Temp))] := '.';
    LapsoTiempo := Temp;
  END;
