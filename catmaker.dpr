{$APPTYPE CONSOLE}
program Catmaker;

uses Crt, windows, kol;

type
   Zip = Record
      Lfhs: LongWord;                  //local file header signature
      Vnte: Word;                      //version needed to extract
      Gpbf: Word;                      //general purpose bit flag
      Cm: Word;                        //compression method
      Lmft: Word;                      //last mod file time
      Lmfd: Word;                      //last mod file date
      Crc32: LongWord;                 //crc-32
      Cs: LongWord;                    //compressed size
      Us: LongWord;                    //uncompressed size
      Fl: Word;                        //filename length
      Efl: Word;                       //extra field length
      Filename: Array[1..200] Of Char; //filename
      Ef: Array[1..200] Of Byte;       //extra field
   End;

   TRarHeader = record
     Pack_Size: LongWord;
     Name_Size: Word;
     Attr: LongWord;
     File_Name: Array[1..512] of Char;
   End;

   Arj = record
     Pack_Size: LongWord;
     File_Name: String;
   End;



Const L: Array[False..True] of String = ('', '0');

var Drive, Ch: Char;
    Dn: String;
    Filename: String;
    DiskNum: Array[1..6] of Char;
    EDnum: Word;
    F: File;
    Z: Zip;
    I, Dfn: Integer;
    D: TextFile;
    Dfs: Array[1..20] Of String;


procedure ProcessZip(Path, Filename: String);
Const Endread = 2048;
Var G: File of Char;
    B: Char;
    P: Array[1..4] of Char;
    MatchPos, Fep, FSize: Longint;
begin
  {$I-}
  MatchPos := 0; Fep := 0;
  AssignFile(G, Path + Filename);
  Reset(G);
  FSize := Filesize( Path + Filename );
  Seek( G, FSize - 22 );
  BlockRead( G, P, 4 );
  If P = 'PK'#5#6 Then MatchPos := FilePos(G) - 4 Else
  Begin
    If FSize > Endread Then
    Seek(G, FSize - Endread)
    Else Seek( G, FSize - 22 );
    Repeat
      BlockRead(G, B, 1);
      If B = 'P' Then
      Begin
        Seek(G, FilePos(G) - 1);
        BlockRead(G, P, 4);
        Seek(G, FilePos(G) - 3);
        If P = 'PK'#5#6 Then MatchPos := FilePos(G) - 1;
      End;
    Until EoF( G ) Or ( FilePos( G ) >= FSize - 4 );
  End;
  If (MatchPos = 0) Or (MatchPos > FSize) Then Exit;
  Seek(G, MatchPos + 16);
  BlockRead(G, Fep, 4);
  Seek(G, Fep);
  Repeat
    BlockRead(G, Z, 46);
    If Z.Lfhs <> $02014B50 Then Break;
    FillChar(Z.Filename, 200, 0);
    BlockRead(G, Z.Filename, Z.Fl);
    BlockRead(G, Z.Ef, Z.Efl);
    DiskNum[5] := 'Z';
    BlockWrite(F, Z.Filename, Z.Fl);
    BlockWrite(F, DiskNum, 6);
  Until EoF(G) or (FSize - Filepos(G) < 46);
  CloseFile(G);
end;

procedure ProcessRar(Path, FileName: String);
var G: File of Byte;
    S: String;
    R: TRarHeader;
