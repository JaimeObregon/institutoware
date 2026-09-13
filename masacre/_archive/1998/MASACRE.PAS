{$G+}
Program Masacre;

Uses
  Dos, Crt, Grafx, VocPlay;

Const
  Pitch                 = 1;
  Max                   = 100;
  e =7 ;


Var
  Ch            : Char;
  NOP           : Boolean;
  Origen                : File;
  Sprites1, Sprites2    : Pointer;
  Fondo                 : Pointer;
  R, X, Y               : LongInt;
  Linea                 : Array[0..319] Of LongInt;
  W                     : Word;
  Paleta                : TPaleta;
  Titulo1, Titulo2      : Pointer;

  Screen                        : Pointer;
  banko                         : byte;
  ScrOfs, ScrSeg          : longint;
  c                             : Byte;




Type
  TSprite              = Record X1, Y1, X2, Y2, CX, CY : Integer; End;

Const
  Sprite               : Array[1..20] Of TSprite =
                         (
                         (X1:001; Y1:001; X2:039; Y2:061; CX:+00; CY:+00),
                         (X1:041; Y1:001; X2:079; Y2:062; CX:+00; CY:-02),
                         (X1:081; Y1:001; X2:118; Y2:063; CX:+05; CY:-01),
                         (X1:120; Y1:001; X2:178; Y2:056; CX:-03; CY:-01),
                         (X1:180; Y1:001; X2:220; Y2:033; CX:+07; CY:+30),

                         (X1:001; Y1:063; X2:038; Y2:116; CX:+07; CY:+00),
                         (X1:040; Y1:064; X2:073; Y2:116; CX:+07; CY:+01),
                         (X1:075; Y1:065; X2:101; Y2:117; CX:+10; CY:+00),
                         (X1:103; Y1:065; X2:158; Y2:109; CX:-04; CY:+00),
                         (X1:160; Y1:058; X2:205; Y2:086; CX:+0;  CY:+27),

                         (X1:001; Y1:118; X2:037; Y2:178; CX:+07; CY:+18),
                         (X1:039; Y1:118; X2:073; Y2:181; CX:+04; CY:+18),
                         (X1:075; Y1:119; X2:116; Y2:183; CX:+02; CY:+18),
                         (X1:118; Y1:122; X2:181; Y2:181; CX:-8; CY:+18),
                         (X1:160; Y1:088; X2:208; Y2:120; CX:-07; CY:+42),

                         (X1:183; Y1:122; X2:237; Y2:195; CX:-07; CY:+42),
                         (X1:001; Y1:001; X2:050; Y2:080; CX:-01; CY:+42),
                         (X1:053; Y1:001; X2:122; Y2:086; CX:-22; CY:+33),

                         {EL PROTAGONISTA}
                         (X1:001; Y1:082; X2:034; Y2:157; CX:000; CY:000),
                         (X1:036; Y1:088; X2:076; Y2:162; CX:000; CY:000)
                         );

Type
  Tipo                  = Array[0..223] Of Record
                                             Bitmap : Array[0..16] Of Array[0..11] Of Byte;
                                           End;

procedure setpixel(x, y : Longint; C : byte);
  var
    b, d : longint;
  Begin
     d:=(Y*640+X);
     B:=D SHR 16;

     if b<>banko then
       begin
         asm
           mov ax,$4f05
           xor bx, bx
           mov dx,word(b)
           int $10
         end;
       banko:=B;
       end;
    d:=d-(b shl 16);
    asm
      mov ax, 0a000h
      mov es, ax
      mov bx, word(d)
      mov cl, c
      mov byte ptr [es:bx], cl

    end;
  end;



Var
  Font                  : ^Tipo;
  TMaxY, TMinY, TMaxX   : Byte;
  Indice                : Word;

