Unit VocPlay;

INTERFACE

Uses
  Crt, Dos;

TYPE
  VocHeader  = Record
                 Cadena_Id       : Array[0..19] Of Char;
                 Sampoff         : Word;
                 VersLo          : Byte;
                 VersHi          : Byte;
                 Identificador   : Word;
               End;
  VoiceBlock = Record
                 Identificador  : Byte;
                 Long_lo        : Word;
                 Long_hi        : Byte;
                 SR             : Integer;
                 Pack           : Byte;
               End;

Const
  dsp_irq            = $5;
  dma_ch             = 1;
  dsp_adr            = $220;
  SbProDetected      : BOOLEAN = FALSE;  { SB Pro presente?           }
  Block_Activ        : Byte = 1;

Var
  TamBloc          : word;
  SaveExitProc     : Pointer;          { necesario ya que Exitproc  }

Var
  LastOne          : Boolean;
  VOC_READY        : Boolean;
  Inread           : Array[1..25] of byte;
  VocF             : File;
  FGR              : Longint;
  Blk1, Blk2       : Pointer;
  VOCh             : VocHeader;
  VBlock           : VoiceBlock;

  Function Init_SB : boolean;
  Procedure Wr_dsp(v : byte);
  Procedure Set_Timeconst_sb16(tc : byte);
  Procedure Reprod_Bloque_DSP(gr : word;bk : pointer;b1,b2 : boolean);
  Procedure Reproduce_Sb(Segm,Offs,dsize : word);
  Procedure Init_Voc(filename : string);
  Procedure Voc_Done;

IMPLEMENTATION

TYPE
  Pt = Record
         Ofs, Sgm    : Word;
       End;

CONST
  Frec_Sampling      : Word = 20000;
  DMA_Page           : Array[0..3] Of Byte = ($87, $83, $81, $81);
  DMA_Adr            : Array[0..3] Of Byte = (0, 2, 4, 6);
  DMA_Wc             : Array[0..3] Of Byte = (1, 3, 5, 7);
  SB16_LongitudSalida: word = 0;
  Ultima_Reprod      : Boolean = FALSE;

VAR
  DSP_Rdy_SB16        : Boolean;
  OldInt              : pointer;
  IRQMsk              : byte;

Procedure Wr_dsp(V : Byte);
  Begin
    While Port[Dsp_Adr+$c] >= 128 Do ;
    Port[DSP_Adr+$c] := v;
  End;

Function SbReadByte : Byte;
  Begin
    While Port[DSP_Adr+$a] = $AA Do ;     { esperar al DSP             }
    SbReadByte := Port[DSP_Adr+$a];       { escribir valor             }
  End;

Procedure REproduce_Sb(Segm, Offs, DSize : Word);
  Var
    Li            : Word;
  Begin
    port[$0A] := dma_ch+4;                { bloquear canal DMA         }
    Port[$0c] := 0;                       { direcc. del b£fer   (blk)  }
    Port[$0B] := $49;                     { para salida sonido         }
    Port[dma_adr[dma_ch]] := Lo(offs);    { al controlador DMA         }
    Port[dma_adr[dma_ch]] := Hi(offs);
    Port[dma_wc[dma_ch]] := Lo(dsize-1);  { tama¤o del bloque (block-  }
    Port[dma_wc[dma_ch]] := Hi(dsize-1);  { groesse) al control. DMA   }
    Port[dma_page[dma_ch]] := Segm;
    Wr_dsp($14);
    Wr_dsp(Lo(dsize-1));                  { tama¤o del bloque al       }
    Wr_dsp(Hi(dsize-1));                  { DSP                        }
    Port[$0A] := dma_ch;                  { liberar canal DMA          }
  End;

