unit uaudiocd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, udisc_helper, uaudiocd_helper, ucdtrack;

type

  { TCDRipper }

  TAudioCD = class
    private
      FDrive: string;
      FTrackList: TAudioTrackList;
      FAudioHelper: TAudioCD_Helper;
      FDiscHelper: TDiscHelper;
      FDiscInfo: TAudioCDInfo;
      FUseCDDB: boolean;
      procedure Clear;
    public
      constructor Create();
      destructor Destroy; override;
      function SetDrive(ADrive: string): boolean;
      function IsReady(ADrive: string):boolean;
      property AudioHelper: TAUdioCD_Helper read FAudioHelper;
      property TrackList: TAudioTrackList read FTrackList;
      property DiscInfo: TAudioCDInfo read FDiscInfo;
      property UseCDDB: boolean read FUseCDDB;
  end;

implementation

{ TCDRipper }

procedure TAudioCD.Clear;
begin
  If FTrackList = nil then
   FTrackList := TAudioTrackList.Create
  else
   FTrackList.Clear;
end;

constructor TAudioCD.Create();
begin
  FAudioHelper := TAudioCD_Helper.Create;
  FDiscHelper := TDiscHelper.Create;
  //потом вынести в опции
  FUseCDDB := true;
  Clear;
end;

destructor TAudioCD.Destroy;
begin
  Clear;
  FTrackList.Free;
  FAudioHelper.Free;
  FDiscHelper.Free;
  inherited Destroy;
end;

function TAudioCD.SetDrive(ADrive: string): boolean;
var
  i,count: integer;
  track: TAudioTrack;
begin
  FDrive := ADrive;
  if FTrackList.count > 0 then
   begin
   FTrackList.Clear;
   FAudioHelper.FreeDrive();
   end;
   if FUseCDDB then
    FDiscHelper.SetDisc(ADrive);
  FAudioHelper.OpenDrive(FDrive);
  if FAudioHelper.isReady() then
  begin
    FAudioHelper.GetTrackTable();
    if FUseCDDB then
    begin
      FDiscInfo.Performer:=FDiscHelper.Parser.Disks[0].Performer;
      FDiscInfo.Genre:=FDiscHelper.Genre;
      FDiscInfo.Title:=FDiscHelper.Parser.Disks[0].Title;
      FDiscInfo.Year:=IntToStr(FDiscHelper.Parser.Disks[0].Year);
      count := FAudioHelper.TracksCount;
      for i := 0 to count - 1 do
      begin
        //track.Artist:=;
        track.Number := i + 1;
        track.Artist := DiscInfo.Performer;
        track.Title := FDiscHelper.Parser.Disks[0].Tracks[i].Title;
        track.Duration:=SecondToTime(FAudioHelper.GetTrackTime(i));
        track.Length:=FormatByteSize(FAudioHelper.GetTrackSize(i));
        TrackList.Add(Track);
      end;
    end else
    begin
      FDiscInfo.Performer:='Unknown artist';
      FDiscInfo.Genre:='Unknown';
      FDiscInfo.Title:='Unknown album';
      FDiscInfo.Year:='';
      count := FAudioHelper.TracksCount;
      for i := 0 to count - 1 do
      begin
        //track.Artist:=;
        track.Number := i + 1;
        track.Artist := DiscInfo.Performer;
        track.Title := 'Track ' + IntToStr(i + 1);
        track.Duration:=SecondToTime(FAudioHelper.GetTrackTime(i));
        track.Length:=FormatByteSize(FAudioHelper.GetTrackSize(i));
        TrackList.Add(Track);
      end;
    end;
    result := true;
  end else
  result := false;
end;

function TAudioCD.IsReady(ADrive: string): boolean;
begin
 FAudioHelper.OpenDrive(ADrive);
 result := FAudioHelper.isReady();
 FAudioHelper.FreeDrive();
end;

end.