Procedure LoadFont(CX, CY : LongInt);
  Var
    X, Y, FX, FY                : LongInt;
    Origen                      : File;
    Cadena                      : Array[00..13] Of Byte;
    D                           : Byte;
  Begin
    Assign(Origen, 'FONTS.VGA'); Reset(Origen, 1);
    { Tama¤o de la rejilla (en caracteres) : 32 * 07 }
    { Tama¤o del caracter  (en pixels)     : 14 * 16 }
    Seek(Origen, 4+((CY*640)+CX)+641);
    For FY:=00 To 06 Do
      Begin
        For Y:=0 To 16 Do
          Begin
            For FX:=00 To 31 Do
              Begin
                BlockRead(Origen, Cadena, 12);
                For X:=000 To 011 Do Font^[FY*32+FX].Bitmap[Y][X]:=Cadena[X];
                BlockRead(Origen, Cadena, 1);
              End;
            Seek(Origen, FilePos(Origen)+224)
          End;
        Seek(Origen, FilePos(Origen)+640)
      End;
    Close(Origen);

    TMinY:=16;
    TMaxY:=00;
    For FY:=000 To 223 Do
      For Y:=0 To 16 Do
        For X:=0 To 11 Do
          Begin
            If Font^[FY].Bitmap[Y][X]<>255 Then
              Begin
                If TMinY > Y Then TMinY:=Y;
                If TMaxY < Y Then TMaxY:=Y;
              End;
          End;

    TMaxX:=0;

    For FY:=0 To 223 Do
      Begin
        D:=$00;
        For X:=0 To 11 Do
          Begin
            For Y:=0 To 16 Do
              If Font^[FY].Bitmap[Y][X]<>255 Then
                Begin
                  If X > TMaxX Then TMaxX:=X;
                  If D=$00 Then D:=X
                End;
          End;
        If D>01 Then
          For Y:=0 To 16 Do
            Move(Mem[Seg(Font^):Ofs(Font^)+(FY*204)+(Y*12)], Mem[Seg(Font^):Ofs(Font^)+(FY*204)+(Y*12)-D+0], 12);

      End;
  End;

Procedure Texto(PX, PY : integer; T : String);
  Var
    W, C, N, A, B, X, Y      : Word;
    EOC, Q, K                : Word;
    r :byte;
  Label
    Uno, Cero;

  Begin
    py:=py-3;
    Asm
      MOV AX, [Offset(Font)]    { OJO con los corchetes !! }
      MOV K, AX
    End;
    For Q:=1 To Length(T) Do
      Begin
        Case T[Q] Of
          #33..#125 : Begin
                        N:=Ord(T[Q])-32;
                        Asm
                          XOR AX, AX
                          MOV AX, EOC
                        End;
                      End;
          #32       : Asm
                        MOV EOC, pitch*2
                        XOR AX, AX
                        MOV N, AX
                      End;
          Else
            Asm
              MOV EOC, 4
              XOR AX, AX
              MOV N, AX
            End;
        End;
        For X:=0 To TMaxX Do
          For Y:=TMinY To TMaxY Do
            Begin
              Asm
                MOV SI, X
                MOV DI, Y

                MOV AX, N
                MOV BX, 204
                MUL BX
                MOV CX, AX
                MOV AX, DI
                MOV BX, 12d
                MUL BX
                ADD AX, DX
                ADD AX, CX
                ADD AX, SI
                MOV BX, AX
                MOV AX, Word(Font+2)
                MOV ES, AX
                MOV AH, [ES:BX]
                CMP AH, 1
                mov r, ah
                End;

              if r =255 then goto cero;
                asm
                MOV AX, PY
                ADD DI, AX
                MOV A, DI
                MOV BX, SI
                ADD BX, PX
                MOV B, BX
                MOV AX, DI
                MOV BX, 10d
                MUL BX
                SHL AX, 3d
                MOV BX, B
                SHR BX, 3d
                ADD AX, BX
                MOV DX, AX
                MOV DI, B
                AND DI, 7d
                MOV EOC, SI
                MOV AX, DI
                ADD AX, AX
              End;
              Mem[$A000:(Y+PY)*320+X+PX-q*1]:=R;
                {
                MOV BX, Offset(Potencias)
                ADD BX, AX
                MOV AX, [BX]
                MOV CX, 0A000h
                MOV ES, CX
                MOV BX, DX
                MOV CX, [ES:BX]
                OR CX, AX
                MOV [ES:BX], CX
                }
                Cero:
            End;
        Asm
          MOV AX, PX
          ADD AX, EOC
          ADD AX, Pitch
          MOV PX, AX
        End;
        {PX:=PX+8;}
        waitretrace;
      End;
  End;