Procedure DSP_Int_SB16; Interrupt;
  Var
    H             : Byte;
  Begin

    H := Port[DSP_Adr+$E];
    If (FGR > TamBloc) And NOT LastOne Then
      Begin
	LastOne := FALSE;
	If Block_Activ = 1 Then
          Begin
	    Reprod_Bloque_DSP(TamBloc, Blk2, FALSE, TRUE);
   	    BlockRead(VocF, Blk1^,TamBloc);
            FGR := FGR - TamBloc;
	    Block_Activ := 2;
	  End
        Else
          Begin
	    Reprod_Bloque_DSP(TamBloc, Blk1, FALSE, TRUE);
	    BlockRead(VocF, Blk2^, TamBloc);
	    fgr := fgr - TamBloc;
	    Block_Activ := 1;
  	  End;
      End
    Else
      Begin
        If NOT LastOne Then
          Begin
            If block_activ = 1 then
              Begin
                Reprod_Bloque_DSP(TamBloc, Blk2, FALSE, TRUE);
                LastOne := TRUE;
              End
            Else
              Begin
                Reprod_Bloque_DSP(TamBloc, Blk1, FALSE, TRUE);
                LastOne := TRUE;
              End;
          End
        Else
          Begin
            Dsp_Rdy_SB16 := TRUE;
            Wr_Dsp($D0);
            VOC_READY := TRUE;
          End;
      End;

    Port[$20] := $20;
  End;

Function Init_SB : boolean;
  Begin
    Init_SB := TRUE;
    Wr_dsp($D1);                           { activar altavoz            }
    GetIntVec($8+DSP_IRQ, OldInt);          { guardar interr. antigua    }
    SetIntVec($8+DSP_IRQ, @Dsp_INT_SB16);   { colocar a rutina propia    }
    Irqmsk := 1 shl dsp_irq;               { enmascarar interrupci¢n    }
    Port[$21] := Port[$21] And NOT IRQMsk;
  End;

Procedure Exit_Sb16;
  Begin;
    SetIntVec($8+DSP_IRQ, Oldint);        { restaurar interr. antigua  }
    Port[$21] := Port[$21] OR IRQMsk;     { y reponer enmascaramiento  }
    Port[DSP_Adr+$c] := $d3;              { a valor antiguo            }
    Port[$20] := $20;
    Wr_DSP($D0);
  End;

{$F+}
Procedure MODExitProc;
  Begin
    ExitProc := SaveExitProc;
    Exit_Sb16;
  End;
{$F-}

Procedure Reprod_Bloque_DSP(Gr : Word; BK : Pointer; B1, B2 : Boolean);
  Var
    L             : LongInt;
    Pn, Offs      : Word;

  Begin
    Dsp_Rdy_SB16 := FALSE;
    L := 16*LongInt(Seg(Bk^))+Ofs(Bk^);
    Pn := Pt(L).Sgm;
    Offs := Pt(L).Ofs;
    SB16_LongitudSalida := 0;
    Set_TimeConst_SB16(VBlock.SR);
    Reproduce_Sb(Pn, Offs, Gr);
  End;

Procedure Init_Voc(FileName : String);
  Const
    VOCkenn                     : String = 'Creative Voice File'+#$1A;
  Var
    Ch                  : Char;
    Cadena_Id           : String;
    SR                  : Word;
    Error               : Integer;
    SamplingR           : Word;
  Begin
    VOC_READY := FALSE;
    Assign(VocF, FileName);
    Reset(VocF, 1);
    If FileSize(VocF) < 5000 Then
      Begin
        VOC_READY   := TRUE;
        Exit;
      End;

{*}VBlock.SR:=170;
{*}Set_TimeConst_SB16(VBlock.SR);

    TamBloc := FileSize(VocF) - 31;
    If TamBloc > 2500 Then TamBloc := 2500;
    BlockRead(VocF, Blk1^, TamBloc);

    Ch := #0;
    FGR := FileSize(VocF) - 32;
    FGR := FGR - TamBloc;
    Block_Activ := 1;
    If FGR > 1 Then
      Begin
        BlockRead(VocF, Blk2^, TamBloc);
        FGR := FGR - TamBloc;
      End;
     Wr_dsp($D1);
     LastOne := FALSE;
     Reprod_Bloque_DSP(TamBloc, Blk1, FALSE, TRUE);
  End;

Procedure Voc_Done;
  Begin
    LastOne := TRUE;
    Repeat Until DSP_Rdy_sb16;
    Close(VocF);
  End;

Procedure Set_Timeconst_sb16(tc : byte);
  Begin
    Wr_DSP($40);
    Wr_DSP(tc);
  End;

Begin

  SaveExitProc := ExitProc;
  ExitProc := @MODExitProc;
  DSP_Rdy_SB16 := TRUE;
  GetMem(blk1, 2500);
  GetMem(blk2, 2500);

End.
