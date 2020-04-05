unit uaudiocd_helper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, Windows, JwaWinIoctl, FGL, ucdrom_helper, ucdtrack;

const
  RAW_SECTOR_SIZE = 2352;
  CD_SECTOR_SIZE = 2048;
  MAXIMUM_NUMBER_TRACKS = 100;
  SECTORS_AT_READ = 20;
  CD_BLOCKS_PER_SECOND = 75;
  IOCTL_CDROM_RAW_READ = $2403E;
  IOCTL_CDROM_READ_TOC = $24000;
  YellowMode2 = 0;
  XAForm2 = 1;
  CDDA = 2;
  WAVE_FORMAT_PCM = $0001;

type
  TID = array[0..3] of AnsiChar;
  TByteArray = array of byte;
  PByteArr = ^TByteArray;

type
  TAudioCDInfo = record
    Genre: String;
    Performer: String;
    Title: String;
    Year: string;
  end;

  TTRACK_DATA = record
    Reserved: byte;
    Adr_and_Control: byte;
    TrackNumber: byte;
    Reserved1: byte;
    Address: TAddress;
  end;
  PTRACK_DATA = ^TTRACK_DATA;

type
  TCDROM_TOC = record
    Length: word;
    FirstTrack: byte;
    LastTrack: byte;
    TrackData: array[1..MAXIMUM_NUMBER_TRACKS] of TTRACK_DATA;
  end;
  PCDROM_TOC = ^TCDROM_TOC;

  TRAW_READ_INFO = record
    DiskOffset: int64;
    SectorCount: cardinal;
    Mode: cardinal;
  end;

  TWaveHeader = record
    {  RiffHeader  }
    ChunkID: TID;       //  'RIFF'
    ChunkSize: cardinal;  //  4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
    Format: TID;       //  'WAVE'
    {  SubChunk1  }
    SubChunk1ID: TID;       //  'fmt '
    SubChunk1Size: cardinal;  //  PCM 16
    AudioFormat: word;      //  PCM = 1
    NumChannels: word;      //  Mono = 1, Stereo = 2
    SampleRate: cardinal;  //  Bei CD 44100
    ByteRate: cardinal;  //  = SampleRate * NumChannels * BitsPerSample / 8
    BlockAlign: word;      //  = NumChannels * BitsPerSample / 8
    BitsPerSample: word;      //  8 bits = 8, 16 bits = 16
    {  SubChunk2  }
    SubChunk2ID: TID;       //  'data'
    SubChunk2Size: cardinal;  //  = NumChannels * NumChannels * BitsPerSample / 8
  end;


  TTrackList = specialize TFPGList<TCDTrack>;
  TAudioTrackList = specialize TFPGList<TAudioTrack>;
   { TAudioCD_Helper }
  TAudioCD_Helper = class
  private
    FCDHandle: THandle;
    FDriveLockFlag: boolean;
    FTracks: TTrackList;
    FCDToc: TCDROM_TOC;
    function GetTrackCount: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure OpenDrive(ADrive: string);
    procedure FreeDrive();
    function isReady():boolean;
    function GetTrackTable(): boolean;
    function GetTrackTime(Index: integer): cardinal;
    function GetTrackSize(Index: integer): cardinal;
    function EjectDrive():boolean;
    function InjectDrive():boolean;
    //function ReadTrack(Index: integer; Stream: TStream): boolean;
    property TracksCount: integer read GetTrackCount;
    property Tracks: TTrackList read FTracks;
    property Handle: THandle read FCDHandle;
  end;

procedure WriteWavHeader(aFS: TStream; aSize: cardinal);
function AddressToSectors(addr: TAddress): int64;
function SecondToTime(const Seconds: cardinal): double;
function FormatByteSize(const bytes: Longint): string;

implementation

procedure WriteWavHeader(aFS: TStream; aSize: cardinal);
var
  Wave: TWaveHeader;
begin
  aFS.Seek(0, soFromBeginning);
  Wave.ChunkID := 'RIFF';
  Wave.ChunkSize := aSize + SizeOf(Wave.ChunkID) + SizeOf(Wave.ChunkSize);
  Wave.Format := 'WAVE';
  Wave.SubChunk1ID := 'fmt ';
  Wave.SubChunk1Size := 16;
  Wave.AudioFormat := WAVE_FORMAT_PCM;
  Wave.NumChannels := 2;
  Wave.SampleRate := 44100;
  Wave.ByteRate := 44100 * 2 * 2;
  Wave.BlockAlign := 2 * 16 div 8;
  Wave.BitsPerSample := 16;
  Wave.SubChunk2ID := 'data';
  Wave.SubChunk2Size := aSize;
  aFS.Write(Wave, SizeOf(TWaveHeader));
end;

function AddressToSectors(addr: TAddress): int64;
begin
  Result := addr[1] * 75 * 60 + addr[2] * 75 + addr[3] - 150;
end;

function SecondToTime(const Seconds: cardinal): double;
const
  SecPerDay = 86400;
  SecPerHour = 3600;
  SecPerMinute = 60;