Procedure Center(px, PY : integer; T : String; descent : integer);
  Var
    W, C, N, A, B, X, Y      : Word;
    EOC, Q, K, opx           : Word;
    r :byte;
  Label
    Uno, Cero;

  Begin
  opx:=px;
    Asm
      MOV AX, [Offset(Font)]    { OJO con los corchetes !! }
      MOV K, AX
    End;
    For Q:=1 To Length(T) Do
      Begin
        Case T[Q] Of
          #33..#125 : Begin
                        N:=Ord(T[Q])-32;
                        Asm
                          XOR AX, AX
                          MOV AX, EOC
                        End;
                      End;
          #32       : Asm
                        MOV EOC, pitch*2
                        XOR AX, AX
                        MOV N, AX
                      End;
          Else
            Asm
              MOV EOC, 4
              XOR AX, AX
              MOV N, AX
            End;
        End;
        For X:=0 To TMaxX Do
          For Y:=TMinY To TMaxY Do
            Begin
              Asm
                MOV SI, X
                MOV DI, Y

                MOV AX, N
                MOV BX, 204
                MUL BX
                MOV CX, AX
                MOV AX, DI
                MOV BX, 12d
                MUL BX
                ADD AX, DX
                ADD AX, CX
                ADD AX, SI
                MOV BX, AX
                MOV AX, Word(Font+2)
                MOV ES, AX
                MOV AH, [ES:BX]
                CMP AH, 1
                mov r, ah
                End;

              if r =255 then goto cero;
                asm
                MOV AX, PY
                ADD DI, AX
                MOV A, DI
                MOV BX, SI
                ADD BX, px
                MOV B, BX
                MOV AX, DI
                MOV BX, 10d
                MUL BX
                SHL AX, 3d
                MOV BX, B
                SHR BX, 3d
                ADD AX, BX
                MOV DX, AX
                MOV DI, B
                AND DI, 7d
                MOV EOC, SI
                MOV AX, DI
                ADD AX, AX
              End;
{              Mem[$A000:(Y+PY)*320+X+PX-q*1]:=R;}
                {
                MOV BX, Offset(Potencias)
                ADD BX, AX
                MOV AX, [BX]
                MOV CX, 0A000h
                MOV ES, CX
                MOV BX, DX
                MOV CX, [ES:BX]
                OR CX, AX
                MOV [ES:BX], CX
                }
                Cero:
            End;
        Asm
          MOV AX, px
          ADD AX, EOC
          ADD AX, Pitch
          MOV PX, AX
        End;
        {PX:=PX+8;}
      End;
    texto(160-(((px-q)-opx) div 2)+descent, py, t);
  End;

Procedure DrawSprite(Cual : Word; DondeX, DondeY : Word);
  Var
    X, Y                        : Word;
    X1, Y1, X2, Y2              : Word;
    Color                       : Byte;
  Begin
    X1:=Sprite[Cual].X1;
    Y1:=Sprite[Cual].Y1;
    X2:=Sprite[Cual].X2;
    Y2:=Sprite[Cual].Y2;
    {
    For Y:=Y1 To Y2 Do
      For X:=X1 To X2 Do
        Begin
          Color:=Mem[Seg(Sprites1^):Y*320+X];
          If Color <> 1 Then
            Mem[$A000:(DondeY+Y-Y1+Sprite[Cual].CY)*320+DondeX+X-X1+Sprite[Cual].CX]:=Color;
        End;
        }
    For Y:=0 To Y2-Y1 Do
      For X:=0 To X2-X1 Do
        Begin
          If Cual < 17 Then
            Color:=Mem[Seg(Sprites1^):(Y+Y1)*320+(X+X1)]
          Else
            Color:=Mem[Seg(Sprites2^):(Y+Y1)*320+(X+X1)];
          If Color <> 1 Then
            Mem[$A000:(DondeY+Y+Sprite[Cual].CY)*320+DondeX+X+Sprite[Cual].CX]:=Color;
        End;
  End;