begin
  {$I-}
  AssignFile(G, Path + FileName);
  Reset(G);
  FillChar(R, SizeOf(R), 0);
  Seek(G, 27);
  Repeat
    FillChar(R, SizeOf(R), 0);
    BlockRead(G, R.Pack_Size, 4);
    If FileSize(Path + Filename) - FilePos(G) < R.Pack_Size Then Exit;
    Seek(G, FilePos(G) + 15);
    BlockRead(G, R.Name_Size, 6);
    If FileSize(Path + Filename) - FilePos(G) < R.Name_Size Then Exit;
    BlockRead(G, R.File_Name, R.Name_Size);
    S := Copy(R.File_Name, 1, Pos(#0, R.File_Name) - 1);
      DiskNum[5] := 'R';
      BlockWrite(F, R.File_Name, R.Name_Size);
      BlockWrite(F, DiskNum, 6);
    Seek(G, FilePos(G) + R.Pack_Size + 7)
  Until EoF(G);
  CloseFile(G);
end;

procedure ProcessArj(Path, FileName: String);
var
    G: File of Byte;
    I: Word;
    A: Arj;
    C: Char;
begin
  {$I-}
  AssignFile(G, Path + FileName);
  Reset(G);
  BlockRead(G, I, 2);
  If I <> $EA60 Then Exit;
  BlockRead(G, I, 2);
  Seek(G, FilePos(G) + I - 2);
  BlockRead(G, I, 2);
  If I <> 0 Then Exit;
  Seek(G, FilePos(G) + 22);
  Repeat
    FillChar(A, SizeOf(A), 0);
    BlockRead(G, A.Pack_Size, 4);
    Seek(G, FilePos(G) + 14);
    Repeat
      BlockRead(G, C, 1);
      If C <> #00 Then A.File_Name := A.File_Name + C;
    Until C = #00;
      DiskNum[5] := 'A';
      BlockWrite(F, A.File_Name[1], Length(A.File_Name));
      BlockWrite(F, DiskNum, 6);
    Seek(G, Filepos(G) + A.Pack_Size + 23);
  Until Eof(G);
  CloseFile(G);
end;

function Poszero(Pe: String): integer;
var e: integer;
begin
  result := 0;
  e := 1;
  repeat
    if Pe <> '' then
     begin if Pe[e] = #0 then begin result := e; exit; end end
    else exit;
    inc(e);
  until false;
end;

procedure CheckDesc;
var Dft: String;
begin
  Dfn := 0;
  {$I-}
  AssignFile( D, Copy( ParamStr( 0 ), 1, Pos( '.', ParamStr( 0 ) ) ) + 'cfs' );
  Reset( D );
  FillChar( Dfs, SizeOf( Dfs ), 0 );
  While Not Eof( D ) Do        
  Begin
    Inc( Dfn );
    ReadLn( D, Dft );
    If Dft[ 1 ] <> ';'
    Then Dfs[ Dfn ] := Dft
    Else Dec( Dfn );
  End;
  CloseFile( D );
  {$I+}
end;

procedure RunRecurse;
const Z: Array[False..True] Of String = ('', '0');
var Dirs, Files: Array[1..30] of TWin32FindData;
    J, Matched: Integer;
    I: Array[1..30] of Integer;
    Dsc, Dsr: Array[1..2048] of String;

  procedure Recurse;
  var S, Ln, FName: String;
      K, L, Df: Integer;
  begin
    {$I-}

      I[J] := FindFirstFile(PChar('.\*.*'), Dirs[J]);
      Repeat
        If (Dirs[J].dwFileAttributes And $010 > 0) And
           (not StrIn( Dirs[J].cFileName, ['.','..'] )) Then
        Begin
          GetDir(0, S);
          S := S + '\' + Copy(Dirs[J].cFileName, 1, PosZero(Dirs[J].cFileName) - 1);
          Delete(S, 1, 3);
          If S[1] = '\' Then S := Copy(S, 2, Length(S));

          DiskNum[5] := 'D';
          BlockWrite(F, Dirs[J].cFileName, PosZero(Dirs[J].cFileName) - 1);
          BlockWrite(F, DiskNum, 6);
          GotoXY(1, WhereY);
          Write(S);
          For K := Length(S) To 78 Do Write(' ');

          ChDir(Copy(Dirs[J].cFileName, 1, PosZero(Dirs[J].cFileName) - 1));
          Inc(J);
          Recurse;
          ChDir('..');
          Dec(J);
          GetDir(0, S);
          S := S + '\' + Copy(Dirs[J].cFileName, 1, PosZero(Dirs[J].cFileName) - 1);
          Delete(S, 1, 3);
          If S[1] = '\' Then S := Copy(S, 2, Length(S));
        End;
      Until not FindNextFile(I[J], Dirs[J]);

  L := 0;
  For Df := 1 To Dfn Do
  Begin
    If Dfn >= 20 Then
      Begin
        CheckDesc;
        Break;
      End; 
    I[J] := FindFirstFile( PChar( Dfs[ Df ] ), Files[J] );
    If I[J] <> -1 Then
      Begin
        L := 0;
        AssignFile(D, Copy(Files[J].cFileName, 1, PosZero(Files[J].cFileName) - 1));
        Reset(D);
        Repeat
          Inc(L);
          ReadLn(D, Dsc[L]);
          Dsr[L] := LowerCase(Dsc[L]);
        Until EoF(D);
        CloseFile(D);
      End;
  End;

  I[J] := FindFirstFile(PChar('*.*'), Files[J]);
  Repeat
    If Files[J].dwFileAttributes AND FILE_ATTRIBUTE_DIRECTORY = 0 Then
    Begin
      GetDir(0, S);

      Ln := Copy(Files[J].cFileName, 1, PosZero(Files[J].cFileName) - 1);
      Matched := -1;
      For K := 1 To L Do If Pos(LowerCase(Ln), Dsr[K]) = 1 Then Matched := K;

      If Matched <> -1 Then
      Begin
        Delete(Dsc[Matched], 1, Length(Ln));

        Repeat
          If Dsc[Matched] <> '' Then
          Begin If (Dsc[Matched][1] = #32) Or (Dsc[Matched][1] = #09) Then
                   Delete(Dsc[Matched], 1, 1) Else Break End
          Else Break;
        Until False;

        DiskNum[5] := '-';
        BlockWrite(F, Files[J].cFileName, PosZero(Files[J].cFileName) - 1);
        BlockWrite(F, DiskNum, 5);
        Ln := Z[Length(Dsc[Matched]) < 100] + Z[Length(Dsc[Matched]) < 10] + Int2Str(Length(Dsc[Matched]));
        BlockWrite(F, Ln[1], 3);
        BlockWrite(F, Dsc[Matched][1], Length(Dsc[Matched]));
        BlockWrite(F, DiskNum[6], 1);
      End
      Else
      Begin
        DiskNum[5] := 'F';
        BlockWrite(F, Files[J].cFileName, PosZero(Files[J].cFileName) - 1);
        BlockWrite(F, DiskNum, 6);
      End;
      Ln := Copy(Files[J].cFileName, 1, PosZero(Files[J].cFileName) - 1);
      If (Pos('.zip', Ln) = Length(Ln) - 3) And
         (Pos('.zip', Ln) <> 0)  Then
      ProcessZip(S + '\', Ln);
      If (Pos('.rar', Ln) = Length(Ln) - 3) And
         (Pos('.rar', Ln) <> 0)  Then
      ProcessRar(S + '\', Ln);
      If (Pos('.arj', Ln) = Length(Ln) - 3) And
         (Pos('.arj', Ln) <> 0)  Then
      ProcessArj(S + '\', Ln);

    End;
  Until not FindNextFile( I[J], Files[J] );
  End;

begin
  J := 1;
  ChDir(Drive + ':\');
  Recurse;
end;

begin
  EDnum := 1;
  Write('Mi legyen a f jl neve? (ha m r l‚tezik, akkor hozz ¡r) : ');
  ReadLn(Filename);

  AssignFile(F, FileName);
  {$I-}
  If not FileExists(FileName) Then Rewrite(F, 1)
  Else
   Begin
    Reset(F, 1);
    Seek(F, FileSize(FileName));
   End;
  {$I+}
  If IOResult <> 0 Then Begin WriteLn( 'F jl hiba!' ); Halt; End;

  Repeat
    Write('Melyik meghajt¢t szeretn‚d scannelni? (pl. E) : ');
    ReadLn(Drive);

    Repeat
      Write('H nyas sz m£ lesz ez a katal¢gusban (00 - 99)? : ');
      ReadLn(DN);

      EDnum := Str2Int(Dn);
      If (EDnum < 0) Or (EDnum > 99) Then WriteLn( 'A sz mnak 0 ‚s 99 k”z‚ kell esnie!' );
    Until (EDnum > 0) And (EDnum < 99);

    If EDNum < 10 Then Dn := '0' + Int2Str(EDnum) Else Dn := Int2Str(EDnum);
    Inc(EDnum);
    DiskNum[1] := '-';
    DiskNum[2] := '#';
    DiskNum[3] := Dn[1];
    DiskNum[4] := Dn[2];
    DiskNum[6] := #0;
    CheckDesc;
    RunRecurse;
    WriteLn;
    WriteLn('Lemez scannel‚se k‚sz: #' + Dn);
    Ch := ' ';
    Write('Na m‚g egyet? [Y/N] ');
    ReadLn(Ch);
  Until (Ch = 'N') Or (Ch = 'n');


  CloseFile(F);
end.
