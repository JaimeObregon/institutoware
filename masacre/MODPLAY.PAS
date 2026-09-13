{$A+,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V+,X+,Y+}
{$M 16384,0,655360}

program modplay;

uses mixer,dos,crt;  { see bottom for MIXER code }

{ Program by Borek (Marcin Borkowski), Warsaw, Poland.
  You can find me in a Top Secret BBS, +48 2 6788783
  Fido 2:480/25, Pascal Net 115:4804/104

  This program needs fast machine, as it is written in
  plain vanilla Pascal. If you are looking for proffesional
  quality implementation of MOD player, keep trying
  (I'm sure you'll have to paid for that). If you are looking
  for a source to understand and start work by yourself -
  you've got what you are looking for! You may freely copy
  and use this source, as long as it is unchanged and states my
  name in the begining. If you find more profitable use of this
  code, feel free to share your profits with me! At least - let
  me know you were able to use it for your own purposes.

  This program should be accompanied by the MIXER unit source.

  Attention - this implementation of playing MOD's is BAD
  and will probably not work on some MOD's with changed
  order of playing patterns, also MOD's based on effects
  will not be played properly. Effects (and many other things -
  as sample volumes, finetuning) aren't implemented, and in
  fact that's only a sketch. Program is probably bugged, but
  for sure it plays 40% MOD's from my BBS in an acceptable way.

  Parts of code ripped from PCPGE, various sources from
  Ethan Brodsky and probably from SWAG. I can't remember
  source of every byte, but for sure 95% of code is mine.

  When this code was posted for the first time, I've got some
  stupid questions, here are stupid answers:
  1. Borland Pascal 7.0
  2. Sound Blaster 2.0
  3. Yes, I'm nearly bald. }

const
  TIMERINTR = 8;
  PIT_FREQ  = $1234DD;

type
  sampledata = array[0..65533]of byte;
  pattern    = array[0..63,0..15]of byte;
  patptr     = ^pattern;

var
  BIOSTimerHandler    : procedure;
  clock_ticks,counter : longint;

  playend : boolean;
  ticks,speed : word;
  divplayed : word;
  patplayed : word;
  patterns : array[0..255]of patptr;
  patternorder : array[0..127]of byte;
  fmod    : file;
  hdr     : array[1..1084]of byte;
  nofsamples : word;
  nofpatterns : word;
  OrigTextMode : integer;
  OldExit : pointer;
  timerset : boolean;
  samples : array[1..31]of record
                             sname : string[22];
                             length : word;
                             finet  : byte;
                             volume : byte;
                             repst,repend : word;
                           end;

function amiword(w : word): word;
{ Data in MOD files are usually in 68000 format. }
assembler;
asm
  mov ax,w
  xchg ah,al
end;

procedure nextdivision;
var
{ Sometimes data have to be treated as bytes,
  sometimes as words. Let's use some tricks! }
  divis : array[0..15]of byte;
  diwis : array[0..7]of word absolute divis;
  smp,tmp,freq : word;
  eff,arg : byte;
  i       : integer;
begin
  if divplayed=64 then
  begin
    divplayed:=0;
    inc(patplayed);
  end;
  if patplayed>=hdr[951] then
  begin
    playend:=true;
    EXIT
  end;

  gotoxy(1,43);
  write('Pattern: ',patplayed+1:2,'/',hdr[951],
        '    division: ',divplayed:2);
  move(patterns[patternorder[patplayed]]^[divplayed,0],divis,16);

  for i:=0 to 3 do
  begin
    smp:=(divis[4*i+0] and $F0)+divis[4*i+2] shr 4;  {sample number}
    tmp:=(amiword(diwis[2*i]) and $0FFF);      {sample period}
    if tmp<>0 then freq:=3546895 div tmp;
    if smp<>0 then startchannel(i+1,smp,64,freq)
              else if tmp<>0 then setchannelfrequency(i+1,freq);

    gotoxy(1,45+i);
    write(' channel ',i,': (',smp:2,') ',samples[smp].sname:22);
    if tmp<>0 then write(' Hz: ',freq:5,' ':25)
              else write(' Hz: ',' ':30);
    gotoxy(53,45+i);

    eff:=divis[4*i+2] and $0F;                 {effect number}
    arg:=divis[4*i+3];                         {effect argument}
    case eff of
      $0C : begin
              setchannelvolume(i+1,arg);
              write('volume change       ');
            end;
      $0F : if arg<>0 then
            begin
              speed:=arg;
              write('speed change        ');
            end;
      $0B : begin
              divplayed:=63;
              patplayed:=arg-1;
              write('pattern break       ');
            end;
      $0D : begin
              inc(patplayed);
              divplayed:=10*(arg shr 4)+arg and $0F-1;
              write('pattern jump        ');
            end;
      else if eff<>0 then
              write('unimplemented effect');
    end;
  end;
  inc(divplayed);
end;

procedure play;
interrupt;
begin
  inc(ticks);
  if ticks=speed then
  begin
    ticks:=0;
    nextdivision;
  end;
  clock_ticks := clock_ticks + counter;
  if clock_ticks >= $10000 then
    begin
      clock_ticks := clock_ticks - $10000;
      asm pushf end;
      BIOSTimerHandler;
    end
  else Port[$20] := $20;
end;

procedure CleanUpTimer;
begin
  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;
  SetIntVec(TIMERINTR, @BIOSTimerHandler);
end;

procedure SetTimer(TimerHandler : pointer; frequency : word);
begin
  clock_ticks := 0;
  counter := $1234DD div frequency;
  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, TimerHandler);
  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;
  timerset:=true
end;

{$F+}
procedure shutdown;
begin
  if timerset then CleanUpTimer;
  exitproc:=oldexit
end;
{$F-}

procedure error(s : string);
begin
  textmode(OrigTextMode);
  writeln(s);
  close(fmod);
  HALT
end;

procedure openmod;
var
  s : string;
begin
  if paramcount=0 then error('Needs filename (*.mod) as parameter');
  assign(fmod,paramstr(1));
  reset(fmod,1);
  if IOResult<>0 then error('Can''t open file: '+paramstr(1));
  blockread(fmod,hdr,1084);
  move(hdr[1081],s[1],4);
  s[0]:=#4;
  if not((s='M.K.') or (s='M!K!') or (s='FLT4') or (s='4CHN')) then
    error('Invalid mod file format tag: '+s);
  nofsamples:=31;
  move(hdr[1],s[1],20);
  s[0]:=#1;
  while s[ord(s[0])]<>#0 do inc(s[0]);
  writeln('Song name: ',s);
  writeln
end;

procedure getsamples;
var
  i : integer;
  s : string;
  w : word;
  totalsamplength : longint;
  p : pointer;
begin
  writeln('Number     Name':20,'Length  Vol    RepSt   RepEnd':48);
  totalsamplength:=0;
  for i:=1 to nofsamples do with samples[i] do
  begin
    move(hdr[21+(i-1)*30],sname[1],21);
    sname[0]:=#1;
    while sname[ord(sname[0])]<>#0 do inc(sname[0]);
    move(hdr[43+30*(i-1)],w,2);    length:=amiword(w) shl 1;
    inc(totalsamplength,length);
    volume:=hdr[46+30*(i-1)];
    move(hdr[47+30*(i-1)],w,2);    repst:=amiword(w) shl 1;
    move(hdr[49+30*(i-1)],w,2);    repend:=repst+amiword(w) shl 1;
    writeln(' sample ',i:2,': ',sname:22,length:11,
            volume:5,repst:8,repend-2:8);
  end;
  nofpatterns:=(filesize(fmod)-1084-totalsamplength) div 1024;
  writeln;
  writeln('Number of different patterns in song: ',nofpatterns);
  seek(fmod,filesize(fmod)-totalsamplength);
  for i:=1 to nofsamples do
    with samples[i] do
      if length>2 then
      begin
        getmem(p,length);
        blockread(fmod,w,2);
        blockread(fmod,p^,length-2);
      { Convert sample to appropriate format. }
        for w:=0 to length-3 do inc(sampledata(p^)[w],128);
        addvoice(i,length-2,repst,repend-2,p)
      end;
  if IOResult<>0 then error('Something went wrong during samples reading.')
end;

procedure getpatterns;
var
  i : integer;
begin
  seek(fmod,1084);
  for i:=0 to nofpatterns-1 do
  begin
    new(patterns[i]);
    blockread(fmod,patterns[i]^,1024)
  end;
  seek(fmod,952);
  blockread(fmod,patternorder,128);
  close(fmod);
end;

procedure startplay;
begin
  speed:=6;
  divplayed:=0;
  patplayed:=0;
  SetTimer(@play,50);
  playend:=false;
end;

begin
  OrigTextMode:=LastMode;
  timerset:=false;
  TextMode(C80+Font8x8);
  clrscr;
  OldExit:=ExitProc;
  ExitProc:=@ShutDown;
  openmod;
  getsamples;
  getpatterns;
  startplay;
  repeat until keypressed or playend;
  textmode(OrigTextMode)
end.
