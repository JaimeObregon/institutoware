{Mejorar el sistema de puntuaci¢n y el tipo de letra ... }
{$M 65520,0,65530}
{$UNDEF DEBUG}
Program Tetris;

Uses
  Dos, Crt;

{$L TETRIS.SCD}
{$F+}
Procedure ModVolume(V1, V2, V3, V4: Integer); External;
Procedure ModDevice(Var Device: Integer); External;
Procedure ModSetup(Var Status: Integer; Device, MixSpeed, Pro, Loop : Integer; Var Str: String); External;
Procedure ModStop; External;
Procedure ModInit; External;
{$F-}

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

Procedure ModPlay(Str: String);
  Var
    Dev, Mix, Stat, Pro, Loop: Integer;
  Begin
    ModInit;
    Mix := 10000; Dev := 7; Pro := 10; Loop := 4;
    ModVolume(255, 255, 255, 255);
    ModSetup(Stat, Dev, Mix, Pro, Loop, Str);
  End;

Procedure GetColor(C : Byte; Var R, G, B :  Byte);
  Begin
    Port[$3C8] := C; R := Port[$3C9]; G := Port[$3C9]; B := Port[$3C9];
    Port[$3C8] := C; R := Port[$3C9]; G := Port[$3C9]; B := Port[$3C9];
  End;

Procedure SetColor(Col, R, G, B : Byte); Assembler;
  Asm
    MOV    DX, 3C8H
    MOV    Al, [Col]
    OUT    DX, AL
    INC    DX
    MOV    Al, [R]
    OUT    DX, AL
    MOV    Al, [G]
    OUT    DX, AL
    MOV    Al, [B]
    OUT    DX, AL
  End;

Procedure WaitRetrace; Assembler;
  Asm
    MOV       DX, 3DAh
    @WAIT1:
    IN        AL, DX
    TEST      AL, 08H
    JNZ       @WAIT1
    @WAIT2:
    IN        AL, DX
    TEST      AL, 08h
    JZ        @WAIT2
  End;

Type
  TPieza                = Array[0..3] Of Array[0..3] Of ShortInt;
  Numero                = Array[0..2] Of String[3];

Const
  Esc = #27;
  Arr = #72;
  Aba = #80;
  Izq = #75;
  Der = #77;
  Ent = #13;
  Ins = '0';
  CX                    : Integer = 82;
  CY                    : Integer = 19;
  Piezas                : Array[0..6] Of Array[0..3] Of TPieza =
  (
  (((0,1,0,0), (1,1,1,0), (0,0,0,0), (0,0,0,0)),
   ((1,0,0,0), (1,1,0,0), (1,0,0,0), (0,0,0,0)),
   ((1,1,1,0), (0,1,0,0), (0,0,0,0), (0,0,0,0)),
   ((0,1,0,0), (1,1,0,0), (0,1,0,0), (0,0,0,0))),
  (((1,0,0,0), (1,0,0,0), (1,0,0,0), (1,0,0,0)),
   ((1,1,1,1), (0,0,0,0), (0,0,0,0), (0,0,0,0)),
   ((1,0,0,0), (1,0,0,0), (1,0,0,0), (1,0,0,0)),
   ((1,1,1,1), (0,0,0,0), (0,0,0,0), (0,0,0,0))),
  (((1,1,0,0), (1,0,0,0), (1,0,0,0), (0,0,0,0)),
   ((1,1,1,0), (0,0,1,0), (0,0,0,0), (0,0,0,0)),
   ((0,1,0,0), (0,1,0,0), (1,1,0,0), (0,0,0,0)),
   ((1,0,0,0), (1,1,1,0), (0,0,0,0), (0,0,0,0))),
  (((1,1,0,0), (0,1,0,0), (0,1,0,0), (0,0,0,0)),
   ((0,0,1,0), (1,1,1,0), (0,0,0,0), (0,0,0,0)),
   ((1,0,0,0), (1,0,0,0), (1,1,0,0), (0,0,0,0)),
   ((1,1,1,0), (1,0,0,0), (0,0,0,0), (0,0,0,0))),
  (((1,1,0,0), (1,1,0,0), (0,0,0,0), (0,0,0,0)),
   ((1,1,0,0), (1,1,0,0), (0,0,0,0), (0,0,0,0)),
   ((1,1,0,0), (1,1,0,0), (0,0,0,0), (0,0,0,0)),
   ((1,1,0,0), (1,1,0,0), (0,0,0,0), (0,0,0,0))),
  (((1,1,0,0), (0,1,1,0), (0,0,0,0), (0,0,0,0)),
   ((0,1,0,0), (1,1,0,0), (1,0,0,0), (0,0,0,0)),
   ((1,1,0,0), (0,1,1,0), (0,0,0,0), (0,0,0,0)),
   ((0,1,0,0), (1,1,0,0), (1,0,0,0), (0,0,0,0))),
  (((0,1,1,0), (1,1,0,0), (0,0,0,0), (0,0,0,0)),
   ((1,0,0,0), (1,1,0,0), (0,1,0,0), (0,0,0,0)),
   ((0,1,1,0), (1,1,0,0), (0,0,0,0), (0,0,0,0)),
   ((1,0,0,0), (1,1,0,0), (0,1,0,0), (0,0,0,0)))
  );

