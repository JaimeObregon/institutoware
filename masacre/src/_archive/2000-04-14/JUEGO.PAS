Program Juego;

{$G+}{$R-}{$S-}{$I-}{$Q-}{$N+}
{$DEFINE Debug}


Uses
  Dos, Crt, Grafx, Raton;

{
  --> Pedir a Pep¡n el reproductor de MP3s...
  --> Hay que sincronizar el Scroll con el Timer para que la velocidad sea
      independiente del n£mero de bitxos en pantalla.
  --> Grabar unos sonidos de disparos, cargando la escopeta, gritos, lloros,
      lamentos...
  --> Que el movimiento de los personajes no sea solo horizontal y en un
      sentido.
  --> Gotas de Sangre que salpiquen la c mara y resbalan lentamente...
  --> Optimizaci¢n mortal.

}

{$I CONTADOR.INC}

Type
  TSprite              = Record X1, Y1, X2, Y2, CX, CY : Integer; End;

Const
  Sprite               : Array[1..24] Of TSprite =
                         (
  { AlumnoSaludando 1 }  (X1:001; Y1:001; X2:039; Y2:061; CX:+00; CY:+00),
  { AlumnoSaludando 2 }  (X1:041; Y1:001; X2:079; Y2:062; CX:+00; CY:-02),
  { AlumnoSaludando 3 }  (X1:081; Y1:001; X2:118; Y2:063; CX:+05; CY:-01),
  { AlumnoSaludando 4 }  (X1:120; Y1:001; X2:178; Y2:056; CX:-03; CY:-01),
  { AlumnoSaludando 5 }  (X1:180; Y1:001; X2:220; Y2:033; CX:+07; CY:+30),
  { Pastillero 1 }       (X1:001; Y1:063; X2:038; Y2:116; CX:+07; CY:+00),
  { Pastillero 2 }       (X1:040; Y1:064; X2:073; Y2:116; CX:+07; CY:+01),
  { Pastillero 3 }       (X1:075; Y1:065; X2:101; Y2:117; CX:+10; CY:+00),
  { Pastillero 4 }       (X1:103; Y1:065; X2:158; Y2:109; CX:-04; CY:+00),
  { Pastillero 5 }       (X1:160; Y1:058; X2:205; Y2:086; CX:+0;  CY:+27),
  { DirectorSaltando 1 } (X1:001; Y1:118; X2:037; Y2:178; CX:+07; CY:+00),
  { DirectorSaltando 2 } (X1:039; Y1:118; X2:073; Y2:181; CX:+04; CY:+00),
  { DirectorSaltando 3 } (X1:075; Y1:119; X2:116; Y2:183; CX:+02; CY:+00),
  { DirectorSaltando 4 } (X1:118; Y1:122; X2:181; Y2:181; CX:-08; CY:+00),
  { DirectorSaltando 5 } (X1:160; Y1:088; X2:208; Y2:120; CX:-07; CY:+26),
  { AlumnaBotando 1 }    (X1:183; Y1:122; X2:237; Y2:195; CX:-07; CY:+9),
  { AlumnaBotando 1 }    (X1:001; Y1:001; X2:050; Y2:080; CX:05; CY:+1),
  { AlumnaBotando 1 }    (X1:053; Y1:001; X2:122; Y2:086; CX:-2; CY:-1),
  { Cursor1 }            (X1:239; Y1:122; X2:249; Y2:132; CX:0; CY:0),
  { Cursor1 }            (X1:251; Y1:122; X2:261; Y2:132; CX:0; CY:0),
  { Gota de Sangre 1 }   (X1:239; Y1:134; X2:249; Y2:144; CX:0; CY:0),
  { Gota de Sangre 2 }   (X1:251; Y1:134; X2:260; Y2:144; CX:0; CY:0),
  { Gota de sangre 1 }   (X1:263; Y1:122; X2:266; Y2:124; CX:0; CY:0),
  { Gota de sangre 2 }   (X1:268; Y1:122; X2:271; Y2:124; CX:0; CY:0)
                         );