Procedure PonFondo(Cual : Word; DondeX, DondeY : Word);
  Var
    X, Y                        : Word;
    X1, Y1, X2, Y2              : Word;
    Color                       : Byte;
  Begin
    X1:=Sprite[Cual].X1;
    Y1:=Sprite[Cual].Y1;
    X2:=Sprite[Cual].X2;
    Y2:=Sprite[Cual].Y2;
    For Y:=0 To Y2-Y1 Do
      For X:=0 To X2-X1 Do
        Begin
          Color:=Mem[Seg(Fondo^):(DondeY+Y+Sprite[Cual].CY)*320+DondeX+X+Sprite[Cual].CX];
          Mem[$A000:(DondeY+Y+Sprite[Cual].CY)*320+DondeX+X+Sprite[Cual].CX]:=Color;
        End;
    {
    For Y:=Y1 To Y2 Do
      For X:=X1 To X2 Do
        Begin
          Color:=Mem[Seg(Fondo^):(DondeY+Y-Y1+Sprite[Cual].CY)*320+DondeX+X-X1+Sprite[Cual].CX];
          Mem[$A000:(DondeY+Y-Y1+Sprite[Cual].CY)*320+DondeX+X-X1+Sprite[Cual].CX]:=Color;
        End;
        }
  End;