Var
  Mapa                          : Array[0..7] Of Array[0..19] Of ShortInt;
  Lineas, Puntos                : Word;
  SPieza                        : ShortInt;
  Bloque                        : Array[0..6] Of Array[0..7] Of Array[0..9] Of Byte;
  Numeros                       : Pointer;
  Nivel                         : Byte;
  Letras                        : Pointer;
  Paleta                        : Array[0..255] Of Array[0..2] Of Byte;

Procedure WriteTxt(A, B : Word; T : String);
  Var
    Z, X, Y, L, C       : Word;
  Begin
    C:=0;
    For Z:=1 To Length(T) Do
      Begin
        For Y:=0 To 4 Do
          Begin
            For X:=0 To 3 Do
              Begin
                L:=0;
                Case T[Z] Of
                  'A'..'Z' : L:=Ord(T[Z])-65;
                  '0'..'9' : L:=Ord(T[Z])-22;
                  ' '      : Break;
                  #44..#46 : L:=Ord(T[Z])-44+36;
                End;
                Mem[$A000:(B+Y)*320+C+X+A]:=Mem[Seg(Letras^):Ofs(Letras^)+(Y*160)+X+L*4];
              End;
          End;
        Inc(C, 4);
      End;
  End;

Function Cadena(Numero : LongInt) : String;
  Var
    C                           : String;
  Begin
    Str(Numero, C);
    Cadena:=C;
  End;

