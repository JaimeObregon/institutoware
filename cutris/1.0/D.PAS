Program d;

uses
 dos, crt;
var
  origen, destino: file;
  a, b : word;

 begin
   assign(origen, 'pausa.vga'); reset(Origen, 1);
   assign(destino, 'pausa2.vga'); rewrite(destino, 1);
   blockread(origen, a, 1); blockwrite(destino, a, 1);
   blockread(origen, a, 1); blockwrite(destino, a, 1);
   blockread(origen, a, 1); blockwrite(destino, a, 1);
   blockread(origen, a, 1); blockwrite(destino, a, 1);
   seek(origen, 4);
   repeat
     blockread(Origen, a, 1);
     inc(a, 48);
     blockwrite(destino, a, 1);
   until filepos(origen)>(filesize(origen)-768);
   for b:=0 to 766 do
    begin
   blockread(origen, a, 1); blockwrite(destino, a, 1);
   end;

   close(origen);
   close(Destino);
 end.