var
  ms, ss, mm, hh, dd: cardinal;
begin
  dd := Seconds div SecPerDay;
  hh := (Seconds mod SecPerDay) div SecPerHour;
  mm := ((Seconds mod SecPerDay) mod SecPerHour) div SecPerMinute;
  ss := ((Seconds mod SecPerDay) mod SecPerHour) mod SecPerMinute;
  ms := 0;
  Result := dd + EncodeTime(hh, mm, ss, ms);
end;

function FormatByteSize(const bytes: Longint): string;
const
  B = 1; // byte
  KB = 1024 * B; // kilobyte
  MB = 1024 * KB; // megabyte
  GB = 1024 * MB; // gigabyte
begin
  if bytes > GB then
    result := FormatFloat('#.## GB', bytes / GB)
  else if bytes > MB then
    result := FormatFloat('#.## MB', bytes / MB)
  else if bytes > KB then
    result := FormatFloat('#.## KB', bytes / KB)
  else
    result := FormatFloat('#.## bytes', bytes);
end;

{ TAudioCD_Helper }

function TAudioCD_Helper.GetTrackCount: integer;
begin
  Result := ftracks.Count;
end;


constructor TAudioCD_Helper.Create;
begin
  FCDHAndle := 0;
  FDriveLockFlag := False;
  FTracks := TTrackList.Create;
end;

destructor TAudioCD_Helper.Destroy;
begin
  FreeDrive();
  FTracks.Free;
  inherited Destroy;
end;

procedure TAudioCD_Helper.OpenDrive(ADrive: string);
var
  Flags: cardinal;
  Dummy: cardinal;
begin
  Flags := cardinal(GENERIC_READ);
  ADrive := Upcase('\\.\' + ADrive);
  if FCDHandle > 0 then
    FreeDrive();
  if FTracks.Count > 0 then
    FTracks.Clear;
  FCDHAndle := CreateFileA(PChar(ADrive), Flags, FILE_SHARE_READ,
    nil, OPEN_EXISTING, 0, 0);
  if (FCDHandle = INVALID_HANDLE_VALUE) then
  begin
    ShowMessage(SysErrorMessage(GetLastError));
    exit;
  end;

end;

procedure TAudioCD_Helper.FreeDrive();
begin
  if not FDriveLockFlag then
  begin
    CloseHandle(FCDHandle);
    FCDHandle := 0;
  end;
end;

function TAudioCD_Helper.isReady(): boolean;
begin
 if  (FCDHandle = 0) then
  begin
    Result := False;
    exit;
  end;
 result := TCDRom_Helper.IsDeviceReady(FCDHandle);
end;

function TAudioCD_Helper.GetTrackTable(): boolean;
var
  BytesRead: cardinal;
  i: integer;
  Track: TCDTrack;
begin
  if Tracks.Count > 0 then
   Tracks.Clear;
  FDRiveLockFlag := TCDRom_Helper.LockCD(FCDHandle);
  if not FDriveLockFlag then
  begin
    TCDRom_Helper.UnlockCD(FCDHandle);
    FreeDrive();
    Result := False;
  end;
  BytesRead := 0;
  Result := DeviceIoControl(FCDHandle, IOCTL_CDROM_READ_TOC, nil, 0,
    @FCDToc, SizeOf(TCDROM_TOC), @BytesRead, nil);
  if Result = False then
  begin

    ShowMessage(SysErrorMessage(GetLastError));
    TCDRom_Helper.UnlockCD(FCDHandle);
    FreeDrive();
    exit;
  end;

  for i := FCDToc.FirstTrack to FCDToc.LastTrack do
  begin
    Track.Address := AddressToSectors(FCDToc.TrackData[i].Address);
    Track.Len := AddressToSectors(FCDToc.TrackData[i + 1].Address) - Track.Address;
    FTracks.Add(Track);
  end;

  // if TrackList.

  if FDriveLockFlag then
  begin
    FDriveLockFlag := false;
    TCDRom_Helper.UnlockCD(FCDHandle);
  end;

end;

function TAudioCD_Helper.GetTrackTime(Index: integer): cardinal;
var
  Track: TCDTrack;
begin
  if (Index > FTracks.Count) or (FCDHandle = 0) then
  begin
    Result := 0;
    exit;
  end;

  Track := FTracks.Items[Index];

  Result := round(Track.len / 75);

end;

function TAudioCD_Helper.GetTrackSize(Index: integer): cardinal;
var
  Track: TCDTrack;
begin
  if (Index > FTracks.Count) or (FCDHandle = 0) then
  begin
    Result := 0;
    exit;
  end;

  Track := FTracks.Items[Index];

  Result := Track.len * RAW_SECTOR_SIZE;

end;

function TAudioCD_Helper.EjectDrive(): boolean;
begin
  result := TCDrom_Helper.EjectCD(FCDHandle);
end;

function TAudioCD_Helper.InjectDrive(): boolean;
begin
  result := TCDRom_Helper.InjectCD(FCDHandle);

end;

//function TAudioCD_Helper.ReadTrack(Index: integer; Stream: TStream): boolean;




end.