Procedure Intro1;
  Begin
{
  banko:=0;
  GetMem(Screen, 64000);
  Asm
    mov ax, 4f02h
    mov bx, 101h
    int 10h
  End;
  BlackPalette;
  Assign(Origen, 'inutil.VGA'); Reset(Origen, 1); Seek(Origen, 4);
  for C:=0 to 3 do
  begin
  BlockRead(Origen, Screen^, 64000);
  ScrOfs:=Ofs(Screen^);
  ScrSeg:=Seg(Screen^);
  For Y:=0 To 99 do
    For X:=0 To 639 Do
      Begin
        SetPixel(X, Y+c*100, Mem[ScrSeg:ScrOfs+Y*640+X]);
      End;
  end;
  BlockRead(Origen, Screen^, 640*80);
  For Y:=0 To 79 do
    For X:=0 To 639 Do
      Begin
        SetPixel(X, Y+400, Mem[ScrSeg:ScrOfs+(Y)*640+X]);
      End;

  Seek(Origen, FileSize(Origen)-768);
  BlockRead(Origen, Paleta, 768);
  SetPalFading(Paleta, 0);
  While KeyPressed Do If ReadKey=#0 Then ; Repeat Until KeyPressed;
  freemem(screen, 64000);
  halt;

 }
  ASM MOV AX, 0013h; INT 10h End;


    {
    }
    BlackPalette;
    New(Font);
    LoadFont(000, 126*0);
    GetMem(Titulo1, 64000); GetMem(Titulo2, 64000);

   LoadPCX('INTEND.PCX', Titulo1, Paleta);
    SetPalFading(Paleta, 0);
    For Y:=199 DownTo 183 Do
      Begin
        fillchar(mem[$a000:y*320], 320, 255); waitretrace;waitretrace;
      End;

    Texto(1, 186, 'Ano 2007.                                              Cuartel General de la Resistencia.');
    for y:=0 to 119 do waitretrace;
    blackpalette;
   Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
    SetPalFading(Paleta, 0);

   Center(10, 3+00,    'El Director del Instituto de Educacion Secun-'        , -10);
   Center(10, 3+11*01, 'daria "Las Llamas" de Santander ha instaurado'      , -10);
   Center(10, 3+11*02, 'un sistema represivo, truncando los partidos de'        , -10);
   Center(10, 3+11*03, 'palas en las aulas y prohibiendo la degusta-'   , -10);
   Center(10, 3+11*04, 'cion de chicle durante las clases.'             , -10);


  While keypressed do if readkey = #0 then ; repeat until keypressed;
    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);

   Center(10, 2+00,    'Se ha hecho rodear de mercenarios especial-'        , -10);
   Center(10, 2+11*01, 'mente entrenados para esta ocasion en el Minis-'      , -10);
   Center(10, 2+11*02, 'terio de Cultura. En sus filas cuenta con empollo-'        , -10);
   Center(10, 2+11*03, 'nes, torturadores docentes, profesores pijos'   , -10);
   Center(10, 2+11*04, 'de informatica, directivos, pastilleros...'             , -10);
  While keypressed do if readkey = #0 then ; repeat until keypressed;

    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);

   Center(10, 5+00,    'Todos ellos obedecen las siniestras ordenes'        , -11);
   Center(10, 5+11*01, 'de su mano derecha, la Jefa de Estudios, Sra.'      , -11);
   Center(10, 5+11*02, 'Urrusolo, una maquinacion del Consejo Escolar'        , -11);
   Center(10, 5+11*03, 'pagada con el dinero del narcotrafico.'   , -11);

  While keypressed do if readkey = #0 then ; repeat until keypressed;

    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);

   Center(10, 9+00,    'Tu mision es sencila: matarlos a todos. Para'        , -11);
   Center(10, 9+11*01, 'ello dispones solamente de un fusil de asalto'      , -11);
   Center(10, 9+11*02, 'AK-47, cocteles molotov y un rayo laser.'        , -11);
   Center(10, 9+11*03, 'Suerte.'        , -11);
  While keypressed do if readkey = #0 then ; repeat until keypressed;

   BlackPalette;
    LoadPCX('SOLDADO.PCX', Titulo1, Paleta);
    SetPalFading(Paleta, 0);
    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
    LoadFont(000, 126*1);
    Center(10, 45,    'NO LE'        , +55);
     Center(10, 55,   'DEFRAUDARE'   , +55);

  While keypressed do if readkey = #0 then ; repeat until keypressed;


  banko:=0;
  GetMem(Screen, 64000);
  Asm
    mov ax, 4f02h
    mov bx, 101h
    int 10h
  End;
  BlackPalette;
  Assign(Origen, 'EMBOSCAD.VGA'); Reset(Origen, 1); Seek(Origen, 4);
  for C:=0 to 3 do
  begin
  BlockRead(Origen, Screen^, 64000);
  ScrOfs:=Ofs(Screen^);
  ScrSeg:=Seg(Screen^);
  For Y:=0 To 99 do
    For X:=0 To 639 Do
      Begin
        SetPixel(X, Y+c*100, Mem[ScrSeg:ScrOfs+Y*640+X]);
      End;
      end;
  BlockRead(Origen, Screen^, 640*80);
  For Y:=0 To 79 do
    For X:=0 To 639 Do
      Begin
        SetPixel(X, Y+400, Mem[ScrSeg:ScrOfs+(Y)*640+X]);
      End;

  Seek(Origen, FileSize(Origen)-768);
  BlockRead(Origen, Paleta, 768);
  SetPalFading(Paleta, 0);
  While KeyPressed Do If ReadKey=#0 Then ; Repeat Until KeyPressed;
  freemem(screen, 64000);




    LoadFont(000, 126*2);
  ASM MOV AX, 0013h; INT 10h End;
   BlackPalette;
    LoadPCX('MONGOLO.PCX', Titulo1, Paleta);
    LoadFont(000, 000);
    SetPalFading(Paleta, 0);
    For Y:=199 DownTo 183 Do
      Begin
        fillchar(mem[$a000:y*320], 320, 255); waitretrace;waitretrace;
      End;

    Texto(1, 186, '...mientras tanto, en la Sala de profesores...');
    for y:=0 to 119 do waitretrace;
    blackpalette;
    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
    SetPalFading(Paleta, 0);

   Center(185, 12,          'Buenos dias,' , 60);
   Center(185, 12+10*1,     'Como Presidente del Conse-' , 64);
   Center(185, 12+10*2,     'jo Colar de este Instituto es mi' , 64);
   Center(185, 12+10*3,     'obligacion comunicarles que soy' , 64);
   Center(185, 12+10*4,     'la persona mas cretina del mun-' , 64);
   Center(185, 12+10*5,     'do y que alucino cuando me pon-' , 64);
   Center(185, 12+10*6,     'go a pensar lo tonto que soy.' , 64);

  While keypressed do if readkey = #0 then ; repeat until keypressed;


    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
   Center(185, 26,          'Un guerrillero ha entrado en' , 64);
   Center(185, 26+10*1,     'el Centro armado hasta los dien-' , 64);
   Center(185, 26+10*2,     'tes y nos va a sacudir a todos.' , 64);
   Center(185, 26+10*3,     'Confio en que el Sr. Director sepa' , 64);
   Center(185, 26+10*4,     'lo que hace...' , 64);
  While keypressed do if readkey = #0 then ; repeat until keypressed;

  ASM MOV AX, 0013h; INT 10h End;
   BlackPalette;
    LoadPCX('DIRECTOR.PCX', Titulo1, Paleta);
    SetPalFading(Paleta, 0);
    For Y:=199 DownTo 183 Do
      Begin
        fillchar(mem[$a000:y*320], 320, 255); waitretrace;waitretrace;
      End;

    Texto(1, 186, 'Despacho del director.');
    for y:=0 to 119 do waitretrace;
    blackpalette;
    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
    SetPalFading(Paleta, 0);
   LoadFont(000, 126*0);
   Texto(150, 50+15-40,  'Nombre'); LoadFont(000, 126*1);
   Texto(170, 65+15-40,  'Sr. Crusafont'); LoadFont(000, 126*0);
   Texto(150, 80+15-40,  'Inteligencia');LoadFont(000, 126*1);
   Texto(170, 95+15-40,  'Media/alta'); LoadFont(000, 126*0);
   Texto(150, 110+15-40, 'Tapadera');LoadFont(000, 126*1);
   Texto(170, 125+15-40, 'Director de instituto'); LoadFont(000, 126*0);
   Texto(150, 140+15-40, 'Negocios'); LoadFont(000, 126*1);
   Texto(170, 155+15-40, 'Trafico de cocaina.');
   Texto(170, 167+15-40, 'Conexiones con la');
   Texto(170, 179+15-40, 'mafia rusa.');
   Texto(170, 191+15-40, 'Extorsion.');

  While keypressed do if readkey = #0 then ; repeat until keypressed;

  banko:=0;
  GetMem(Screen, 64000);
  Asm
    mov ax, 4f02h
    mov bx, 101h
    int 10h
  End;
  BlackPalette;
  Assign(Origen, 'INUTIL.VGA'); Reset(Origen, 1); Seek(Origen, 4);
  for C:=0 to 3 do
  begin
  BlockRead(Origen, Screen^, 64000);
  ScrOfs:=Ofs(Screen^);
  ScrSeg:=Seg(Screen^);
  For Y:=0 To 99 do
    For X:=0 To 639 Do
      Begin
        SetPixel(X, Y+c*100, Mem[ScrSeg:ScrOfs+Y*640+X]);
      End;
      end;
  BlockRead(Origen, Screen^, 640*80);
  For Y:=0 To 79 do
    For X:=0 To 639 Do
      Begin
        SetPixel(X, Y+400, Mem[ScrSeg:ScrOfs+(Y)*640+X]);
      End;

  Seek(Origen, FileSize(Origen)-768);
  BlockRead(Origen, Paleta, 768);
  SetPalFading(Paleta, 0);
  While KeyPressed Do If ReadKey=#0 Then ; Repeat Until KeyPressed;
  freemem(screen, 64000);

  ASM MOV AX, 0013h; INT 10h End;
   BlackPalette;
    LoadPCX('PRESENTA.PCX', Titulo1, Paleta);
    Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
    SetPalFading(Paleta, 0);
  While KeyPressed Do If ReadKey=#0 Then ; Repeat Until KeyPressed;

  ASM MOV AX, 0013h; INT 10h End; blackpalette;
    LoadPCX('TITULO1.PCX', Titulo1, Paleta);
    LoadPCX('TITULO2.PCX', Titulo2, Paleta);
    SetPalFading(Paleta, 0);


  Init_SB;
  Init_Voc('nacht.voc');
  Ch := #0;
  NOP:=FALSE;
  Port[$224]:=$2E;
  Port[$225]:=(e shl 5) + (e shl 1);