Var
  opx, opy : word;
  tecla : char;
  HaySangre                          : Byte;
  Gotas                              : Array[0..9] Of Record
                                                        X, Y            : Word;
                                                        Velocidad       : Real;
                                                      End;

  Sincro                             : Array[0..255] Of Record
                                                          Tiempo : Word;
                                                          Tipo   : Byte;
                                                          PosX   : Integer;
                                                          PosY   : Integer;
                                                          Dir    : Word;
                                                        End;
  Origen, Tiempos                    : File;
  Fondo0, Fondo1, Fondo2, Fondo3     : Pointer;
  Sprites1, Sprites2                 : Pointer;
  Paleta                             : TPaleta;
  Plane                              : Byte;
  PVirtual                           : Word;
  Bitxo                              : Word;
  Tiempo                             : Word;
  NumBitxo                           : Word;
  Num                                : Integer;
  NumBitxos                          : Word;
  Bitxos                             : Array[0..99] Of Record
                                                         Tipo, PosX, PosY, Frame, Dir : Integer;
                                                       End;

  Const
    g                           : Real = 9.8;
    Numsang                     : Word = 23;

  Var
    I                           : Word;
    Quedan                      : Integer;
    t                           : Real;
    Puntos                      : Array[0..23] Of Record
                                                   Vox, Voy, X, Y, D : Real;
                                                   Tipo              : Word;
                                                 End;

Procedure Plano(Plane : Byte);
  Begin
    Port[$3C4] := $02; Port[$3C5]:=$01 SHL Plane;
  End;

Procedure SetStart(T : Word); Assembler;
  Asm
    mov dx,3d4h
    mov al,0ch
    mov ah,byte ptr t + 1
    out dx,ax
    mov al,0dh
    mov ah,byte ptr t
    out dx,ax
  End;

