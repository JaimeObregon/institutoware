Program CUATRO_EN_RAYA;
                                                                              {
******************************************************************************

 Primer...
 ������������� �����������  �����������  ����� �����  ����������� �����������
    �����     ����� �����  ����� �����  ������۱���  �����       ����� �����
   �����     ����� �����  ���������    ����۲�۲��  �������     ����� �����
  �����     ����� �����  ����۰����   ����۱�����  �����       ����� �����
 �����     �����������  ����۰����   ����� �����  ����������� �����������
                                                          ...de programacion.

   ��� ��� �   ���    ��� ��� ��� ��� ��� ��� � � ��� ��  ��� ��� ��� ���
   �   � � �   � �    � � � � � � �   � � � � ��� � � � � � � � � �   �
   ��� � � �   � �    ��� ��  � � � � ��  ��� ��� ��� � � � � ��  ��  ���
     � � � �   � �    �   � � � � � � � � � � � � � � � � � � � � �     �
   ��� ��� ��� ���    �   � � ��� ��� � � � � � � � � ��  ��� � � ��� ���

******************************************************************************
                                                                              }

Uses
  Dos, Crt;

Label
  1;

Const
  Tiempo         = 24.7824758; {El equivalente a 12 segundos en mi ordenador}

Var
  No             : Byte;          { N� de jugadas }
  Tablero        : Text;          { Fichero del tablero }
  Datos          : Text;          { Mi fichero de datos }
  Caracter       : Char;
  Vacio          : Boolean;       { Indica si el tablero esta vacio }
  Jugador        : Byte;          { El numero de pieza que le toca }
  Enemigo        : Byte;          { El numero de pieza de su adversario }
  Fichas         : Byte;          { Numero de fichas (unos y doses) }
  X, Y           : ShortInt;   
  H, M, S, D     : Word;          { Para medir las diferencias de velocidad. }
  P1, P2, P3, P4 : Integer;       { Su funcion es orientativa }
  Piezas         : Array[-5..12, -5..11] Of Byte;
 { ** Es extra�o que en el array en que van a estar contenidas las posiciones
      de las piezas (que teoricamente son 7 x 6 = 42 aparezcan numeros ne-
      gativos, y en consecuencia, mas piezas.
      Esto es asi, porque las posibilidades de hacer cuatro en raya en el
      centro del tablero, son mayores que las posibilidades de hacer cuatro
      en raya en las esquinas. (Por ejemplo: en la esquina superior izquier-
      da, no se puede hacer cuatro en raya de derecha a izquierda, pero en
      el centro s�. He a�adido, por problemas internos, cinco casillas m�s
      a cada lado. Por supuesto, esto no interfiere en el modo de juego.
      Si no las hubiera a�adido, el compilador devolveria en la mayoria de
      las jugadas el Runtime Error #201, "Range check error." ** }

                                                                              {
������������������������������������������������������������������������������
��             AQUI COMIENZAN LAS FUNCIONES Y PROCEDIMIENTOS.               ��
������������������������������������������������������������������������������
                                                                              }

Procedure Salir; { Devuelve el control al sistema operativo cuando ha movido }
  Begin
    { ** En estas lineas es donde el ordenador detecta si le van a ganar en
         la siguiente jugada.
         Si su ultimo movimiento va a hacer que su adversario gane, le desace
         antes de grabarle en el fichero y busca otro.
         De lo contrario, graba su movimiento en el fichero y vuelve al
         DOS.
         Para averiguarlo, busca tres piezas juntas del adversario, que en la
         siguiente jugada puedan hacer 4 en raya.
         ** }

    { ** Graba su movimiento en el fichero ** }
    X:=1; Y:=1;
    ReWrite(Tablero);
    Repeat
      If Piezas[X,Y]=0 Then Write(Tablero, #0);
      If Piezas[X,Y]=1 Then Write(Tablero, #1);
      If Piezas[X,Y]=2 Then Write(Tablero, #2);
      X:=X+1;
      If X=8 Then
        Begin
          X:=1; Y:=Y+1;
        End;
    Until(Y=7);
    Close(Tablero);
    If No>42 Then
      Begin
        Halt;
      End;
    Halt; 
  End;

Procedure Busca_Tres_Fichas_Mias_Seguidas;
  Begin
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-DERECHA si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Jugador;
             If Piezas[X+1,Y+1]=Jugador Then
               Begin
                 P2:=Jugador;
                 If Piezas[X+2,Y+2]=Jugador Then
                   Begin
                     P3:=Jugador;
                     If (X+3<8) And (Y+3<7) Then  { ** Pone mi ficha abajo-der.    }
                       Begin
                         If (Piezas[X+3,Y+4]<>0) Or (Y+4=6) Then
                           Begin
                             If Piezas[X+3,Y+3]=0 Then
                               Begin
                                 Piezas[X+3,Y+3]:=Jugador; Salir;
                               End;
                           End;
                       End;
                     If (X-1>0) And (Y-1>0) Then  { ** Pone mi ficha arriba-izq.   }
                       Begin
                         If (Piezas[X-1,Y]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X-1,Y-1]=0 Then
                               Begin
                                 Piezas[X-1,Y-1]:=Jugador; Salir;
                               End;
                           End;
                       End;
                   End;
               End;
           End;
       X:=X+1;
       If X=8 Then
          Begin
            X:=1; Y:=Y+1;
          End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-IZQ si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Jugador;
             If Piezas[X-1,Y+1]=Jugador Then
               Begin
                 P2:=Jugador;
                 If Piezas[X-2,Y+2]=Jugador Then
                   Begin
                     P3:=Jugador;
                     If (X-3>0) And (Y+3<7) Then  { ** Pone mi ficha abajo-izq.    }
                       Begin
                         If (Piezas[X-3,Y+4]<>0) Or (Y+3=6) Then
                           Begin
                             If Piezas[X-3,Y+3]=0 Then
                               Begin
                                 Piezas[X-3,Y+3]:=Jugador; Salir;
                               End;
                           End;
                       End;
                     If (X+1<8) And (Y-1>0) Then  { ** Pone mi ficha arriba-der.   }
                       Begin
                         If (Piezas[X+1,Y]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X+1,Y-1]=0 Then
                               Begin
                                 Piezas[X+1,Y-1]:=Jugador; Salir;
                               End;
                           End;
                       End;
                   End;
               End;
           End;
       X:=X+1;
       If X=8 Then
         Begin
           X:=1; Y:=Y+1;
         End;
     Until(Y=7);
       { ** Busca una combinacion de dos o tres piezas iguales
            HORIZONTALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Jugador;
             If Piezas[X+1,Y]=Jugador Then
               Begin
                 P2:=Jugador;
                 If Piezas[X+2,Y]=Jugador Then
                   Begin
                     P3:=Jugador;
                     If (X+3<8) Then  { ** Pone mi ficha a la dcha. ** }
                       Begin
                         If (Piezas[X+3,Y+1]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X+3,Y]=0 Then
                               Begin
                                 Piezas[X+3,Y]:=Jugador; Salir;
                               End;
                           End;
                       End;
                     If (X-1>0) And (X>0) Then  { ** Pone mi ficha a la izq. ** }
                       Begin
                         If (Piezas[X-1,Y+1]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X-1,Y]=0 Then
                               Begin
                                 Piezas[X-1,Y]:=Jugador; Salir;
                               End;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);

{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            VERTICALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Jugador;
             If Piezas[X,Y+1]=Jugador Then
               Begin
                 P2:=Jugador;
                 If Piezas[X,Y+2]=Jugador Then
                   Begin
                     P3:=Jugador;
                     If (Y-1>0) Then  { ** Pone mi ficha arriba. ** }
                       Begin
                         If Piezas[X,Y-1]=0 Then
                           Begin
                             Piezas[X,Y-1]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
           X:=X+1;
           If X=8 Then
             Begin
               X:=1; Y:=Y+1;
             End;
         Until(Y=7);
{ ************************************************************************** }
  End;

Procedure Busca_Tres_Fichas_Suyas_Seguidas;
  Begin
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-DERECHA si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X+1,Y+1]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If Piezas[X+2,Y+2]=Enemigo Then
                   Begin
                     P3:=Enemigo;
                     If (X+3<8) And (Y+3<7) Then  { ** Pone mi ficha abajo-der.    }
                       Begin
                         If (Piezas[X+3,Y+4]<>0) Or (Y+4=6) Then
                           Begin
                             If Piezas[X+3,Y+3]=0 Then
                               Begin
                                 Piezas[X+3,Y+3]:=Jugador; Salir;
                               End;
                           End;
                       End;
                     If (X-1>0) And (Y-1>0) Then  { ** Pone mi ficha arriba-izq.   }
                       Begin
                         If (Piezas[X-1,Y]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X-1,Y-1]=0 Then
                               Begin
                                 Piezas[X-1,Y-1]:=Jugador; Salir;
                               End;
                           End;
                       End;
                   End;
               End;
           End;
       X:=X+1;
       If X=8 Then
          Begin
            X:=1; Y:=Y+1;
          End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-IZQ si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X-1,Y+1]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If Piezas[X-2,Y+2]=Enemigo Then
                   Begin
                     P3:=Enemigo;
                     If (X-3>0) And (Y+3<7) Then  { ** Pone mi ficha abajo-izq.    }
                       Begin
                         If (Piezas[X-3,Y+4]<>0) Or (Y+3=6) Then
                           Begin
                             If Piezas[X-3,Y+3]=0 Then
                               Begin
                                 Piezas[X-3,Y+3]:=Jugador; Salir;
                               End;
                           End;
                       End;
                     If (X+1<8) And (Y-1>0) Then  { ** Pone mi ficha arriba-der.   }
                       Begin
                         If (Piezas[X+1,Y]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X+1,Y-1]=0 Then
                               Begin
                                 Piezas[X+1,Y-1]:=Jugador; Salir;
                               End;
                           End;
                       End;
                   End;
               End;
           End;
       X:=X+1;
       If X=8 Then
         Begin
           X:=1; Y:=Y+1;
         End;
     Until(Y=7);
       { ** Busca una combinacion de dos o tres piezas iguales
            HORIZONTALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X+1,Y]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If Piezas[X+2,Y]=Enemigo Then
                   Begin
                     P3:=Enemigo;
                     If (X+3<8) Then  { ** Pone mi ficha a la dcha. ** }
                       Begin
                         If (Piezas[X+3,Y+1]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X+3,Y]=0 Then
                               Begin
                                 Piezas[X+3,Y]:=Jugador; Salir;
                               End;
                           End;
                       End;
                     If (X-1>0) And (X>0) Then  { ** Pone mi ficha a la izq. ** }
                       Begin
                         If (Piezas[X-1,Y+1]<>0) Or (Y=6) Then
                           Begin
                             If Piezas[X-1,Y]=0 Then
                               Begin
                                 Piezas[X-1,Y]:=Jugador; Salir;
                               End;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            VERTICALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X,Y+1]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If Piezas[X,Y+2]=Enemigo Then
                   Begin
                     P3:=Enemigo;
                     If (Y-1>0) Then  { ** Pone mi ficha arriba. ** }
                       Begin
                         If Piezas[X,Y-1]=0 Then
                           Begin
                             Piezas[X,Y-1]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
           X:=X+1;
           If X=8 Then
             Begin
               X:=1; Y:=Y+1;
             End;
         Until(Y=7);
{ ************************************************************************** }
  End;

Procedure Busca_Dos_Fichas_Suyas_Seguidas;
  Begin
       { ** Busca una combinacion de dos o tres piezas iguales
            HORIZONTALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X+1,Y]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If (X+2<8) Then  { ** Pone mi ficha a la dcha. ** }
                   Begin
                     If (Piezas[X+2,Y+1]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X+2,Y]=0 Then
                           Begin
                             Piezas[X+2,Y]:=Jugador; Salir;
                           End;
                       End;
                   End;
                 If (X-1>0) And (X>0) Then  { ** Pone mi ficha a la izq. ** }
                   Begin
                     If (Piezas[X-1,Y+1]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X-1,Y]=0 Then
                           Begin
                             Piezas[X-1,Y]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            VERTICALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X,Y+1]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If (Y-1>0) Then  { ** Pone mi ficha arriba. ** }
                   Begin
                     If Piezas[X,Y-1]=0 Then
                       Begin
                         Piezas[X,Y-1]:=Jugador; Salir;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-DERECHA si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X+1,Y+1]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If (X+2<8) And (Y+2<7) Then  { ** Pone mi ficha abajo-der.    }
                   Begin
                     If (Piezas[X+2,Y+3]<>0) Or (Y+3=6) Then
                       Begin
                         If Piezas[X+2,Y+2]=0 Then
                           Begin
                             Piezas[X+2,Y+2]:=Jugador; Salir;
                           End;
                       End;
                   End;
                 If (X-1>0) And (Y-1>0) Then  { ** Pone mi ficha arriba-izq.   }
                   Begin
                     If (Piezas[X-1,Y]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X-1,Y-1]=0 Then
                           Begin
                             Piezas[X-1,Y-1]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-IZQ si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Enemigo Then
           Begin
             P1:=Enemigo;
             If Piezas[X-1,Y+1]=Enemigo Then
               Begin
                 P2:=Enemigo;
                 If (X-2>0) And (Y+2<7) Then  { ** Pone mi ficha abajo-izq.    }
                   Begin
                     If (Piezas[X-2,Y+3]<>0) Or (Y+2=6) Then
                       Begin
                         If Piezas[X-2,Y+2]=0 Then
                           Begin
                             Piezas[X-2,Y+2]:=Jugador; Salir;
                           End;
                       End;
                   End;
                 If (X+1<8) And (Y-1>0) Then  { ** Pone mi ficha arriba-der.   }
                   Begin
                     If (Piezas[X+1,Y]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X+1,Y-1]=0 Then
                           Begin
                             Piezas[X+1,Y-1]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
  End;

Procedure Busca_Dos_Fichas_Mias_Seguidas;
  Begin
       { ** Busca una combinacion de dos o tres piezas iguales
            HORIZONTALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Enemigo;
             If Piezas[X+1,Y]=Jugador Then
               Begin
                 P2:=Enemigo;
                 If X+2<8 Then  { ** Pone mi ficha a la dcha. ** }
                   Begin
                     If (Piezas[X+2,Y+1]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X+2,Y]=0 Then
                           Begin
                             Piezas[X+2,Y]:=Jugador; Salir;
                           End;
                       End;
                   End;
                 If (X-1>0) And (X>0) Then  { ** Pone mi ficha a la izq. ** }
                   Begin
                     If (Piezas[X-1,Y+1]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X-1,Y]=0 Then
                           Begin
                             Piezas[X-1,Y]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            VERTICALMENTE si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Enemigo;
             If Piezas[X,Y+1]=Jugador Then
               Begin
                 P2:=Enemigo;
                 If (Y-1>0) Then  { ** Pone mi ficha arriba. ** }
                   Begin
                     If Piezas[X,Y-1]=0 Then
                       Begin
                         Piezas[X,Y-1]:=Jugador; Salir;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }

       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-DERECHA si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Enemigo;
             If Piezas[X+1,Y+1]=Jugador Then
               Begin
                 P2:=Enemigo;
                 If (X+2<8) And (Y+2<7) Then  { ** Pone mi ficha abajo-der.    }
                   Begin
                     If (Piezas[X+2,Y+3]<>0) Or (Y+3=6) Then
                       Begin
                         If Piezas[X+2,Y+2]=0 Then
                           Begin
                             Piezas[X+2,Y+2]:=Jugador; Salir;
                           End;
                       End;
                   End;
                 If (X-1>0) And (Y-1>0) Then  { ** Pone mi ficha arriba-izq.   }
                   Begin
                     If (Piezas[X-1,Y]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X-1,Y-1]=0 Then
                           Begin
                             Piezas[X-1,Y-1]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
{ ************************************************************************** }
       { ** Busca una combinacion de dos o tres piezas iguales
            DIAGONALMENTE-IZQ si la encuentra, pone una ficha de mi color
            acontinuacion. Asi, si eran suyas, le chafa la jugada. Y si eran
            mias, me favorece. }
       X:=1; Y:=1;
       Repeat
         P1:=0; P2:=0; P3:=0; P4:=0;
         If Piezas[X,Y]=Jugador Then
           Begin
             P1:=Enemigo;
             If Piezas[X-1,Y+1]=Jugador Then
               Begin
                 P2:=Enemigo;
                 If (X-2>0) And (Y+2<7) Then  { ** Pone mi ficha abajo-izq.    }
                   Begin
                     If (Piezas[X-2,Y+3]<>0) Or (Y+2=6) Then
                       Begin
                         If Piezas[X-2,Y+2]=0 Then
                           Begin
                             Piezas[X-2,Y+2]:=Jugador; Salir;
                           End;
                       End;
                   End;
                 If (X+1<8) And (Y-1>0) Then  { ** Pone mi ficha arriba-der.   }
                   Begin
                     If (Piezas[X+1,Y]<>0) Or (Y=6) Then
                       Begin
                         If Piezas[X+1,Y-1]=0 Then
                           Begin
                             Piezas[X+1,Y-1]:=Jugador; Salir;
                           End;
                       End;
                   End;
               End;
           End;
         X:=X+1;
         If X=8 Then
           Begin
             X:=1; Y:=Y+1;
           End;
       Until(Y=7);
  End;

                                                                              {
������������������������������������������������������������������������������
��               AQUI ACABAN LAS FUNCIONES Y PROCEDIMIENTOS.                ��
������������������������������������������������������������������������������


  ������������������������������������������������������������������������۳
  ���                                              � Jaime G�mez Obreg�n �۳
  ���  Version 3.5. 03/02/1995                     � Apartado de Correos �۳
  ���  Escrito por Jaime G�mez Obreg�n.            � 199 de Santander.   �۳
  ���  Desarrollado exclusivamente para el         � CANTABRIA.          �۳
  ���  I Torneo de Programacion Solo Programadores.� Tlf: (942) 27 58 91 �۳
  ���                                              �����������������������۳
  ���  TODO el codigo de este programa, incluyendo � 12 seg. en el orde- �۳
  ���  los logotipos, comentarios, etc, HAN SIDO   � nador de la SEDE    �۳
  ���  ESCRITOS POR MI.                            � son 24.7824758 seg. �۳
  ���                                              � en mi 386 / DX.     �۳
  ������������������������������������������������������������������������۳
******************************************************************************
{               


  ESQUEMA DEL PROGRAMA EN SU VERSION 1.5:
    ������������������������������������������������������������������Ŀ
    � �Hay 2 o mas piezas DEL ADVERSARIO juntas horizontal,vertical o  �
    � diagonalmente?                                                   �
    ��������������������������������������������������������������������
     ����Ŀ                                                       ����Ŀ
     � SI �                                                       � NO �
     ������                                                       ������
    �����������������������������������������������������������Ŀ     �
    � Pone una pieza a continuacion para estropearle la jugada. �     �
    �������������������������������������������������������������     �
     ����Ŀ                                                           �
     � OK �                                                           �
     ������                                                           �
            �����������������������������������������������������������
    ����������������������������������������������������������������������Ŀ
    � �Hay 2 o mas piezas MIAS juntas horizontal,vertical o diagonalmente? �
    ������������������������������������������������������������������������
     ����Ŀ                                                       ����Ŀ
     � SI �                                                       � NO �
     ������                                                       ������
    ��������������������������������������������������������������Ŀ  �
    � Pone una pieza a continuacion para intentar hacer 4 en raya. �  �
    ����������������������������������������������������������������  �
     ����Ŀ                                                           �
     � OK �                                                           �
     ������                                                           �
            �����������������������������������������������������������
    �����������������������������������Ŀ
    � �Esta la posicion X=4, Y=6 vacia? �
    �������������������������������������
     ����Ŀ                    ����Ŀ
     � SI �                    � NO �
     ������                    ������
         �                         �����Ŀ
    ���������������������������������Ŀ  �
    � Pone una pieza en esa posicion. �  �
    �����������������������������������  �
     ����Ŀ                              �
     � OK �                              �
     ������                              �
                                 �������������������������Ŀ
                                 � Pone una pieza al azar. �
                                 ���������������������������

******************************************************************************

  ESQUEMA DEL PROGRAMA EN SU VERSION 5.0:
    ��������������������������������������������������������������Ŀ
    � �Hay 3 piezas MIAS juntas horizontal, o verticalmente o dia- �
    � gonalmente?                                                  �
    ����������������������������������������������������������������
      �                                                         �
     ����Ŀ                                                    ����Ŀ
     � SI �                                                    � NO �
     ������                                                    ������
    �����������������������������������������������������Ŀ        �
    � Pone una pieza a continuacion para hacer 4 en raya. �        �
    �������������������������������������������������������        �
     �������Ŀ                                                     �
     � GANE! �                                                     �
     ���������                                                     �
                  ����������������������������������������������������Ŀ
                  � �Hay 3 piezas DEL ADVERSARIO juntas diagonalmente? �
                  ������������������������������������������������������
                   ����Ŀ                                          ����Ŀ
                   � SI �                                          � NO �
                   ������                                          ������
    ������������������������������������������������������Ŀ           �
    � Pone una pieza a continuacion estropearle la jugada. �           �
    ��������������������������������������������������������           �
    ������������������������������������������������������Ŀ           �
    � �Puede ahora hacer el adversario 4 en raya en la si- �           �
    � guiente jugada?                                      �           �
    ��������������������������������������������������������           �
     ����Ŀ                                          ����Ŀ
     � SI �                                          � NO �
     ������                                          ������
         �                                               �����Ŀ
    �������������������������������������������������������Ŀ  �
    � Cambia inmediatamente el movimiento y busca uno mejor.�  �
    ���������������������������������������������������������  �
     ����Ŀ                                                    �
     � OK �                                                    �
     ������                                                    �
            ����������������������������������������������������
    �����������������������������������������������������������������Ŀ
    � �Hay 3 piezas DEL ADVERSARIO juntas horizontal o verticalmente? �
    �������������������������������������������������������������������
     ����Ŀ                                                       ����Ŀ
     � SI �                                                       � NO �
     ������                                                       ������
    �����������������������������������������������������������Ŀ     �
    � Pone una pieza a continuacion para estropearle la jugada. �     �
    �������������������������������������������������������������     �
     ����Ŀ                                                           �
     � OK �                                                           �
     ������                                                           �
            �����������������������������������������������������������
    �����������������������������������������������������������������Ŀ
    � �Hay 2 piezas SUYAS juntas horizontal,vertical o diagonalmente? �
    �������������������������������������������������������������������
     ����Ŀ                                                       ����Ŀ
     � SI �                                                       � NO �
     ������                                                       ������
    �����������������������������������������������������������Ŀ     �
    � Pone una pieza a continuacion para estropearle la jugada. �     �
    �������������������������������������������������������������     �
     ����Ŀ                                                           �
     � OK �                                                           �
     ������                                                           �
            �����������������������������������������������������������
    ����������������������������������������������������������������Ŀ
    � �Hay 2 piezas MIAS juntas horizontal,vertical o diagonalmente? �
    ������������������������������������������������������������������
     ����Ŀ                                                      ����Ŀ
     � SI �                                                      � NO �
     ������                                                      ������
    ��������������������������������������������������������������Ŀ �
    � Pone una pieza a continuacion para intentar hacer 4 en raya. � �
    � en futuras jugadas.                                          � �
    ���������������������������������������������������������������� �
     ����Ŀ                                                          �
     � OK �                                                          �
     ������                                                          �
            ����������������������������������������������������������
    ���������������������������������������������������������������������Ŀ
    � �Hay una pieza mia aislada, con posibilidad de hacer cuatro en raya �
    � en futuras jugadas?                                                 �
    �����������������������������������������������������������������������
     ����Ŀ          ����Ŀ
     � SI �          � NO �
     ������          ������
         �               ���������������Ŀ
    �������������������������������Ŀ    �
    � Pone la pieza a continuacion. �    �
    ���������������������������������    �
     ����Ŀ                              �
     � OK �                              �
     ������                              �
            ������������������������������
    �������������������������Ŀ
    � �Esta el tablero vacio? �
    ���������������������������
     ����Ŀ          ����Ŀ
     � SI �          � NO �
     ������          ������
         �               ������������������Ŀ
    ������������������������������������Ŀ  �
    � Pone una pieza en la posicion 6,4. �  �
    ��������������������������������������  �
     ����Ŀ                                 �
     � OK �                                 �
     ������                                 �
                                       �������������������������Ŀ
                                       � Pone una pieza al azar. �
                                       ���������������������������
                                        ����Ŀ
                                        � OK �
                                        ������


  �������������������������������������������������������������������������۳
  ���                                                                     �۳
  ���  HISTORIA DE LAS VERSIONES.                                         �۳
  ���  ==========================                                         �۳
  �������������������������������������������������������������������������۳
  ���  Ver � Fecha    � Descripcion                                       �۳
  �������������������������������������������������������������������������۳
  ���  1.0 � 01/02/95 � Primera version.                                  �۳
  �������������������������������������������������������������������������۳
  ���  1.5 � 02/02/95 � La matriz se vacia un poco mas rapido, con lo que �۳
  ���      �          � ahorramos unas decimas de segundo en cada jugada. �۳
  �������������������������������������������������������������������������۳
  ���  2.0 � 04/02/95 � Mas tacticas. "Piensa" un poco m�s d�nde ha de    �۳
  ���      �          � poner cada ficha. No desperdicia su turno con     �۳
  ���      �          � jugadas estupidas. Cuando hay tres fichas juntas  �۳
  ���      �          � pero estas no pueden hacer 4 en raya, las ignora. �۳
  ���      �          � Ante todo, se defiende, de lo contrario, ataca.   �۳
  �������������������������������������������������������������������������۳
  ���  3.0 � 07/02/95 � Mucho mas control sobre la situacion en la que se �۳
  ���      �          � encuentra. Elimina al minimo el uso del azar, y   �۳
  ���      �          � piensa practicamente todas las jugadas posibles   �۳
  ���      �          � en cada movimiento.                               �۳
  ���      �          � Busca primero una tactica defensiva para la si-   �۳
  ���      �          � tuacion en que se encuentra, si no hay ninguna,   �۳
  ���      �          � usa una tactica ofensiva.                         �۳
  �������������������������������������������������������������������������۳
  ���  3.5 � 09/02/95 � Busca primero las combinaciones de fichas diago-  �۳
  ���      �          � nales, luego las horizontales, y por ultimo las   �۳
  ���      �          � verticales. Esto es asi porque con tres fichas    �۳
  ���      �          � horizontales o diagonales juntas puedes hacer dos �۳
  ���      �          � tipos distintos de 4 en raya, pero con tres fi-   �۳
  ���      �          � chas juntas verticalmente, solo puedes hacer una. �۳
  ���      �          � Ejemplo:                                          �۳
  ���      �          �����������������������������������������������������۳
  ���      �          � � � � � � � � � Aqui, el jugador de "�" puede     �۳
  ���      �          � � � � � � � � � hacer dos 4 en raya, uno de a-    �۳
  ���      �          � x � � � � � � � rriba a abajo, y otro de abajo    �۳
  ���      �          � � x � x � � � � a arriba, ambos diagonalmente.    �۳
  ���      �          � x x x � �   x �                                   �۳
  ���      �          � � x � � � x � �                                   �۳
  �������������������������������������������������������������������������۳
  ���  5.0 � 15/02/95 � Ultima version. Antes de hacer un movimiento,     �۳
  ���      �          � detecta las posibles consecuencias que este puede �۳
  ���      �          � acarrear. Asi, ya no perdera en jugadas como      �۳
  ���      �          � esta:                                             �۳
  ���      �          �����������������������������������������������������۳
  ���      �          � � � � � � � � � El ordenador es "�", y el adver-  �۳
  ���      �          � � � � � � � � � sario "x".                        �۳
  ���      �          � � � � x x � � � Cuando le toca al ordenador,      �۳
  ���      �          � � � � � � x � � tiende a poner su pieza en la     �۳
  ���      �          � � � x x � x � � posicion 3,4, sin darse cuenta de �۳
  ���      �          � � x � � x � x � que el contrincante le ganara en  �۳
  ���      �          ����������������� la siguiente jugada.              �۳
  �������������������������������������������������������������������������۳
  ���                                                                     �۳
  ��� Antes de enviar esta version al concurso, hice un total de 78       �۳
  ��� partidas, de las cuales en 1 gane yo y en 77 me gano el ordenador.  �۳
  ���                                                                     �۳
  �������������������������������������������������������������������������۳

}





























Begin

  Assign(Tablero, 'TABLERO.DAT'); Reset(Tablero);
  Assign(Datos, '12345678.DAT'); ReSet(Datos);
  No:=1; Vacio:=FALSE; Jugador:=1; Fichas:=0;
  FillChar(Piezas,SizeOf(Piezas),0); { ** Pone el array de las piezas a cero.}
  X:=1; Y:=1;
  Repeat
    Read(Tablero, Caracter);
    If Caracter=#0 Then Vacio:=TRUE
    Else
      Begin
        Vacio:=FALSE; Fichas:=Fichas+1;
      End;
    If Caracter=#0 Then Piezas[X,Y]:=0;
    If Caracter=#1 Then
      Begin
        Piezas[X,Y]:=1; No:=No+1
      End;
    If Caracter=#2 Then
      Begin
        Piezas[X,Y]:=2; No:=No+1
      End;
    X:=X+1;
    If X=8 Then
      Begin
        X:=1; Y:=Y+1;
      End;
  Until(Eof(Tablero));
    If No>42 Then
      Begin
        Halt;
      End;

  If Vacio Then Jugador:=1;

  Case Fichas Of
    0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40:
        Begin
          Jugador:=1;
        End
    Else
        Begin
          Jugador:=2;
        End
    End;
  Y:=0;
  Repeat
    Read(Datos, Caracter);
    Y:=Y+1;
  Until(Eof(Datos));
  If Y=1 Then
    Begin
      Close(Datos);
      Rewrite(Datos);
      Write(Datos,Jugador);
      Close(Datos);
    End;
  ReWrite(Tablero);
  X:=1; Y:=1;
                                                                               {
������������������������������������������������������������������������������
    ** Aqui COMIENZA el nucleo del programa, cuando el ordenador "piensa" en
       que casilla ha de poner la pieza **
������������������������������������������������������������������������������
                                                                               }

  If Jugador=1 Then Enemigo:=2;   { ** Descubre el numero del contrincante. }
  If Jugador=2 Then Enemigo:=1;

  Busca_Tres_Fichas_Mias_Seguidas;  
  Busca_Tres_Fichas_Suyas_Seguidas; { ** Los nombres de estos Procedures son }
  Busca_Dos_Fichas_Suyas_Seguidas;  {    los mas largos que he escrito en mi }
  Busca_Dos_Fichas_Mias_Seguidas;   {    vida **                             }

  X:=1; Y:=1;
  Repeat                                           { Busca una pieza mia que }
    If Piezas[X,Y]=Jugador Then                    { tenga posibilidades de  }
      Begin                                        { salir adelante en futu- }
        If Y-3>0 Then                              { ras jugadas.            }
          Begin
            If Y-1=0 Then
              Begin
                Piezas[X,Y-1]:=Jugador; Salir;
              End;
          End;
        If X-3>0 Then
          Begin
            If X-1=0 Then
              Begin
                Piezas[X-1,Y]:=Jugador; Salir;
              End;
          End;
        If X+3<8 Then
          Begin
            If X+1=0 Then
              Begin
                Piezas[X+1,Y]:=Jugador; Salir;
              End;
          End;
      End;
    X:=X+1;
    If X=8 Then
     Begin
       X:=1; Y:=Y+1;
     End;
  Until(Y=7);

  X:=1; Y:=1;
  Vacio:=TRUE; 
  Repeat
    If Piezas[X,Y]<>0 Then  { ** Detecta si el tablero esta vacio. ** }
      Begin
        Vacio:=FALSE;
      End;
    X:=X+1;
    If X=8 Then
     Begin
       X:=1; Y:=Y+1;
     End;
  Until(Y=7);


   If Vacio Then
     If Piezas[4,6]=0 Then
       Begin
         Piezas[4,6]:=Jugador; { ** Esto es un "truco" para comenzar con    }
         Salir;                { ** buen pie. Siempre que puede, coloca una }
       End;                    { ** pieza de mi color en la casilla 4, 6    }

{ ** Mi jugador puede llegar a esta linea del programa por 3 circunstancias:
       - Se encuentra en una situacion en la que no la que no le he "ense�ado"
         que debia hacer. (No encuentra dos fichas iguales alineadas
         horizontal, vertical o diagonalmente).
       - Se han acabado las piezas (se ha rellenado el tablero con 42
         casillas).
       - Se le estan acabando los 12 segundos de tiempo maximo para "pensar".

     En cualquiera de los casos anteriores, elige una casilla al azar. **      }

     1:

     Randomize;
     X:=Random(7)+1;             
     If Piezas[X,6]=0 Then Begin Piezas[X,6]:=Jugador; Salir; End;
     If Piezas[X,5]=0 Then Begin Piezas[X,5]:=Jugador; Salir; End;
     If Piezas[X,4]=0 Then Begin Piezas[X,4]:=Jugador; Salir; End;
     If Piezas[X,3]=0 Then Begin Piezas[X,3]:=Jugador; Salir; End;
     If Piezas[X,2]=0 Then Begin Piezas[X,2]:=Jugador; Salir; End;
     If Piezas[X,1]=0 Then Begin Piezas[X,1]:=Jugador; Salir; End
     Else
       Begin
         Goto 1;
       End;
  { ** El programa NUNCA deberia llegar a esta linea, si lo hace, es una
       de estas dos opciones:
       - Algun malintencionado, (lease "idiota"), a modificado el codigo
         fuente.
       - El ordenador se ha vuelto loco.
    No obstante, si ocurre, se sale del programa como si no pasara nada. }

  Salir;

End.