Move(Titulo1^, Mem[$A000:0000], 64000); Delay(10);
    For Y:=0 To 319 Do Linea[Y]:=0;

    For Y:=0 To 439 Do Waitretrace;
    While KeyPressed Do If ReadKey = #0 Then ;
    For Y:=0 To 430 Do
      Begin
        For X:=0 To 319 Do
          Begin
            R:=X;
            W:=Linea[R]*320+X;
            Mem[$A000:W]:=Mem[Seg(Titulo2^):W];
            if random(2) = 1 Then
            Linea[R]:=Linea[R]+1;
            If Linea[R] >= 200 Then Linea[R]:=0;
          End;
      Waitretrace;
      End;
    For Y:=0 To 286 Do Waitretrace;
    For Y:=0 To 319 Do Linea[Y]:=0;
     For Y:=0 To 500 Do
      Begin
        For X:=0 To 319 Do
          Begin
            R:=X;
            Mem[$A000:Linea[R]*320+X]:=0;
            if random(2) = 1 Then
            Linea[R]:=Linea[R]+1;
            If Linea[R] >= 200 Then Linea[R]:=0;
          End;
        Waitretrace;
      End;
  VOC_Done;
  Dispose(Font);
  End;

Procedure InitGame;
  Begin
    GetMem(Sprites1, 64000); GetMem(Sprites2, 64000); BlackPalette;
    GetMem(Fondo, 64000);
    Assign(Origen, 'MASACRE.PAL');  Reset(Origen, 1); Blockread(Origen, Paleta, 768); Close(Origen);
    Assign(Origen, 'FONDO.VGA');    Reset(Origen, 1); Seek(Origen, 4); Blockread(Origen, Fondo^, 64000);    Close(Origen);
    Assign(Origen, 'SPRITES1.VGA'); Reset(Origen, 1); Seek(Origen, 4); Blockread(Origen, Sprites1^, 64000); Close(Origen);
    Assign(Origen, 'SPRITES2.VGA'); Reset(Origen, 1); Seek(Origen, 4); Blockread(Origen, Sprites2^, 64000); Close(Origen);
    Move(Fondo^, Mem[$A000:0000], 64000);
    SetPalFading(Paleta, 0);
  End;

