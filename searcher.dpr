program Searcher;

uses kol, windows;

{$R *.res}

var MainForm, Edit, SBar, ListV: PControl;
    Menu: PMenu;
    ODlg, SDlg: POpenSaveDialog;
    Th: PThread;
    Ini: PIniFile;

    f : file;
    d, d2: array of char;
    load, epos: longint;
    cons, cs, od: boolean;

function  Cconv(K: String): String;
var S: String;
begin
   S := K;
   While Pos( #160, S ) <> 0 Do S[Pos( #160, S )] := #225;
   While Pos( #130, S ) <> 0 Do S[Pos( #130, S )] := #233;
   While Pos( #139, S ) <> 0 Do S[Pos( #139, S )] := #245;
   While Pos( #129, S ) <> 0 Do S[Pos( #129, S )] := #252;
   While Pos( #141, S ) <> 0 Do S[Pos( #141, S )] := #205;
   While Pos( #143, S ) <> 0 Do S[Pos( #143, S )] := #193;
   While Pos( #144, S ) <> 0 Do S[Pos( #144, S )] := #201;
   While Pos( #147, S ) <> 0 Do S[Pos( #147, S )] := #245;
   While Pos( #148, S ) <> 0 Do S[Pos( #148, S )] := #246;
   While Pos( #149, S ) <> 0 Do S[Pos( #149, S )] := #211;
   While Pos( #150, S ) <> 0 Do S[Pos( #150, S )] := #251;
   While Pos( #151, S ) <> 0 Do S[Pos( #151, S )] := #218;
   While Pos( #153, S ) <> 0 Do S[Pos( #153, S )] := #214;
   While Pos( #162, S ) <> 0 Do S[Pos( #162, S )] := #243;
   While Pos( #161, S ) <> 0 Do S[Pos( #161, S )] := #237;
   While Pos( #163, S ) <> 0 Do S[Pos( #163, S )] := #250;
   While Pos( #154, S ) <> 0 Do S[Pos( #154, S )] := #220;
   While Pos( #167, S ) <> 0 Do S[Pos( #167, S )] := #213;
   While Pos( #152, S ) <> 0 Do S[Pos( #152, S )] := #219;
   Result := S;
end;

procedure Exec( Dummy: Pointer; Sender: PThread );
const mz: array[false..true] of byte = (0, 1);
var i, j, k, l: Integer;
    stext, typ, match: string;

    { optimalizált pos függvény }
    function  pose(s: string): integer;
    var i, j: integer;
        k: string;
        okay: boolean;
    begin
      result := 0;
      for i := epos to load do
        if d2[i] = s[1] then
        begin
          k := '';
          okay := true;
          for j := 0 to length(s) - 1 do
              if d2[i+j] <> s[j+1] then begin okay := false; break; end;
          if okay then
            begin
              epos := i;
              result := i;
              exit;
            end;
    end;
    end;

    { optimizált copy függvény }
    function copye(pos1, pos2: longword): string;
    var i: longword;
        s: string;
    begin
      result := '';
      s := '';
      for i := pos1 to pos2 do
        s := s + d[i];
      result := s;
    end;

begin
  cons := menu.ItemChecked[9];
  cs := menu.ItemChecked[10];
  od := menu.ItemChecked[11];
  if cons then ListV.Clear;
  ListV.LVItemAdd( ' --- Starting search --- ' );
  SBar.SimpleStatusText := 'Searching...';
  fillchar(d2[0], load, 0);
  if not cs then stext := LowerCase(Edit.Text)
    else stext := Edit.Text;
  for i := 0 to load do
      d2[i] := chr(ord(d[i]) + 32 * mz[(not cs) and (d[i] in ['A'..'Z'])]);
  epos := 0;

  { keresés }
  repeat
    i := pose(stext);
    if i = 0 then break;
    k := i;
    while d2[i-1] <> #0 do dec(i);
    while d2[k+1] <> #0 do inc(k);
    match := copye(i, k);
    typ := '';
    l := pos('-#', match);
    case match[l+4] of
      'Z': if not od then typ := 'File inside ZIP' else typ := '';
      'R': if not od then typ := 'File inside RAR' else typ := '';
      'A': if not od then typ := 'File inside ARJ' else typ := '';
      'C': if not od then typ := 'File inside ACE' else typ := '';
      'F': if not od then typ := 'Single file' else typ := '';
      'D': if not od then typ := 'Folder';
      '-': typ := copy(match, l + 8, str2int(copy(match, l + 5, 3)));
    end;
    ListV.LVItemAdd( cconv(copy(match, 1, l - 1)) );
    ListV.LVItems[ListV.Count - 1, 1] := copy(match, l + 1, 3);
    ListV.LVItems[ListV.Count - 1, 2] := cconv(typ);
    for j := i to k do
      d2[j] := #0;
  until th.terminated;
  Menu.ItemEnabled[6] := True;
  Menu.ItemEnabled[7] := False;
  ListV.LVItemAdd( ' --- Search completed ---' );
end;

procedure EditChange( Dummy: Pointer; Sender : PControl );
begin
  Edit.Font.Color := clWhite;
  If Pos('/', Edit.Text) <> 0 Then Edit.Font.Color := clPurple;
  If Pos('.', Edit.Text) <> 0 Then Edit.Font.Color := clAqua;
  If (Edit.Text <> '') And (Load <> 0) Then Menu.ItemEnabled[6] := True Else Menu.ItemEnabled[6] := False;
end;

procedure FormClose( Dummy: Pointer; Sender: PControl; var Accept: Boolean );
begin
  Th.Free;
  Accept := True;
end;

procedure FormResize( Dummy: Pointer; Sender: PControl );
begin
  ListV.Width := MainForm.Width - 8;
  ListV.Height := MainForm.Height - 101;
  Edit.Width := MainForm.Width - 8;
end;

procedure MenuExit( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  MainForm.Close;
end;

procedure LoadFile(FName: String);
var E: Integer;
Begin
  SBar.SimpleStatusText := PChar('File open: ' + FName);
  assignfile(f, FName);
  filemode := 0;
  {$I-}
  reset(f, 1);
  {$I+}
  E := IOResult;
  if E <> 0 then begin ListV.LVItemAdd( ' --- Open failed! --- ' ); ListV.LVItems[ListV.LVCount - 1, 1] := Int2Str(E); exit; end;
  Ini := OpenIniFile( Copy(ParamStr(0), 1, Pos('.', ParamStr(0)) - 1) + '.ini');
  With Ini^ Do
  Begin
    Section := 'History';
    Mode := ifmWrite;
    Menu.ItemText[4] := ValueString('Mru1', FName);
    Menu.ItemEnabled[4] := True;
    Free;
  End;
  load := filesize(FName);
  setlength(d, load + 1);
  setlength(d2, load + 1);
  blockread(f, d[0], load);
  ListV.LVItemAdd( ' --- Open complete, loaded ' + Int2Str(load) + ' bytes ---' );
  SBar.SimpleStatusText := PChar('File opened: ' + FName + ' --- ' + Int2Str(Load) + 'bytes load');
  closefile(f);
  EditChange( nil, nil );
End;

procedure MenuOpen( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  If ODlg.Execute Then LoadFile( ODlg.filename );
end;

procedure MenuSave( Dummy: Pointer; Sender : PMenu; Item : Integer );
var i, j: integer;
    g: textfile;
begin
  If SDlg.Execute Then
  Begin
    assignfile(g, SDlg.Filename);
    rewrite(g);
    for j := 0 to ListV.Count - 1 do
    begin
      for i := 0 to ListV.LVColCount do
        write(g, ListV.LVItems[j, i] + #9);
      write(g, #13#10);
    end;
    closefile(g);
  End;
end;

procedure MenuSearch( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  Menu.ItemEnabled[6] := False;
  Menu.ItemEnabled[7] := True;
  Th := NewThread;
  Th.OnExecute := TOnThreadExecute( MakeMethod( nil, @Exec ) );
  Th.Resume;
end;

procedure MenuStop( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  Th.Free;
  ListV.LVItemAdd( ' --- Search terminated ---' );
  SBar.SimpleStatusText := 'End of search thread';
  Menu.ItemEnabled[6] := True;
  Menu.ItemEnabled[7] := False;
end;

procedure MenuClear( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  ListV.Clear;
end;

procedure MenuHist( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  If FileExists( Sender.ItemText[Item] ) Then
  LoadFile( Sender.ItemText[Item] )
  Else MsgOk( 'File doesn''t exist!' );
end;

procedure MenuHistory( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
  Ini := OpenIniFile( Copy(ParamStr(0), 1, Pos('.', ParamStr(0)) - 1) + '.ini');
  With Ini^ Do
  Begin
    Section := 'History';
    Mode := ifmWrite;
    ClearKey( 'Mru1' );
    Free;
  End;
  Menu.ItemEnabled[4] := False;
  Menu.ItemText[4] := '< no recent file >'
end;

procedure MenuAbout( Dummy: Pointer; Sender : PMenu; Item : Integer );
begin
end;

procedure CClick( Dummy: Pointer; Sender: PControl; Idx: Integer );
begin
  ListV.LVSortColumn( Idx );
end;

procedure CC;
begin
  Load := 0;
  MainForm := NewForm( Applet, 'Form' );
  With MainForm^ Do
  Begin
    Caption := 'Searcher';
    Color := clBtnFace;
    Font.Color := clWindowText;
    Font.FontHeight := -11;
    Font.FontName := 'MS Sans Serif';
    Font.FontStyle := [];
    OnClose := TOnEventAccept( MakeMethod( nil, @FormClose ) );
    OnResize := TOnEvent( MakeMethod( nil, @FormResize ) );
    Width := 600;
    Height := 440;
    Left := (GetSystemMetrics(SM_CXFULLSCREEN) - Width) div 2;
    Top := (GetSystemMetrics(SM_CYFULLSCREEN) - Height) div 2;
  End;
  Menu := NewMenuEx( MainForm, 0, [
    '&File',
      '(',
        'O&pen catalog'#9'F3',
        '&Save result as text'#9'F2',
        '-',
        'E&xit'#9'Alt+F4',
        '-',
        '< no recent files >',
      ')',
    '&Options',
      '(',
        'S&tart search'#9'Enter',
        'Stop se&arch'#9'Esc',
        '-',
        '&Clear results'#9'Ctrl+N',
        '+C&lear on new search'#9'Ctrl+C',
        '+Case se&nsitive'#9'Ctrl+K',
        '-Only descriptions'#9'Ctrl+O',
        '-',
        'Clear h&istory list'#9'Ctrl+H',
      ')',
    '&Help',
      '(',
        'A&bout'#9'F1',
      ')'
    ],
    [
     nil,
     TOnMenuitem( MakeMethod( nil, @MenuOpen ) ),
     TOnMenuitem( MakeMethod( nil, @MenuSave ) ),
     TOnMenuitem( MakeMethod( nil, @MenuExit ) ),
     TOnMenuitem( MakeMethod( nil, @MenuHist ) ),
     nil,
     TOnMenuitem( MakeMethod( nil, @MenuSearch ) ),
     TOnMenuitem( MakeMethod( nil, @MenuStop ) ),
     TOnMenuitem( MakeMethod( nil, @MenuClear ) ),
     nil,
     nil,
     nil,
     TOnMenuitem( MakeMethod( nil, @MenuHistory ) ),
     nil,
     TOnMenuitem( MakeMethod( nil, @MenuAbout ) )
    ]  );
  Menu.ItemAccelerator[1]  := MakeAccelerator( FVIRTKEY, VK_F3 );
  Menu.ItemAccelerator[2]  := MakeAccelerator( FVIRTKEY, VK_F2 );
  Menu.ItemAccelerator[6]  := MakeAccelerator( FVIRTKEY, VK_RETURN );
  Menu.ItemAccelerator[7]  := MakeAccelerator( FVIRTKEY, VK_ESCAPE );
  Menu.ItemAccelerator[8]  := MakeAccelerator( FVIRTKEY or FCONTROL, Ord('N') );
  Menu.ItemAccelerator[9]  := MakeAccelerator( FVIRTKEY or FCONTROL, Ord('C') );
  Menu.ItemAccelerator[10]  := MakeAccelerator( FVIRTKEY or FCONTROL, Ord('K') );
  Menu.ItemAccelerator[11] := MakeAccelerator( FVIRTKEY or FCONTROL, Ord('O') );
  Menu.ItemAccelerator[12] := MakeAccelerator( FVIRTKEY or FCONTROL, Ord('H') );
  Menu.ItemAccelerator[14] := MakeAccelerator( FVIRTKEY, VK_F1 );
  Menu.ItemEnabled[6] := False;
  Menu.ItemEnabled[7] := False;
  Menu.ItemEnabled[4] := False;
  ODlg := NewOpenSaveDialog( 'Open catalog', '.', [OSFileMustExist, OSPathMustExist] );
  With ODlg^ Do
  Begin
    DefExtension := 'ACT';
    Filter := 'Alternate Catalog files(*.act)|*.act|All files(*.*)|*.*';
  End;
  SDlg := NewOpenSaveDialog( 'Save result as txt', '.', [OSOverwritePrompt] );
  With SDlg^ Do
  Begin
    OpenDialog := False;
    DefExtension := 'TXT';
    Filter := 'Text files(*.txt)|*.txt|All files(*.*)|*.*';
  End;
  Edit := NewEditBox( MainForm, [] );
  With Edit^ Do
  Begin
    Left := 0;
    Top := 8;
    Width := 293;
    Height := 21;
    Color := 16536660;
    Font.Color := clWhite;
    Font.FontHeight := -11;
    Font.FontName := 'MS Sans Serif';
    Font.FontStyle := [];
    TabOrder := 0;
    Text := '';
    OnChange := TOnEvent( MakeMethod( nil, @EditChange ) );
  End;
  SBar := _NewStatusBar( MainForm );
  ListV := NewListView( MainForm, lvsDetail, [lvoTrackSelect], nil, nil, nil );
  With ListV^ Do
  Begin
    Left := 0;
    Top := 36;
    Width := 541;
    Height := 330;
    TabOrder := 4;
    LVColAdd( 'Filename', taLeft, 200 );
    LVColAdd( 'Disk number', taLeft, 35 );
    LVColAdd( 'Description', taLeft, 200 );
    LVBkColor := 16536660;
    LVTextBkColor := 16536660;
    OnColumnClick := TOnLVColumnClick( MakeMethod( nil, @CClick ) );
  end;
  Ini := OpenIniFile( Copy(ParamStr(0), 1, Pos('.', ParamStr(0)) - 1) + '.ini');
  With Ini^ Do
  Begin
    Section := 'History';
    Mode := ifmRead;
    Menu.ItemText[4] := ValueString('Mru1', '< no recent file >');
    If Menu.ItemText[4] <> '< no recent file >' Then Menu.ItemEnabled[4] := True;
    Free;
  End;
end;

begin
  Applet := NewApplet( 'Searcher' );

  CC;

  Run( Applet );
end.