Procedure ShowScores;
  Type
    TScore                      = Record
                                    Nombre      : String;
                                    Puntos      : Word;
                                  End;
  Var
    Origen                      : File;
    X, Y, Z                     : Word;
    R, G, B                     : Byte;
    Scores                      : Array[0..9] Of TScore;
    Texto                       : Text;
    Tecla                       : Char;
    Nombre                      : String;
  Begin
    For X:=0 To 63 Do
      Begin
        For Y:=0 To 255 Do
          Begin
            GetColor(Y, R, G, B);
            If R>1 Then Dec(R);
            If G>1 Then Dec(G);
            If B>1 Then Dec(B);
            SetColor(Y, R, G, B);
          End;
      End;
    Delay(50);
    Assign(Texto, 'SCORES.DAT'); Reset(Texto);
    For Y:=0 To 9 Do
      Begin
        ReadLn(Texto, Scores[Y].Nombre);
        ReadLn(Texto, Scores[Y].Puntos);
      End;
    Close(Texto);
    Assign(Origen, 'SCORES.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Mem[$A000:0000], 64000);
    Seek(Origen, FileSize(Origen)-768);
    For Y:=0 To 255 Do
      SetColor(Y, 0, 0, 0);
    For Y:=0 To 255 Do
      Begin
        BlockRead(Origen, Paleta[Y][0], 1);
        BlockRead(Origen, Paleta[Y][1], 1);
        BlockRead(Origen, Paleta[Y][2], 1);
      End;
    For Y:=0 To 9 Do
      Begin
        WriteTXT(30, Y*10+51, Cadena(Y+1)+'.-');
        WriteTXT(50, Y*10+51, Scores[Y].Nombre);
        WriteTXT(280-Length(Cadena(Scores[Y].Puntos))*4, Y*10+51, Cadena(Scores[Y].Puntos));
      End;
    For X:=0 To 63 Do
      Begin
        For Y:=0 To 255 Do
          Begin
            GetColor(Y, R, G, B);
            If R<Paleta[Y][0] Then Inc(R);
            If G<Paleta[Y][1] Then Inc(G);
            If B<Paleta[Y][2] Then Inc(B);
            SetColor(Y, R, G, B);
          End;
      End;
    Delay(50);
    Close(Origen);
    For Y:=0 To 9 Do
      Begin
        If Puntos >= Scores[Y].Puntos Then
          Break;
      End;
    If Puntos >= Scores[9].Puntos Then
      Begin
        For Z:=0 To 9 Do
          For X:=0 To 4 Do
            FillChar(Mem[$A000:(Z*10+51+X)*320+50], 245, 0);
        For X:=9 DownTo Y Do
          Begin
            If X>=1 Then
              Begin
                Scores[X].Puntos:=Scores[X-1].Puntos;
                Scores[X].Nombre:=Scores[X-1].Nombre;
              End;
          End;

        X:=Y;
        WriteTXT(20, 160, 'NUEVO RECORD.');
        For Y:=0 To 9 Do
          Begin
            WriteTXT(30, Y*10+51, Cadena(Y+1)+'.-');
            WriteTXT(50, Y*10+51, Scores[Y].Nombre);
            WriteTXT(280-Length(Cadena(Scores[Y].Puntos))*4, Y*10+51, Cadena(Scores[Y].Puntos));
          End;
        Y:=X;
        For Z:=0 To 9 Do
          For X:=0 To 4 Do
            FillChar(Mem[$A000:(Y*10+51+X)*320+50], 245, 0);
        WriteTXT(280-Length(Cadena(Puntos))*4, Y*10+51, Cadena(Puntos));
        Nombre:='';
        While KeyPressed Do If ReadKey=#0 Then ;
        Repeat
          Tecla:=UpCase(ReadKey);
          Case Tecla Of
            'A'..'Z', '0'..'9',
            ',', '.', '-', ' ' : Begin
                                   If Length(Nombre)<20 Then
                                     Nombre:=Nombre+Tecla;
                                   WriteTXT(50, Y*10+51, Nombre);
                                 End;

            #8: Begin
                  X:=Y;
                  For Y:=0 To 5 Do
                    FillChar(Mem[$A000:(Y+X*10+51)*320+50], Length(Nombre)*4, 0);
                  Y:=X;
                  If Length(Nombre)>0 Then Delete(Nombre, Length(Nombre), 1);
                  WriteTXT(50, Y*10+51, Nombre);
                End;
          End;
        Until Tecla=Ent;
        Scores[Y].Nombre:=Nombre;
        Scores[Y].Puntos:=Puntos;
        Assign(Texto, 'SCORES.DAT'); ReWrite(Texto);
        X:=Y;
        For Y:=0 To 9 Do
          Begin
            WriteLn(Texto, Scores[Y].Nombre);
            WriteLn(Texto, Scores[Y].Puntos);
          End;
        Close(Texto);
        Y:=X;
        For X:=0 To 4 Do
          Begin
            FillChar(Mem[$A000:(Y*10+51+X)*320+50], 245, 0);
            WriteTXT(50, Y*10+51, Scores[Y].Nombre);
            WriteTXT(280-Length(Cadena(Scores[Y].Puntos))*4, Y*10+51, Cadena(Scores[Y].Puntos));
          End;
      End;
    WriteTXT(154, 180, 'PULSE CUALQUIER TECLA PARA CONTINUAR');
    While KeyPressed Do If ReadKey=#0 Then ;
    Repeat Until KeyPressed;
  End;

Procedure WriteNum(A, B : Word; T : String);
  Var
    X, Y, Z                     : Word;
  Begin
    For Z:=1 To Length(T) Do
      For Y:=0 To 7 Do
        Move(Mem[Seg(Numeros^):Ofs(Numeros^)+Y*100+(Ord(T[Z])-48)*10], Mem[$A000:(Y+B)*320+A+Z*10], 10);
  End;

Procedure IniProg;
  Var
    X, Y, Z                     : Word;
    R, G, B                     : Byte;
    Origen                      : File;
    Nombre                      : String;
    Texto                       : Text;
  Begin
    GetMem(Numeros, 800);
    GetMem(Letras, 40*20);
    Asm
      MOV       AL, 13h
      INT       10h
    End;
    For Y:=CY To CY+160 Do
      FillChar(Mem[$A000:Y*320+CX], 80, 0);
    Assign(Origen, 'TETRIS.DAT'); Reset(Origen, 1);
    Seek(Origen, 4);
    For Y:=0 To 7 Do
      Begin
        For Z:=0 To 6 Do
          Begin
            For X:=0 To 9 Do
              BlockRead(Origen, Bloque[Z][Y][X], 1);
            Seek(Origen, FilePos(Origen)+1);
          End;
        Seek(Origen, FilePos(Origen)+320-11*7);
      End;
    Seek(Origen, FileSize(Origen)-768);
    For Y:=0 To 255 Do SetColor(Y, 0, 0, 0);
    For Y:=0 To 255 Do
      Begin
        BlockRead(Origen, Paleta[Y][0], 1);
        BlockRead(Origen, Paleta[Y][1], 1);
        BlockRead(Origen, Paleta[Y][2], 1);
      End;
    Seek(Origen, 170+17*320);
    For Y:=0 To 7 Do
      Begin
        BlockRead(Origen, Mem[Seg(Numeros^):Ofs(Numeros^)+Y*100], 100);
        Seek(Origen, FilePos(Origen)+220);
      End;
    Seek(Origen, 84+11*320);
    For Y:=0 To 4 Do
      Begin
        BlockRead(Origen, Mem[Seg(Letras^):Ofs(Letras^)+Y*40*4], 40*4);
        Seek(Origen, FilePos(Origen)+320-40*4);
      End;
    Close(Origen);
    Assign(Origen, 'TETRIS.VGA'); Reset(Origen, 1); Seek(Origen, 4);
    BlockRead(Origen, Mem[$A000:0000], 64000);
    Close(Origen);
    {$IFDEF DEBUG}
    {$ELSE}
    ModPlay('TETRIS.MSK');
    {$ENDIF}
    Lineas:=0; Puntos:=0; Nivel:=1;
    Randomize;
    FillChar(Mapa, SizeOf(Mapa), 0);
    SPieza:=Random(7);
    WriteTxt(166, 170, 'CUTRIS VERSION 1.0. ');
    WriteTxt(166, 176, 'COPYRIGHT, SOFTWARE INUTIL, S.A.');
    For X:=0 To 63 Do
      Begin
        For Y:=0 To 255 Do
          Begin
            GetColor(Y, R, G, B);
            If R<Paleta[Y][0] Then Inc(R);
            If G<Paleta[Y][1] Then Inc(G);
            If B<Paleta[Y][2] Then Inc(B);
            SetColor(Y, R, G, B);
          End;
      End;
    Assign(Texto, 'SCORES.DAT'); Reset(Texto);
    WriteTXT(166, 20, 'LOS TRES MEJORES');
    ReadLn(Texto, Nombre); WriteTXT(171, 26, '1.- '+Nombre);
    ReadLn(Texto, Nombre); WriteTXT(280, 26, Nombre);
    ReadLn(Texto, Nombre); WriteTXT(171, 32, '2.- '+Nombre);
    ReadLn(Texto, Nombre); WriteTXT(280, 32, Nombre);
    ReadLn(Texto, Nombre); WriteTXT(171, 38, '3.- '+Nombre);
    ReadLn(Texto, Nombre); WriteTXT(280, 38, Nombre);
    Close(Texto);
    WriteTXT(175, 40+20, '  TECLAS');
    WriteTXT(171, 50+20, '  CURSORES     - ROTAR O BAJAR');
    WriteTXT(171, 56+20, '0 O INSERTAR   - SOLTAR');
    WriteTXT(171, 62+20, '               - PAUSA');
    WriteTXT(173, 62+20, '   ENTER');
  End;

Procedure EndProg;
  Var
    X, Y, R, G, B               : Byte;
    Origen                      : File;
    Paleta                      : Array[0..255] Of Array[1..3] Of Byte;
  Begin
    FreeMem(Numeros, 800);
    FreeMem(Letras, 40*20);
    For X:=0 To 63 Do
      Begin
        For Y:=0 To 255 Do
          Begin
            GetColor(Y, R, G, B);
            If R>1 Then Dec(R);
            If G>1 Then Dec(G);
            If B>1 Then Dec(B);
            SetColor(Y, R, G, B);
          End;
      End;
    Assign(Origen, 'TETRIS.SID'); Reset(Origen, 1); Seek(Origen, 4);
    For X:=0 To 255 Do SetColor(X, 0, 0, 0);
    BlockRead(Origen, Mem[$a000:0], 320*200);
    BlockRead(Origen, X, 1); BlockRead(Origen, X, 1);
    For X:=0 To 255 Do
      Begin
        BlockRead(Origen, Paleta[X][1], 1);
        BlockRead(Origen, Paleta[X][2], 1);
        BlockRead(Origen, Paleta[X][3], 1);
      End;
    Close(Origen);
    For Y:=0 To 63 Do
      For X:=0 To 255 Do
        Begin
          GetColor(X, R, G, B);
          If Paleta[X][1]>R Then Inc(R);
          If Paleta[X][2]>G Then Inc(G);
          If Paleta[X][3]>B Then Inc(B);
          SetColor(X, R, G, B);
        End;
    While KeyPressed Do If ReadKey=#0 Then ;
    Repeat Until KeyPressed;
    For Y:=0 To 63 Do
      For X:=0 To 255 Do
        Begin
          GetColor(X, R, G, B);
          If 1<R Then Dec(R);
          If 1<G Then Dec(G);
          If 1<B Then Dec(B);
          SetColor(X, R, G, B);
        End;

    Delay(50);
    {$IFDEF DEBUG}
    {$ELSE}
    ModStop;
    {$ENDIF}
    TextMode(3);
    WriteLn('CUTRIS (CUtre-teTRIS). (C), 1997, SOFTWARE INUTIL, S.A.');
    WriteLn('PROGRAMADO POR JAIME GOMEZ OBREGON. SOFTWARE INUTIL LE DESEA UN BUEN DIA.');
    WriteLn('LINEAS:  ', Lineas, '.   PUNTOS:  ', Puntos, '.   NIVEL:  ', Nivel, '.');
    WriteLn;
    Halt;
  End;

Procedure DBloque(X, Y, C : Word);
  Var
    B, A                : Byte;
  Begin
    Y:=Y+CY; X:=X+CX; Dec(C);
    For B:=0 To 7 Do
      For A:=0 To 9 Do
        Mem[$A000:(Y+B)*320+X+A]:=Bloque[C][B][A];
  End;

Procedure DFondo(X, Y : Word);
  Var
    B, A                : Byte;
  Begin
    X:=X+CX; Y:=Y+CY;
    For B:=0 To 7 Do
      FillChar(Mem[$A000:(Y+B)*320+X], 10, 0);
  End;

Procedure DPieza(C, D, P, A : Integer);
  Var
    X, Y                : Integer;
  Begin
    For Y:=0 To 3 Do
      For X:=0 To 3 Do
        If Piezas[P][A][Y][X]<>0 Then DBloque(X*10+C, Y*8+D, P+1);
  End;

Procedure DrawMapa;
  Var
    X, Y                : Word;
    Altura              : Word;
    Alt                 : Boolean;
  Begin
    Altura:=0;
    For Y:=19 DownTo 0 Do
      Begin
        Alt:=FALSE;
        For X:=0 To 7 Do
          If Mapa[X][Y]<>0 Then Alt:=TRUE;
        If NOT Alt Then
          Begin
            Altura:=Y+1;
            Break;
          End;
      End;
    For Y:=Altura*8 To 160 Do
      FillChar(Mem[$A000:(Y+CY)*320+CX], 80, 0);
    For Y:=0 To 19 Do
      For X:=0 To 7 Do
        If Mapa[X][Y]<>0 Then
           DBloque(X*10, Y*8, Mapa[X][Y]);
  End;

Procedure RunProg;
  Var
    Tecla               : Char;
    Pieza, PosX, PosY   : ShortInt;
    Angulo              : ShortInt;
    Obstaculo           : Boolean;
    Nueva               : Boolean;
    Counter             : LongInt;

  Procedure EndGame;
    Begin
      ShowScores;
      EndProg;
    End;

  Procedure Graba;
    Var
      B, A            : ShortInt;
    Begin
      Nueva:=TRUE;
      { Grabamos la Pieza en el Mapa }
      For B:=0 To 3 Do
        For A:=0 To 3 Do
          If Piezas[Pieza][Angulo][B][A]<>0 Then Mapa[PosX+A][PosY+B]:=Pieza+1;
      End;

  Function BajaPieza : Boolean;
    Var
      A, B, C, D        : ShortInt;
    Begin
      { Obtenemos el Ancho y el Alto de la Pieza }
      BajaPieza:=FALSE;
      C:=0; D:=0;
      For B:=0 To 3 Do
        For A:=0 To 3 Do
          Begin
            If (Piezas[Pieza][Angulo][B][A]<>0) And (D<B) Then D:=B;
            If (Piezas[Pieza][Angulo][B][A]<>0) And (C<A) Then C:=A;
          End;
      If PosY>=19-D Then
        Begin
          Graba;
          DrawMapa;
          PosY:=0;
          Exit;
        End;
      Obstaculo:=FALSE;
      For B:=0 To 3 Do
        For A:=0 To 3 Do
          Begin
            If (Piezas[Pieza][Angulo][B][A]<>0) And (Mapa[A+PosX][B+PosY+1]<>0) Then
              Obstaculo:=TRUE;
          End;
      Nueva:=FALSE; BajaPieza:=FALSE;
      If (NOT Obstaculo) And (PosY<=18-D) Then BajaPieza:=TRUE Else
        Begin
          Graba;
          DrawMapa;
          PosY:=0;
        End;
    End;

  Function MuevePieza(PX : ShortInt) : Boolean;
    Var
      A, B, C, D        : ShortInt;
    Begin
      MuevePieza:=FALSE;
      { Obtenemos el Ancho y el Alto de la Pieza }
      C:=0; D:=0;
      For B:=0 To 3 Do
        For A:=0 To 3 Do
          Begin
            If (Piezas[Pieza][Angulo][B][A]<>0) And (D<B) Then D:=B;
            If (Piezas[Pieza][Angulo][B][A]<>0) And (C<A) Then C:=A;
          End;
      If PX=-1 Then Exit;
      If PX=8-C Then Exit;
      Inc(C); Inc(D);

      Obstaculo:=FALSE;
      For B:=0 To D-1 Do
        For A:=0 To C-1 Do
          If (Piezas[Pieza][Angulo][B][A]<>0) And (Mapa[A+PX][B+PosY]<>0) Then
            Obstaculo:=TRUE;
      Nueva:=FALSE; MuevePieza:=FALSE;
      If (NOT Obstaculo) And (PX<=7) And (PX>=0) Then MuevePieza:=TRUE Else
        Exit;
    End;

  Function Rotar(Ang : ShortInt) : Boolean;
    Var
      A, B, C, D        : ShortInt;
      Obstaculo         : Boolean;
      OldPosX           : ShortInt;
    Begin
      Rotar:=FALSE;
      C:=0; D:=0;
      For B:=0 To 3 Do
        For A:=0 To 3 Do
          Begin
            If (Piezas[Pieza][Ang][B][A]<>0) And (D<B) Then D:=B;
            If (Piezas[Pieza][Ang][B][A]<>0) And (C<A) Then C:=A;
          End;
      Inc(C); Inc(D);
      If PosY+D>20 Then
        Begin
          Rotar:=FALSE;
          Exit;
        End;
      OldPosX:=PosX;
      If PosX+C > 8 Then Dec(PosX, PosX+C-8);

      For C:=0 To 0 Do
        Begin
          Obstaculo:=FALSE;
          For B:=0 To 3 Do
            For A:=0 To 3 Do
              Begin
                If A+PosX >= 0 Then
                  If (Piezas[Pieza][Ang][B][A]<>0) And (Mapa[A+PosX][B+PosY]<>0) Then
                    Obstaculo:=TRUE
              End;
          If NOT Obstaculo Then Break;
        End;
      If Obstaculo Then
        Begin
          PosX:=OldPosX;
          Exit;
        End;
      Dec(PosX, C);
      Angulo:=Ang;
    End;

  Function CheckLines : Boolean;
    Var
      X, Y              : ShortInt;
      Z                 : Word;
      Linea             : ShortInt;
    Begin
      CheckLines:=FALSE;
      For Y:=0 To 19 Do
        Begin
          Linea:=0;
          For X:=0 To 7 Do
            If Mapa[X][Y]=0 Then Linea:=127;
          If Linea<>127 Then Break;
        End;
      If Linea=127 Then Exit;
      Linea:=Y;
      CheckLines:=TRUE;
      For X:=0 To 7 Do
        Mapa[X][Linea]:=0;
      For X:=0 To 7 Do
        Begin
          For Y:=Linea DownTo 1 Do
            Mapa[X][Y]:=Mapa[X][Y-1]
        End;
      Inc(Lineas);
      IF NOT CheckLines Then
        Begin
          For Z:=0 To 160 Do
            FillChar(Mem[$A000:(Z+CY)*320+CX], 80, 0);
          SetColor(0, 63, 63, 63);
          WaitRetrace;
          DrawMapa;
          WaitRetrace;
          SetColor(0, 00, 00, 00);
        End;
    End;

  Function LineasMax : Boolean;
    Var
      X                 : ShortInt;
    Begin
      LineasMax:=FALSE;
      For X:=0 To 7 Do
        If Mapa[X][0]<>0 Then LineasMax:=TRUE;
    End;

  Procedure PNueva;
    Var
      X, Y, B, A, L             : Word;
    Begin
      { Antes de poner una nueva Pieza comprobamos si ha hecho linea(s) o
        si se ha acabado el juego }
      L:=0;
      Repeat
        Inc(L);
      Until CheckLines=FALSE;
      Dec(L);
      Inc(Puntos, L*L*8);

      If LineasMax Then EndGame;
      PosX:=4; PosY:=0;
      Pieza:=SPieza;
      SPieza:=Random(7); Angulo:=0;

      For B:=0 To 3 Do
        For A:=0 To 3 Do
          If Piezas[Pieza][Angulo][B][A]<>0 Then Inc(Puntos);
      WriteNum(63-(Length(Cadena(Lineas))*10), 27, Cadena(Lineas));
      WriteNum(63-(Length(Cadena(Puntos))*10), 59, Cadena(Puntos));
      If Puntos >= Nivel*400 Then
        Begin
          SetColor(0, 63, 63, 0);
          Inc(Nivel);
          WaitRetrace; WaitRetrace; WaitRetrace;
          SetColor(0, 0, 0, 0);
        End;
      WriteNum(63-(Length(Cadena(Nivel))*10), 91, Cadena(Nivel));

      For Y:=146 To 146+8*4 Do
        FillChar(Mem[$A000:Y*320+33], 30, 0);
      For Y:=0 To 3 Do
        For X:=0 To 3 Do
          If Piezas[SPieza][Angulo][Y][X]<>0 Then
            For B:=0 To 7 Do
              For A:=0 To 9 Do
                Mem[$A000:(Y*8+B+146)*320+X*10+A+33]:=Bloque[SPieza][B][A];
      Nueva:=FALSE;
    End;

  Procedure QuitaPieza(P, Z : Byte);
    Var
      A, B              : Integer;
    Begin
      For A:=0 To 3 Do
        For B:=0 To 3 Do
          Begin
            If Piezas[P][Z][A][B]<>0 Then
            DFondo((B+PosX)*10, (A+PosY)*8);
          End;
    End;

  Procedure Block(X, Y, C : Word);
    Var
      A, B              : Word;
    Begin
      For B:=0 To 7 Do
        For A:=0 To 9 Do
          Mem[$A000:(Y+B)*320+X+A]:=Bloque[C][B][A];
    End;

  Var
    A, C, X, Y          : Word;
    Z                   : LongInt;
    Origen              : File;
    R, G, B             : Byte;
    Paleta              : Array[0..255] Of Array[0..2] Of Byte;

  Begin
    Nueva:=TRUE;
    C:=0; Z:=99999;
    Repeat
      If Nueva Then PNueva;
      If BajaPieza Then Inc(PosY);
      If Nueva Then PNueva;
      DPieza(PosX*10, PosY*8, Pieza, Angulo);
      Counter:=MemL[$0040:$006C]+9-Nivel;
      Repeat
        If KeyPressed Then
          Begin
            Tecla:=ReadKey;
            Case Tecla Of
              #13: Begin
                     While KeyPressed Do If ReadKey=#0 Then ;
                     Assign(Origen, 'PAUSA.VGA'); Reset(Origen, 1);
                     Seek(Origen, FileSize(Origen)-768);

                     For Y:=0 To 255 Do
                       Begin
                         BlockRead(Origen, Paleta[Y][0], 1);
                         BlockRead(Origen, Paleta[Y][1], 1);
                         BlockRead(Origen, Paleta[Y][2], 1);
                         If Y>=48 Then SetColor(Y, 0, 0, 0);
                       End;
                     Seek(Origen, 4);
                     For Y:=0 To 170 Do
                       Begin
                         BlockRead(Origen, Mem[$A000:(Y+15)*320+77], 88);
                       End;
                     For X:=0 To 63 Do
                       Begin
                         For Y:=48 To 255 Do
                           Begin
                             GetColor(Y, R, G, B);
                             If R<Paleta[Y][0] Then Inc(R);
                             If G<Paleta[Y][1] Then Inc(G);
                             If B<Paleta[Y][2] Then Inc(B);
                             SetColor(Y, R, G, B);
                           End;
                           While KeyPressed Do If ReadKey=#0 Then ;
{                         WaitRetrace;  }
                         Delay(1);

                       End;

                     For Y:=0 To 255 Do
                       Begin
                         GetColor(Y, R, G, B);
                         Paleta[Y][0]:=R;
                         Paleta[Y][1]:=G;
                         Paleta[Y][2]:=B;
                       End;
                     For X:=0 To 16 Do
                       Begin
                         For Y:=0 To 47 Do
                           Begin
                             GetColor(Y, R, G, B);
                             If R>0 Then Dec(R);
                             If G>0 Then Dec(G);
                             If B>0 Then Dec(B);
                             SetColor(Y, R, G, B);
                           End;
                         WaitRetrace;
                         While KeyPressed Do If ReadKey=#0 Then ;
                       End;
                     Repeat Until KeyPressed;
                     While KeyPressed Do If ReadKey=#0 Then ;
                     For X:=0 To 63 Do
                       Begin
                         For Y:=48 To 255 Do
                           Begin
                             GetColor(Y, R, G, B);
                             If R>0 Then Dec(R);
                             If G>0 Then Dec(G);
                             If B>0 Then Dec(B);
                             SetColor(Y, R, G, B);
                           End;
{                         WaitRetrace;}
                         Delay(1);
                         While KeyPressed Do If ReadKey=#0 Then ;
                       End;

                     For Y:=19 To 179 Do
                       For X:=82 To 161 Do
                         Mem[$A000:Y*320+X]:=0;
                     For X:=0 To 19 Do
                       For Y:=0 To 7 Do
                         Begin
                           If Mapa[Y][X]<>0 then
                           Block(Y*10+82, X*8+19, Mapa[Y][X]-1);
                         End;
                     DPieza(PosX*10, PosY*8, Pieza, Angulo);
                     For X:=0 To 16 Do
                       Begin
                         For Y:=0 To 47 Do
                           Begin
                             GetColor(Y, R, G, B);
                             If R<Paleta[Y][0] Then Inc(R);
                             If G<Paleta[Y][1] Then Inc(G);
                             If B<Paleta[Y][2] Then Inc(B);
                             SetColor(Y, R, G, B);
                           End;
                         WaitRetrace;
                         While KeyPressed Do If ReadKey=#0 Then ;
                       End;
                     Close(Origen);
                   End;
              Arr: Begin
                     QuitaPieza(Pieza, Angulo);
                     If Angulo=0 Then Rotar(3)
                     Else Rotar(Angulo-1);
                     DPieza(PosX*10, PosY*8, Pieza, Angulo);
                   End;
              Aba: Begin
                     QuitaPieza(Pieza, Angulo);
                     If BajaPieza Then Inc(PosY);
                     If Nueva Then PNueva;
                     DPieza(PosX*10, PosY*8, Pieza, Angulo);
                   End;
              Der: Begin
                     QuitaPieza(Pieza, Angulo);
                     If MuevePieza(PosX+1) Then Inc(PosX);
                     DPieza(PosX*10, PosY*8, Pieza, Angulo);
                   End;
              Izq: Begin
                     QuitaPieza(Pieza, Angulo);
                     If MuevePieza(PosX-1) Then Dec(PosX);
                     DPieza(PosX*10, PosY*8, Pieza, Angulo);
                   End;
              Ins: Begin
                     Repeat
                       QuitaPieza(Pieza, Angulo);
                       If BajaPieza Then Inc(PosY);
                       If Nueva Then PNueva;
                       DPieza(PosX*10, PosY*8, Pieza, Angulo);
                       WaitRetrace;
                       While KeyPressed Do If ReadKey=#0 Then ;
                     Until NOT BajaPieza Or LineasMax;
                     Break;
                   End;
            End;
        End
      Else
        Tecla:=#0;
      Inc(Z);
      If Z = 100000 Then
        Begin
          For A:=0 To 28 Do
            Begin
              Block(A*11, 0, (A+C) MOD 7);
              Block(A*11, 189, (A+C) MOD 7);
            End;
          For A:=0 To 20 Do
            Begin
              Block(0, A*9, (A+C) MOD 7);
              Block(308, A*9, (A+C) MOD 7);
            End;
          Inc(C);
          If C=7 Then C:=0;
          Z:=0;
        End;
      Until (MemL[$0040:$006C]>=Counter) Or (Tecla=Esc);
      QuitaPieza(Pieza, Angulo);
    Until Tecla=Esc;
  End;

Procedure LoadScr;
  Var
    Origen                      : File;
    X, R, G, B, Y               : Byte;
    Paleta                      : Array[0..255] Of Array[1..3] Of Byte;

  Begin
    Asm
      MOV AX, 13h
      INT 10h
    End;
    Assign(Origen, 'TETRIS.INT'); Reset(Origen, 1); Seek(Origen, 4);
    For X:=0 To 255 Do SetColor(X, 0, 0, 0);
    BlockRead(Origen, Mem[$a000:0], 320*200);
    BlockRead(Origen, X, 1); BlockRead(Origen, X, 1);
    For X:=0 To 255 Do
      Begin
        BlockRead(Origen, Paleta[X][1], 1);
        BlockRead(Origen, Paleta[X][2], 1);
        BlockRead(Origen, Paleta[X][3], 1);
      End;
    Close(Origen);
    For Y:=0 To 63 Do
      For X:=0 To 255 Do
        Begin
          GetColor(X, R, G, B);
          If Paleta[X][1]>R Then Inc(R);
          If Paleta[X][2]>G Then Inc(G);
          If Paleta[X][3]>B Then Inc(B);
          SetColor(X, R, G, B);
        End;
    Repeat Until KeyPressed;
    For Y:=0 To 63 Do
      For X:=0 To 255 Do
        Begin
          GetColor(X, R, G, B);
          If 1<R Then Dec(R);
          If 1<G Then Dec(G);
          If 1<B Then Dec(B);
          SetColor(X, R, G, B);
        End;
    While KeyPressed Do If ReadKey=#0 Then ;
  End;

  var a: word;
Begin

  {$IFDEF DEBUG}
  {$ELSE}
  LoadScr;
  {$ENDIF}
  IniProg;

  RunProg;
  EndProg;

End.