Procedure Sangre(X, Y : Word);
  Procedure Punto(X, Y : Word); Begin Mem[$A000:Y*320+X]:=22; End;

  Var
    Puntos              : Array[1..10] Of Record X, Y : Word; End;
    E, G                : Word;

  Begin
    Punto(X, Y);
    For E:=1 To 10 Do Begin Puntos[E].X:=X; Puntos[E].Y:=Y; End;

    For G:=0 To 5 Do
      Begin
    Delay(300);
      For E:=1 To 10 Do
        Begin
          Puntos[E].X:=Puntos[E].X+Random(4)+1-2;
          Puntos[E].Y:=Puntos[E].Y+Random(4)+1-2;
        End;
    For E:=1 To 10 Do Punto(Puntos[E].X, Puntos[E].Y);
End;
  End;

Procedure PutPixel(X, Y : Word; C : Byte);
  Begin
    Mem[$A000:Y*320+X]:=C;
  End;

Procedure Laser(X, Y : Word);
  Var
    I                            : Word;
    Q : real;
    dir, d, t, n: longint;
    punto : array[1..20] of record x, y : real; end;
  Begin
    PutPixel(160, 190, 15);
    PutPixel(X, Y, 10);
    {
    delay(1009);
    Q:=160;
    if x > 160 then dir:=1 else dir:=-1;
    For I:=190 DownTo Y Do
      Begin
        if dir =1 then Q:=Q+(x-160) / (190-Y)
        else Q:=Q-(160-x) / (190-Y);
        if q < 0 then q:=0;
        PutPixel(round(Q), I, 10);
        d:=I DIV 40;
        if d <= 3 then d:=0;
        delay(d);
      End;
      }
    putpixel(X, y, 12);
    for i:=1 to 20 do punto[i].x:=160;
    for i:=1 to 20 do punto[i].y:=100;

    randomize;
    for n:=1 to 30 do
      begin
        for i:=1 to 20 do putpixel(round(punto[i].x), round(punto[i].y), 0);


             punto[1].x:=((30-n)*(30-n))/15+110;
             punto[1].y:=100-sin(n / 8)*49;



        for i:=1 to 20 do putpixel(round(punto[i].x), round(punto[i].y), 12);
        delay(50);
      end;




    repeat until keypressed; halt;
  End;

