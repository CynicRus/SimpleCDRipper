unit uextractor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ComObj, ComCtrls, Windows, JwaWinIoctl, LConvEncoding,
  uwthread, uaudiocd, uaudiocd_helper, ucdtrack, fgl;

type
  TIntList = specialize TFPGList<integer>;

  { TExtractor }

  TExtractor = class(TwThread)
  private
    procedure ExtractTrack(AudioCD: TAudioCD; Index: integer;
      OverallProgress: integer; Filename: string);
    procedure SaveAudioFiles(ListView: TListView; AudioCD: TAudioCD;
      dir: string; CreateSubDir: boolean = True);
  public
    constructor Create(pSplashPanel_: Pointer);
    destructor Destroy; override;
    procedure DoWork; override;

  end;


implementation

uses umain;

{ TExtractor }

procedure TExtractor.ExtractTrack(AudioCD: TAudioCD; Index: integer;
  OverallProgress: integer; Filename: string);
var
  Track: TCDTrack;
  Info: TRAW_READ_INFO;
  sc, l: integer;
  offs: int64;
  Dummy: cardinal;
  pBuffer: PansiChar;
  BufferSize: integer;
  Stream: TFileStream;
  Res: boolean;
begin
  Dummy := 0;
  if (Index > AudioCD.AudioHelper.Tracks.Count) or (AudioCD.AudioHelper.Handle = 0) then
  begin
    //Result := False;
    exit;
  end;

  Track := AudioCD.AudioHelper.Tracks.Items[Index];

  info.Mode := CDDA;
  BufferSize := SECTORS_AT_READ * RAW_SECTOR_SIZE;
  pBuffer := AllocMem(BufferSize);
  l := Track.len;
  TrackProgressMax := l;
  offs := Track.address * 2048;
  Stream := TFileStream.Create(FileName, fmCreate);
  WriteWavHeader(Stream, AudioCD.AudioHelper.GetTrackSize(index));
  try
    while l > 0 do
    begin
      info.DiskOffset := offs;

      if l > SECTORS_AT_READ then
        sc := SECTORS_AT_READ
      else
        sc := l;

      info.SectorCount := sc;
      Res := DeviceIoControl(AudioCD.AudioHelper.Handle, IOCTL_CDROM_RAW_READ,
        @info, SizeOf(info), pBuffer, sc * 2352, @Dummy, nil);
      if not Res then
        RaiseLastOSError;

      Stream.Write(pBuffer^, BufferSize);

      l := l - SECTORS_AT_READ;
      offs := offs + SECTORS_AT_READ * CD_SECTOR_SIZE;
      //Write('Sectors remaining ', c, ' ', #13);
      ShowProgress(TrackProgressMax - l, OverallProgress, 'Extracting....');
    end;

  finally
    FreeMem(pBuffer);
    stream.Free;
  end;

end;

procedure TExtractor.SaveAudioFiles(ListView: TListView; AudioCD: TAudioCD;
  dir: string; CreateSubDir: boolean);

  procedure DeleteStopSymbols(var AText: ansistring);
  const
    cntStopSym: ansistring = '><|?*/\:"';
  var
    i, j: integer;
  begin
    for i := 1 to Length(cntStopSym) do
    begin
      j := Pos(cntStopSym[i], AText);
      Delete(AText, j, 1);
    end;
  end;

var
  Path: string;
  Item: TListItem;
  i, t: integer;
  Tracks: TIntList;
  Title: string;
begin
  if DirectoryExists(Dir) then
  begin
    Path := dir;
    if CreateSubDir then
    begin
      if not DirectoryExists(Path + '\' + CP1251ToUTF8(Ripper.DiscInfo.Performer)) then
        if not CreateDir(Path + '\' + CP1251ToUTF8(Ripper.DiscInfo.Performer)) then
          raise Exception.Create('Failed to create directory: ' +
            Path + '\' + Ripper.DiscInfo.Performer);
      Path := Path + '\' + CP1251ToUTF8(Ripper.DiscInfo.Performer);
      Title := Ripper.DiscInfo.Title;
      DeleteStopSymbols(Title);
      if not DirectoryExists(Path + '\' + CP1251ToUTF8(title)) then
        if not CreateDir(Path + '\' + CP1251ToUTF8(title)) then
          raise Exception.Create('Failed to create directory: ' +
            Path + '\' + Title);
      Path := Path + '\' + CP1251ToUTF8(Title);
    end;
  end
  else
    raise Exception.Create('Directory not exists: ' + dir);
  Tracks := TIntList.Create;
  try
    for i := 0 to ListView.Items.Count - 1 do
    begin
      Item := ListView.Items[i];
      if Item.Checked then
        Tracks.Add(StrToInt(Item.SubItems[0]) - 1);
    end;
    OverallProgressMax := Tracks.Count;
    ShowProgress(-1, -1, 'Extraction....');
    for t := 0 to Tracks.Count - 1 do
    begin
      ExtractTrack(AudioCd, Tracks[t], t + 1, Path + '\' + IntToStr(
        AudioCd.TrackList[Tracks[t]].Number) + '_' + CP1251ToUTF8(AudioCD.DiscInfo.Performer) +
        '_' + CP1251ToUTF8(AudioCd.TrackList[Tracks[t]].Title) + '.wav');
    end;
    ShowProgress(0, OverallProgressMax, 'Extraction done!')
  finally
    Tracks.Free;
  end;

end;

constructor TExtractor.Create(pSplashPanel_: Pointer);
begin
  inherited Create(pSplashPanel_);
end;

destructor TExtractor.Destroy;
begin
  inherited Destroy;
end;

procedure TExtractor.DoWork;
begin
  SaveAudioFiles(MainForm.TrackListView, uMain.Ripper, uMain.Dir, umain.sDir);
end;

end.
