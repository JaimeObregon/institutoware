Program Parser;

Uses
  Dos, Crt;

Var
  Origen, Destino                       : File;
  X, Y                                  : Word;
  Buffer                                : Pointer;
  Ancho, Alto, OldAncho                 : LongInt;
  I                                     : LongInt;
  Plano                                 : Array[1..4] Of Byte;

Const
  P                                     = 3;

Begin

  ClrScr;
  Assign(Origen, 'FONDO.VGA'); Reset(Origen, 1);
  Assign(Destino, 'FONDO3.VGA'); ReWrite(Destino, 1);
  GetMem(Buffer, 64000);
  BlockRead(Origen, Ancho, 2); BlockRead(Origen, Alto, 2);
  WriteLn(' Ancho           : ', Ancho+1);
  WriteLn(' Alto            : ', Alto+1);
  I:=(Alto+1)*(Ancho+1)+4;
  WriteLn(' Tama¤o estimado : ', I);
  WriteLn(' Tama¤o real     : ', FileSize(Origen));
  OldAncho:=Ancho;
  Ancho:=0; For X:=0 To OldAncho Do If X MOD 4 = P Then Inc(Ancho);
  Dec(Ancho);
  WriteLn(' Nuevo ancho     : ', Ancho+1);
  WriteLn(' Nuevo alto      : ', Alto+1);
  BlockWrite(Destino, Ancho, 2); BlockWrite(Destino, Alto, 2);
  WriteLn(' Tama¤o estimado : ', (Ancho+1)*(Alto+1)+4);

  For Y:=0 To Alto Do
    Begin
      For X:=0 To OldAncho Do
        Begin
          BlockRead(Origen, Plano[1], 1);
          If X MOD 4 = P Then
            Begin BlockWrite(Destino, Plano[1], 1); End;
        End;

    End;
  Close(Origen);
  WriteLn(' Tama¤o real     : ', FileSize(Destino));

   Plano[1]:=$D8; Plano[2]:=$D8;
   BlockWrite(Destino, Plano[1], 2);
  Close(Destino);

  FreeMem(Buffer, 64000);


End.