Begin
  Intro1;
 halt;

  ASM MOV AX, 0013h; INT 10h End;
  Laser(160, 100);

  InitGame;


  X:=306;
  Repeat
  {
  DrawSprite(19, X, 58);
  For Y:=1 To 9 Do waitretrace;
  PonFondo(19, X, 58);
  X:=X+3;

  DrawSprite(20, X, 58);
  For Y:=1 To 9 Do waitretrace;
  PonFondo(20, X, 58);
  X:=X+3;
  }


  DrawSprite(1, X, 58); DrawSprite(7, X, 1); DrawSprite(11, X, 106); DrawSprite(16, X+50, 16);
  For Y:=1 To 9 Do waitretrace;
  PonFondo(1, X, 58); PonFondo(7, X, 1); PonFondo(11, X, 106); PonFondo(16, X+50, 16);
  X:=X-5;


  DrawSprite(3, X, 58); DrawSprite(6, X, 1); DrawSprite(12, X, 106); DrawSprite(17, X+50, 16);
  For Y:=1 To 9 Do waitretrace;
  PonFondo(3, X, 58); PonFondo(6, X, 1); PonFondo(12, X, 106); PonFondo(17, X+50, 16);
  X:=X-5;

  DrawSprite(2, X, 58); DrawSprite(7, X, 1); DrawSprite(11, X, 106); DrawSprite(18, X+50, 16);
  For Y:=1 To 9 Do waitretrace;
  PonFondo(2, X, 58); PonFondo(7, X, 1); PonFondo(11, X, 106); PonFondo(18, X+50, 16);
  X:=X-5;

  DrawSprite(3, X, 58); DrawSprite(8, X, 1); DrawSprite(13, X, 106); DrawSprite(17, X+50, 16);
  For Y:=1 To 9 Do waitretrace;
  PonFondo(3, X, 58); PonFondo(8, X, 1); PonFondo(13, X, 106); PonFondo(17, X+50, 16);
  X:=X-5;




  if x <= 130 then
    begin
  DrawSprite(4, X, 58); DrawSprite(9, X, 1); DrawSprite(14, X, 106);
  For Y:=1 to 15 do waitretrace;
  PonFondo(4, X, 58); PonFondo(9, X, 1); PonFondo(14, X, 106);
  X:=X-5;
  DrawSprite(5, X, 58); DrawSprite(10, X, 1); DrawSprite(15, X, 106);
  For Y:=1 to 15 do waitretrace;
  PonFondo(5, X, 58); PonFondo(10, X, 1); PonFondo(15, X, 106);
  X:=X-5;
      x:=230;
    end;

   
  Until KeyPressed;
  While KeyPressed Do If ReadKey = #0 Then ;

  FreeMem(Sprites1, 64000); FreeMem(Sprites2, 64000);
  textmodE(3);




End.
{
Procedure LoadFondo(Desde, Hasta : Word);
  Var
    X, Y, Bloque                : Word;
  Begin
    Seek(Origen, 4+Desde);
    For Bloque:=0 To 2 Do
      Begin
        BlockRead(Origen, Fondo^, 960*65);
        For Plane:=0 To 3 Do
          Begin
            Plano(Plane);
            For Y:=0 To 64 Do
              For X:=0 To 319 Do
                Mem[$A000:((Y+Bloque*65)*320+X) DIV 4+Hasta]:=Mem[Seg(Fondo^):Y*960+X+Desde+Plane];
          End;
      End;
  End;
}