Procedure InitGame;
  Var
    Y, X, Offset, I                  : Integer;
    C, Buffer                        : Byte;
    Cadena                           : String;
  Begin
    FillChar(Gotas, SizeOf(Gotas), 0);
    InitModeX; BlackPalette; Randomize;
    GetMem(Fondo0, 48000);
    {$IFNDEF Debug}
    GetMem(Fondo1, 48000); GetMem(Fondo2, 48000); GetMem(Fondo3, 48000);
    {$ENDIF}

    GetMem(Sprites1, 64000);GetMem(Sprites2, 64000);

    Assign(Tiempos, 'TIEMPOS.PRG'); Reset(Tiempos, 1);
    I:=0; FillChar(Sincro, SizeOf(Sincro), 0);
    Repeat
      Cadena[0]:=#3; BlockRead(Tiempos, Cadena[1], 3); Seek(Tiempos, FilePos(Tiempos)+1); Val(Cadena, Sincro[I].Tiempo, X);
      Cadena[0]:=#1; BlockRead(Tiempos, Cadena[1], 1); Seek(Tiempos, FilePos(Tiempos)+1); Val(Cadena, Sincro[I].Tipo, X);
      Cadena[0]:=#3; BlockRead(Tiempos, Cadena[1], 3); Seek(Tiempos, FilePos(Tiempos)+1); Val(Cadena, Sincro[I].PosX, X);
      Cadena[0]:=#3; BlockRead(Tiempos, Cadena[1], 3); Seek(Tiempos, FilePos(Tiempos)+1); Val(Cadena, Sincro[I].PosY, X);
      Cadena[0]:=#3; BlockRead(Tiempos, Cadena[1], 3); Seek(Tiempos, FilePos(Tiempos)+2); Val(Cadena, Sincro[I].Dir, X);
      Inc(I);
    Until FilePos(Tiempos)=FileSize(Tiempos);
    NumBitxos:=I;

    Assign(Origen, 'MASACRE.PAL'); Reset(Origen, 1); Blockread(Origen, Paleta, 768); Close(Origen);
    SetPalFading(Paleta, 0);
    Assign(Origen, 'SPRITES1.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Sprites1^, 64000); Close(Origen);
    Assign(Origen, 'SPRITES2.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Sprites2^, 64000); Close(Origen);
    Assign(Origen, 'FONDO0.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Fondo0^, 48000); Close(Origen);
    {$IFNDEF Debug}
    Assign(Origen, 'FONDO1.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Fondo1^, 48000); Close(Origen);
    Assign(Origen, 'FONDO2.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Fondo2^, 48000); Close(Origen);
    Assign(Origen, 'FONDO3.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Fondo3^, 48000); Close(Origen);
    {$Endif}
    ResetRaton;
  End;

  {10.2}

Procedure DrawSprite(Cual : Integer; DondeX, DondeY, dir : Integer);
  Var
    valor :word;
    X, Y, I, X3                 : Integer;
    X1, Y1, X2, Y2              : Word;
    Color, Segm                 : Word;
    P                           : ShortInt;
  Begin
    X1:=Sprite[Cual].X1; Y1:=Sprite[Cual].Y1;
    X2:=Sprite[Cual].X2; Y2:=Sprite[Cual].Y2;
    P := (DondeX+Sprite[Cual].CX);
    P:=P MOD 4;
    if p < 0 then p:=p+4;
    If (Cual < 17) Or ((Cual >= 19) And (Cual <= 24)) Then Segm:=Seg(Sprites1^)
    Else Segm:=Seg(Sprites2^);
    For I:=0 To 3 Do
      Begin
{12.6}
{9.9}
{5.1 con directivas desactivadas}
{4.9}
{4.1}
{3.6}
{3.5}

        Port[$3C4] := $02; Port[$3C5]:=$01 SHL P; { EN LUGAR DE:Plano(P);}
        Inc(P); If P = 4 Then P:=0;

        For Y:=0 To Y2-Y1 Do
          For X3:=0 To ((X2-X1-i) DIV 4) Do
            Begin
              x:=X3*4+i;

              Color:=Mem[Segm:(Y+Y1)*320+(X+X1)];

              If Color <> 72 Then
                begin
                  valor:=(DondeX+X+Sprite[Cual].CX);
                  if (Valor <= 319) And (Valor >= 0) then
                    Mem[$A000:PVirtual+(DondeY+Y+Sprite[Cual].CY)*80+Valor DIV 4]:=Color;
                end;
            End;
      End;
  End;

Procedure DrawGotas;
  Var
    Indice                      : Byte;
  Begin
    For Indice:=0 To 9 Do
      Begin
        If Gotas[Indice].X <> 0 Then
          Begin
            DrawSprite(21+random(2), Gotas[Indice].X, Gotas[Indice].Y, 0);
            Inc(Gotas[Indice].Y, Round(Gotas[Indice].Velocidad));
            Gotas[Indice].Velocidad:=(Gotas[Indice].Velocidad+1)*0.7;
            If Gotas[Indice].Y>200 then Gotas[Indice].x:=0;
          End;
      End;
  End;


Procedure LaserBerri(PosX, PosY : Word);
  Begin

{    Repeat
      WaitRetrace;                }
      For I:=0 To Numsang Do
        Begin
          If Puntos[I].X <> 255 Then
            Begin
{              PutPixel(Round(PosX+Puntos[I].X), Round(PosY+Puntos[I].Y), 0);}
              Puntos[I].D:=Puntos[I].D-1;
              Puntos[I].X:=(Puntos[I].Vox*t);
              Puntos[I].Y:=(Puntos[I].Voy*t+0.5*g*t*t);
              If Puntos[I].X+PosX<000 Then Puntos[I].D:=0;
              If Puntos[I].X+PosX>319 Then Puntos[I].D:=0;
              If Puntos[I].Y+PosY>199 Then Puntos[I].D:=0;
              If Puntos[I].D <= 0 Then
                Begin
{                  PutPixel(Round(PosX+Puntos[I].X), Round(PosY+Puntos[I].Y), 0);}
                  Puntos[I].X:=255; Dec(Quedan);
                End
              Else
              DrawSprite(23+Puntos[I].Tipo, Round(PosX+Puntos[I].X), Round(PosY+Puntos[I].Y), 0);
              {
              {PutPixel(Round(PosX+Puntos[I].X), Round(PosY+Puntos[I].Y), Puntos[I].Color)
              }
            End;
        End;
      t:=t+0.09;
    If Quedan<0 then haysangre:=0;

  End;

Procedure PlayGame;
  Var
    X, Plane, I, A, N, f, s, r, K       : Integer;
    Px, Py                              : Word;
    Izq, Cen, Der                       : Boolean;

  Procedure DrawRaton;
    Begin
      LeerRaton(Px, Py, Izq, Cen, Der);
      DrawSprite(19, px, Py, 0);
    End;

  Procedure Draw(EnQuePlano, QueFondo: Word);
    Var
      Y                                 : Word;
    Begin
      Plano(EnQuePlano);
      Case QueFondo Of
        0 : For Y:=0 To 199 Do Move(Mem[Seg(Fondo0^):240*Y+X DIV 4], Mem[$A000:PVirtual+Y*80], 80);
        {$IFNDEF Debug}
        1 : For Y:=0 To 199 Do Move(Mem[Seg(Fondo1^):240*Y+X DIV 4], Mem[$A000:PVirtual+Y*80], 80);
        2 : For Y:=0 To 199 Do Move(Mem[Seg(Fondo2^):240*Y+X DIV 4], Mem[$A000:PVirtual+Y*80], 80);
        3 : For Y:=0 To 199 Do Move(Mem[Seg(Fondo3^):240*Y+X DIV 4], Mem[$A000:PVirtual+Y*80], 80);
        {$ENDIF}
      End;
    End;

  Procedure Programacion;
    Var
      Indice    : Word;
    Begin
      For Indice:=0 To NumBitxos-1 Do
        Begin
          If Tiempo=Sincro[Indice].Tiempo Then
            Begin
              Inc(NumBitxo); Bitxos[NumBitxo].Tipo:=Sincro[Indice].Tipo;
              Bitxos[NumBitxo].PosX:=Sincro[Indice].PosX; Bitxos[NumBitxo].PosY:=Sincro[Indice].PosY;
              Bitxos[NumBitxo].Frame:=Random(3)+1;
              Bitxos[NumBitxo].Dir:=Sincro[Indice].Dir;
            End;
        End;
    End;

function DondeDisparas(opx, opy : integer) : boolean;
  var I : word;
  desplx, desply: word;
  color :byte;
  dibujo: word;
  Begin
    { Veamos que hay en la pantalla en las coords (opx, opy) }

    dondedisparas:=FALSE;
    For I := 1 to NumBitxo - 1 Do
      Begin
        If (OpX>=Bitxos[I].PosX) And
           (OpY>=Bitxos[I].PosY) And
           (OpX<=Bitxos[I].PosX+Sprite[Bitxos[I].Tipo].X2-Sprite[Bitxos[I].Tipo].X1) And
           (OpY<=Bitxos[I].PosY+Sprite[Bitxos[I].Tipo].Y2-Sprite[Bitxos[I].Tipo].Y1) Then
             BEGIN        { Has disparado sobre un sprite }



            { Veamos ahora si hay carne o es hueco (color 72) }

            desplx:=opx-Bitxos[I].posx;
            desply:=opy-Bitxos[I].posy;

            desplx:=sprite[Bitxos[I].Tipo].X1+desplx;
            desply:=sprite[Bitxos[I].Tipo].Y1+desply;


    dibujo:=((Bitxos[I].Tipo-1)*4+Bitxos[I].Frame);
    If (dibujo < 17) Or ((dibujo >= 19) And (dibujo <= 24)) Then
    color:=Mem[Seg(Sprites1^):desply*320+desplx]
    else
    color:=Mem[Seg(Sprites2^):desply*320+desplx];

            If color<>72 then
            begin
            {ENHORABUENA, HAS DADO EN CARNE!}
            dondedisparas:=TRUE;

             end;
           END;



      End;
    DrawSprite(23, opx, opy, 0);
  End;

  Begin
    FillChar(Bitxos, SizeOf(Bitxos), 0);
    Bitxo:=0; Tiempo:=0; NumBitxo:=0; X:=0; Plane:=0;
    PVirtual:=16000; SetStart(0); F:=290; S:=1; R:=0;

    gotas[1].x:=100; Gotas[1].Y:=10;
    gotas[2].x:=140; Gotas[1].Y:=140;
    gotas[3].x:=180; Gotas[1].Y:=40;
    gotas[4].x:=010; Gotas[1].Y:=1;
    gotas[2].x:=220; Gotas[1].Y:=70;
    gotas[2].x:=300; Gotas[1].Y:=90;
    haysangre:=0;

    Repeat
      Inc(R);
      If R MOD 5 = 0 Then X:=X+1;
      I:=X MOD 4;
      N:=I;

      For A:=0 To 4-I Do
        Begin
          Draw(A, N); Inc(N);
        End;
      X:=X+4; N:=0;

      For A:=4-I To 3 Do
        Begin
          Draw(A, N); Inc(N);
        End;
      X:=X-4;

      DrawRaton; Programacion;

      If R MOD 3 = 0 Then Inc(s);
      If S = 4 Then S:=1;
      Dec(F, 4);

      For A:=0 to NumBitxo Do
        Begin
          If Bitxos[A].Tipo <> 0 Then
            Begin
              if Bitxos[A].Tipo=2 Then
                begin
                  Num:=Random(3);
                  Dec(Num);
                  Num:=Num*2;
                  Bitxos[A].PosY:=Bitxos[A].PosY-Num;
                  if Bitxos[A].PosY<3 then Bitxos[A].PosY:=1;
                  if Bitxos[A].PosY>135 then Bitxos[A].PosY:=135;
                end;

              K:=Bitxos[a].Frame+s;
              while k >= 4 do k:=k-3;

              DrawSprite((Bitxos[a].tipo-1)*5+K, Bitxos[A].PosX, Bitxos[A].PosY, Bitxos[A].Dir);

              If Bitxos[A].Dir=000 Then Dec(Bitxos[A].Posx);
              If Bitxos[A].Dir=001 Then Inc(Bitxos[A].Posx, 1);
              If Bitxos[A].Posx < -60 Then Bitxos[A].Tipo:=0;
              If Bitxos[A].Posx > 380 Then Bitxos[A].Tipo:=0;
            End;
        End;
      Inc(Tiempo);

{      DrawGotas;}
      If HaySangre=1 Then LaserBerri(opx, opy);

      waitretrace;


      SetStart(PVirtual);
      If PVirtual=16000 Then PVirtual:=0 Else PVirtual:=16000;
      If izq AND dondedisparas(px, py) Then

   {   if haysangre <> 1 then {si ya has disparado en carne, espera un momento a que resbale la sangre}
      Begin



    FillChar(Puntos, SizeOf(Puntos), 0); t:=0; Randomize;
    Quedan:=Numsang;
    For I:=0 To Numsang Do
      Begin
        Puntos[I].Vox:=Random(40); Puntos[I].Vox:=Puntos[I].Vox-20;
        Puntos[I].Voy:=Random(40); Puntos[I].Voy:=Puntos[I].Voy-20;
        Puntos[I].X:=0;
        Puntos[I].Y:=0;
        If Odd(I) Then Puntos[I].Tipo:=1
        Else Puntos[I].Tipo:=0;
        Puntos[I].D:=Random(20)*4+50;
      End;
          opx:=px; opy:=py;
      haysangre:=1;
      end;
      if der then break;
    Until X >= 640;
  End;

Procedure QuitGame;
  Begin
    While KeyPressed Do If ReadKey = #0 Then ;
    FreeMem(Fondo0, 48000);
    {$IFNDEF Debug}
    FreeMem(Fondo1, 48000); FreeMem(Fondo2, 48000); FreeMem(Fondo3, 64000);
    {$Endif}
    FreeMem(Sprites1, 64000);
    FinTemporizacion;
    TextMode(3); WriteLn(LapsoTiempo, '. Agur...');
  End;

Begin

  IniTemporizacion;
  InitGame;
  PlayGame;
  QuitGame;

End.
{
075,3,320,125
100,2,320,002
110,1,320,128
150,4,320,110
185,2,320,060
195,3,320,128
210,1,320,007
220,1,320,134
250,3,320,003
280,1,320,006
300,1,320,127
400,4,320,100

}