

{ MIXER }

{$A+,B-,D+,E-,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V+,X+,Y+}
{$M 16384,0,655360}

unit mixer;

{ Program by Borek (Marcin Borkowski), Warsaw, Poland.
  You can find me in a Top Secret BBS, +48 2 6788783
  Fido 2:480/25, Pascal Net 115:4804/104

  If you can't recognize - it is Sound Blaster version.

  You may freely copy and use this source, as long it is
  unchanged and states my name in the begining. If you find
  more profitable use of this code, fell free to share your
  profits with me! At least - let me know you were able to
  use it for your own purposes.

  This unit should be accompanied by the MODPLAY source.

  This version of mixing (even at 44 kHz) works OK on my
  UMC 40 MHz machine (that's a little bit less than 486 50 MHz).
  If you want to make it work on 386DX 33MHz, you must 'unroll'
  the main loop and put used there data into 'hardcoded' variables.
  Such a version works on my old 386 and on several other
  computers of the same class, even with QEMM.

  If you stop this program by ctrl break, you may not be able to
  restart it without resetting your computer - and that's not the
  only one bug I know in the code.

  Parts of code ripped from PCPGE, various sources from
  Ethan Brodsky and probably from SWAG. I can't remember
  source of every byte, but for sure 95% of code is mine.}

interface

procedure addvoice(voice,_samplesize,_loopstart,_loopend : word;
                   sample : pointer);
procedure startchannel(channel,voice,volume,frequency : word);
procedure stopchannel(channel : word);
procedure setchannelfrequency(channel,frequency : word);
procedure setchannelvolume(channel,volume : word);

implementation

uses crt,dos;

const
{ Mixer data }
  max_num_voices = 31; { number of voices }
  max_num_channels = 4; { number of channels }
  PlayFreq = 48000; { samples played at, at 11111 sound is very bad. }
  playbufsize = 640; { Size of play buffer}
{ SB data - change it for your card settings. }
  SBIO    : word = 2;  { 2x0 }
  SBIRQ   : word = 5;

type
  sampledata = array[0..65533]of byte;
  _channel   = record
                 nvoice,position,increment,subposition,vol : word;
                 inloop,active : boolean
               end;

var
{ Pointers to samples. }
  voicesdata : array[1..max_num_voices]of ^sampledata;
{ Sizes of voices }
  voicessize : array[1..max_num_voices]of word;
{ Those two defines begining and end of loop in sample }
  voicesloopstart : array[1..max_num_voices]of word;
  voicesloopend : array[1..max_num_voices]of word;
{ Voice ready to use? }
  voicesdefined : array[1..max_num_voices]of boolean;
{ Which voice played in this channel? }
  channelsnvoice : array[1..max_num_channels]of word;
{ Which position in sample? }
  channelsposition : array[1..max_num_channels]of word;
{ How to increment subposition? }
  channelsincrement : array[1..max_num_channels]of word;
{ Which subposistion in position - it allows to change frequencies,
  as one byte of sample can be played several times. It gives not a
  perfect sound, but it works. To improove sound quality, one should
  use interpolation (and assembler :-) }
  channelssubposition : array[1..max_num_channels]of word;
{ Volume of channel }
  channelsvol : array[1..max_num_channels]of word;
{ Is sample in this channel loop? }
  channelsinloop : array[1..max_num_channels]of boolean;
{ Channel being played? }
  channelsactive : array[1..max_num_channels]of boolean;

{ SB addresses }
  DSP_RESET        : word;
  DSP_READ_DATA    : word;
  DSP_WRITE_DATA   : word;
  DSP_WRITE_STATUS : word;
  DSP_DATA_AVAIL   : word;

  timeconst        : byte;
  playbuf          : pointer;
  oldint,oldexit   : pointer;
  firstbuff        : boolean;

function carry : boolean;
inline($B0/$01/     {  mov al,01 }
       $72/$02/     {  jc @carryset }
       $30/$C0);    {  xor al,al }
                    { @carryset: }

function ResetDSP(base : word) : boolean;
begin
  base := base * $10;
  DSP_RESET := base + $206;
  DSP_READ_DATA := base + $20A;
  DSP_WRITE_DATA := base + $20C;
  DSP_WRITE_STATUS := base + $20C;
  DSP_DATA_AVAIL := base + $20E;
  Port[DSP_RESET] := 1;
  Delay(1);
  Port[DSP_RESET] := 0;
  Delay(1);
  if (Port[DSP_DATA_AVAIL] And $80 = $80) And (Port[DSP_READ_DATA] = $AA)
     then ResetDSP := true
     else ResetDSP := false;
end;

procedure WriteDSP(value : byte);
begin
  while Port[DSP_WRITE_STATUS] And $80 <> 0 do;
  Port[DSP_WRITE_DATA] := value;
end;

function ReadDSP : byte;
begin
  while Port[DSP_DATA_AVAIL] and $80 = 0 do;
  ReadDSP := Port[DSP_READ_DATA];
end;

function SpeakerOn: byte;
begin
  WriteDSP($D1);
end;

function SpeakerOff: byte;
begin
  WriteDSP($D3);
end;

procedure Playback;
var
  page,offset,size   : word;
begin
{ SB and DMA are working in autoinit modes - but DMA buffer is
  twice as long as SB buffer. Each time SB buffer is finished an
  IRQ is generated - a signal that next part of samples should be
  mixed. Play buffer has two parts - when one is played, second
  is being filled. Simple, uh? This version of procedure was checked
  on AWE 32, on SB 16 and on several clones of SB, but for sure
  it'll not work on some cards - especially on older versions
  that are not supporting autoinit mode. }
  firstbuff:=true;
  size := playbufsize-1;
  offset := Seg(playbuf^) Shl 4 + Ofs(playbuf^);
  page := (Seg(playbuf^) + Ofs(playbuf^) shr 4) shr 12;
{ DMA programming }
  Port[$0A] := 5;
  Port[$0C] := 0;
  Port[$0B] := $59; { DMA autoinit }
  Port[$02] := Lo(offset);
  Port[$02] := Hi(offset);
  Port[$83] := page;
  Port[$03] := Lo(size);
  Port[$03] := Hi(size);
  Port[$0A] := 1;
{ SB programming }
  WriteDSP($40);
  WriteDSP(timeconst);
  WriteDSP($48); { 8-bit sample type with autoinit}
  WriteDSP(Lo(playbufsize shr 1-1));
  WriteDSP(Hi(playbufsize shr 1-1));
  WriteDSP($1C) {???? I don't know why, but it is necessary }
end;

procedure mix;
{ Main procedure - mixes samples with appropriate frequencies and
  puts mixed signal into play buffer. If it's too slow for your
  computer, don't blame me - but translate procedure into assembler
  (or buy something faster :-) }
var
  i,j : integer;
  nvoice,sw  : word;
  pombuf : ^sampledata;
begin
{ Pointer to play buffer - is it first, or second part? }
  if firstbuff then pombuf:=@sampledata(playbuf^)[playbufsize div 2]
               else pombuf:=playbuf;
  for i:=0 to playbufsize div 2-1 do
  begin
    sw:=0;
    for j:=1 to max_num_channels do
      if channelsactive[j] then
      begin
        nvoice:=channelsnvoice[j];
{ That's mixing - without interpolation. }
        inc(sw, voicesdata[nvoice]^[channelsposition[j]] * channelsvol[j]);
{ Here is the most important thing - next two lines (excluding
  remarks:) are responsible for output frequency of sample.  }
        inc(channelssubposition[j],channelsincrement[j]);
{ That's a nasty trick - but it works. You can do it other ways,
  in Pascal, Assembler and so on. }
        if carry then
        begin
          inc(channelsposition[j]);
{ Now work with looped samples. }
          if channelsinloop[j] then
            if channelsposition[j] > voicesloopend[nvoice] then
                   channelsposition[j] := voicesloopstart[nvoice];
{ Maybe we should stop playing this sample? Or put it in a loop mode? }
          if channelsposition[j] > voicessize[nvoice] then
            if voicesloopstart[nvoice]<>0 then
            begin
              channelsposition[j] := voicesloopstart[nvoice];
              channelsinloop[j]:=true
            end
            else channelsactive[j]:=false;
        end;
      end;
    pombuf^[i]:=Lo(sw shr 6);
  end;
end;

procedure inthandler;
interrupt;
var
  w : word;
begin
  w:=Port[DSP_DATA_AVAIL];
  port[$20]:=$20;
  firstbuff:=not firstbuff;
  mix;
end;

procedure enableIRQ(n : byte);
begin
  port[$21]:=port[$21] and not (1 shl n)
end;

procedure disableIRQ(n : byte);
begin
  port[$21]:=port[$21] or (1 shl n)
end;

procedure allocmem(var p : pointer);
var
  adr : longint;
begin
{ Allocates memory not crossing page boundary ($X0000) }
  repeat
    getmem(p,playbufsize);
    adr:=longint(Seg(p^)) Shl 4 + Ofs(p^);
  until (adr and $FFFF)<$FFFF-playbufsize
end;

{$F+ }
procedure MixerExit;
begin
  ExitProc:=OldExit;
  WriteDSP($D0); { ??? }
  speakeroff;
  disableIRQ(SBIRQ);
  setintvec(8+SBIRQ,oldint);
  ResetDSP(SBIO);
end;
{$F- }

procedure initplayloop;
begin
  if not ResetDSP(SBIO) then HALT;
  allocmem(playbuf);
  getintvec(8+SBIRQ,oldint);
  setintvec(8+SBIRQ,@inthandler);
  enableIRQ(SBIRQ);
  speakeron;
  timeconst:=256-1000000 div PlayFreq;
  fillchar(playbuf^,playbufsize,#0);
  playback;
  OldExit:=ExitProc;
  ExitProc:=@MixerExit
end;

procedure addvoice(voice,_samplesize,_loopstart,_loopend : word;
                   sample : pointer);
begin
  voicesdata[voice]:=sample;
  voicessize[voice]:=_samplesize;
  voicesloopstart[voice]:=_loopstart;
  voicesloopend[voice]:=_loopend;
  voicesdefined[voice]:=true
end;

procedure startchannel(channel,voice,volume,frequency : word);
begin
  asm cli end;
  if not channelsactive[channel] then channelsactive[channel]:=true;
  channelsinloop[channel]:=false;
  channelsnvoice[channel]:=voice;
  channelsincrement[channel]:=(longint(frequency) shl 16-1) div PlayFreq;
  if (volume>=0) and (volume<=16) then channelsvol[channel]:=volume
                                  else channelsvol[channel]:=16;
  channelssubposition[channel]:=0;
  channelsposition[channel]:=0;
  asm sti end;
end;

procedure stopchannel(channel : word);
begin
  channelsactive[channel]:=false;
  channelsinloop[channel]:=false
end;

procedure setchannelfrequency(channel,frequency : word);
begin
  asm cli end;
  channelsincrement[channel]:=(longint(frequency) shl 16-1) div PlayFreq;
  asm sti end;
end;

procedure setchannelvolume(channel,volume : word);
begin
  asm cli end;  {}
  if (volume>=0) and (volume<=16) then channelsvol[channel]:=volume;
  asm sti end;  {}
end;

begin
  fillchar(voicesdata,sizeof(voicesdata),#0);
  fillchar(voicessize,sizeof(voicessize),#0);
  fillchar(voicesloopstart,sizeof(voicesloopstart),#0);
  fillchar(voicesloopend,sizeof(voicesloopend),#0);
  fillchar(voicesdefined,sizeof(voicesdefined),#0);
  fillchar(channelsnvoice,sizeof(channelsnvoice),#0);
  fillchar(channelsposition,sizeof(channelsposition),#0);
  fillchar(channelsincrement,sizeof(channelsincrement),#0);
  fillchar(channelssubposition,sizeof(channelssubposition),#0);
  fillchar(channelsvol,sizeof(channelsvol),#0);
  fillchar(channelsinloop,sizeof(channelsinloop),#0);
  fillchar(channelsactive,sizeof(channelsactive),#0);
  initplayloop
end.
