Unit Grafx;

INTERFACE

Uses
  Crt;

Type
  TPaleta               = Array[0..255] Of Record
                                             R, G, B    : Byte;
                                           End;
  TPuntero              = Record
                            Ofs, Seg    : Word;
                          End;
Procedure LoadPCX(PCXFile : String; Donde : Pointer; VAR Colores : TPaleta);
Procedure SetPalFading(VAR Colores : TPaleta; Retardo : Byte);
Procedure GetPalFading(Retardo : Byte);
Procedure BlackPalette;
Procedure WaitRetrace;
Procedure Wait;
Procedure InitModeX;

IMPLEMENTATION


Procedure InitModeX;
  Begin
    Asm
      MOV AX, 0013h
      INT 10h                                   { Iniciamos el Modo 13h     }
    End;
    Port[$3C4] := $04;
    Port[$3C5] := Port[$3c5] AND (NOT 8) OR 4;  { Iniciamos el Modo X       }
    Port[$3D4] := $14; Port[$3D5] := Port[$3d5] AND (NOT 64);
    Port[$3D4] := $17; Port[$3D5] := Port[$3d5] OR 64;
    Port[$3C4] := $02; Port[$3C5] := Port[$3c5] AND 15;
    FillChar(Mem[$A000:0000], 64000, 0);        { Limpiamos la pantalla     }
  End;

Procedure Wait;
  Begin
    While KeyPressed Do If ReadKey = #0 Then ;
    Repeat Until KeyPressed;
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

Procedure LoadPCX(PCXFile : String; Donde : Pointer; VAR Colores : TPaleta);
  Var                                         { .Lee un PCX de 320x200 }
    Origen              : File;               { .Optimizado al 50% }
    PCXId               : Word;
    ISize               : LongInt;
    IBufSeg, IBufOfs    : LongInt;
    LogicPos, FlatPos   : LongInt;
    R, G, B, D          : Byte;
    IBuffer             : Pointer;
    Bloque, Fin, Ristra : Boolean;
  Begin
    Assign(Origen, PCXFile); Reset(Origen, 1);
    ISize:=FileSize(Origen)-128-720;
    Fin:=FALSE; Bloque:=FALSE;
    If ISize > 64000 Then Begin ISize:=64000; Bloque:=TRUE; End;
    GetMem(IBuffer, ISize);
    BlockRead(Origen, PCXId, 2);
    Seek(Origen, 128); BlockRead(Origen, IBuffer^, ISize);

    FlatPos:=0; LogicPos:=0;
    IBufSeg:=Seg(IBuffer^);
    IBufOfs:=Ofs(IBuffer^);

    While Fin=FALSE Do
      Begin
        While LogicPos<ISize Do
          Begin
            R:=Mem[IBufSeg:IBufOfs+LogicPos];
            Inc(LogicPos); G:=1; Ristra:=FALSE;
            If R>=192 Then
              Begin
                G:=R AND 63;
                If NOT (LogicPos<ISize) Then Begin Ristra:=TRUE; Break; End;
                R:=Mem[IBufSeg:IBufOfs+LogicPos];
                Inc(LogicPos);
              End;
            FillChar(Mem[TPuntero(Donde).Seg:TPuntero(Donde).Ofs+FlatPos], G, R);
            Inc(FlatPos, G);
          End;
        If Bloque Then
          Begin
            FreeMem(IBuffer, ISize);
            ISize:=(FileSize(Origen)-128-720)-ISize;
            If Ristra Then Seek(Origen, FilePos(Origen)-1);
            GetMem(IBuffer, ISize);
            LogicPos:=0;
            BlockRead(Origen, IBuffer^, ISize);
            Bloque:=FALSE;
          End
        Else
          Fin:=TRUE;
      End;

    FreeMem(IBuffer, ISize);
    Seek(Origen, FileSize(Origen)-768);
    BlockRead(Origen, Mem[Seg(Colores):Ofs(Colores)+00], 768);
    For R:=0 To 255 Do
      Begin
        Colores[R].R:=Colores[R].R SHR 2;
        Colores[R].G:=Colores[R].G SHR 2;
        Colores[R].B:=Colores[R].B SHR 2;
      End;
    Close(Origen);
  End;

Procedure SetPalFading(VAR Colores : TPaleta; Retardo : Byte);
  Var                                         { .Optimizado al 80% }
    R, G, B, Y, X       : Byte;
  Begin
    If Retardo = 0 Then
      Begin
        For Y:=0 To 255 Do
          Begin
            Asm
              mov dx, $3c8
              mov al, y
              out dx, al
              inc dx
              in al, dx; in al, dx;in al, dx
              in al, dx; mov r, al
              in al, dx; mov g, al
              in al, dx; mov b, al
            End;
            R:=Colores[Y].R;
            G:=Colores[Y].G;
            B:=Colores[Y].B;
            Asm
              mov dx, $3c8
              mov al, y
              out dx, al
              inc dx
              mov al, r; out dx, al
              mov al, g; out dx, al
              mov al, b; out dx, al
            End;
          End;
        Exit;
      End;
    For X:=0 To 64 Do
      Begin
        Delay(Retardo);
        For Y:=0 To 255 Do
          Begin
            Asm
              mov dx, $3c8
              mov al, y
              out dx, al
              inc dx
              in al, dx; in al, dx;in al, dx
              in al, dx; mov r, al
              in al, dx; mov g, al
              in al, dx; mov b, al
            End;
            If R < Colores[Y].R Then Inc(R);
            If G < Colores[Y].G Then Inc(G);
            If B < Colores[Y].B Then Inc(B);
            Asm
              mov dx, $3c8
              mov al, y
              out dx, al
              inc dx
              mov al, r; out dx, al
              mov al, g; out dx, al
              mov al, b; out dx, al
            End;
          End;
      End;
  End;

Procedure GetPalFading(Retardo : Byte);
  Var                                         { .Optimizado al 80% }
    R, G, B, Y, X       : Byte;
  Begin
    If Retardo = 0 Then
      Begin
        Asm
          mov dx, $3c8
          mov al, y
          out dx, al
          inc dx
          xor al, al; out dx, al
          out dx, al; out dx, al
        End;
        Exit;
      End;
    For X:=0 To 64 Do
      Begin
        Delay(Retardo);
        For Y:=0 To 255 Do
          Begin
            Asm
              mov dx, $3c8
              mov al, y
              out dx, al
              inc dx
              in al, dx; in al, dx;in al, dx
              in al, dx; mov r, al
              in al, dx; mov g, al
              in al, dx; mov b, al
            End;
            If R > 0 Then Dec(R);
            If G > 0 Then Dec(G);
            If B > 0 Then Dec(B);
            Asm
              mov dx, $3c8
              mov al, y
              out dx, al
              inc dx
              mov al, r; out dx, al
              mov al, g; out dx, al
              mov al, b; out dx, al
            End;
          End;
      End;
  End;

Procedure BlackPalette;
  Var
    Y, R, G, B                  : Byte;
  Begin
    For Y:=0 To 255 Do
      Begin
        Asm
          mov dx, $3c8
          mov al, y
          out dx, al
          inc dx
          xor al, al;
          out dx, al
          out dx, al
          out dx, al
        End;
      End;
  End;

End.