Uses
  Crt, Dos, VocPlay;

Var
  Ch            : Char;
  NOP           : Boolean;

  const e =7 ;
Begin
  ClrScr;
  Init_SB;
  Init_Voc('nacht.voc');
  Ch := #0;
  NOP:=FALSE;
  Port[$224]:=$2E;
  Port[$225]:=(e shl 5) + (e shl 1);
  Repeat
    IF NOT NOP Then
      If VOC_Ready Then Begin VOC_Done;
  Init_Voc('record4.voc');

      End;
    Write(Random(10));

  Until (KeyPressed);
  If NOT NOP Then VOC_Done;

End.