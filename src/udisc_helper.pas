unit udisc_helper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Windows, CDROm, discid, fpcddb, httpsend,
  synacode;

type
  TDiscHelper = class(TObject)
  private
    FTOCData: array[0..99] of TTocEntry;
    FDisc: string;
    FDiscID: cardinal;
    fCDHandle: THandle;
    FParser: TCDDBParser;
    FCategory: string;
    function DoCDDBCmd(CMD: string; Response: TStream): boolean;
    function GetDiskContent(ADiscID, ACategory: string; Content: TStream): boolean;

    function GetCategory(AQuery: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function SetDisc(ADrive: string): integer;
    property Parser: TCDDBParser read FParser;
    property Genre: string read FCategory;
  end;


implementation

constructor TDiscHelper.Create();
begin
  FParser := TCDDBParser.Create(nil);
end;

destructor TDiscHelper.Destroy;
begin
  FParser.Free;
  inherited;
end;

function TDiscHelper.SetDisc(ADrive: string): integer;
var
  Tracks, R, i: integer;
  Q, URL: string;
  M: TMemoryStream;
begin
  FDisc:= ADrive;
  ZeroMemory(@FTocData,Length(FTocData));
  Tracks := ReadCDTOC(ADrive, FTocData);
  if (Tracks <= 0) then
  begin
    //ShowMessage(Format(SErrFailedToReadCD, [ADevice]));
    Exit;
  end;
  FDiscID := CDDBDiscID(FTocData, Tracks);
  //If FUseCache and LoadFromCache(TheDiscID) then Exit;
  Q := GetCDDBQueryString(FTocData, Tracks);
  FCategory := GetCategory(Q);
  if (FCategory = '') then
    exit;
  M := TMemoryStream.Create;
  try
    if GetDiskContent(DiscIDToStr(FDiscID), FCategory, M) then
    begin
      R := Parser.ParseCDDBReadResponse(M, True);
      M.Position := 0;
      if R < 0 then
        exit;
    end;
  finally
    M.Free;
  end;
end;

function TDiscHelper.GetDiskContent(ADiscID, ACategory: string;
  Content: TStream): boolean;
const
  SCmdRead = 'cmd=cddb+read+%s+%s';
begin
  Result := DoCDDBCmd(Format(SCmdRead, [ACategory, ADiscID]), Content);
end;

function TDiscHelper.DoCDDBCmd(CMD: string; Response: TStream): boolean;
const
  SHello = ('hello=%s %s %s %s');
var
  HTTP: THTTPSend;
  U, URL: string;
begin
  Result := False;
  U := 'Anonymous';
  HTTP := THTTPSend.Create;
  try
    Url := 'http://freedb.freedb.org/~cddb/cddb.cgi' + '?';
    URL := URL + StringReplace(Cmd, ' ', '+', [rfReplaceAll]);
    URL := URL + '&' + Format(SHello, ['%EEch', U, 'fpcddb', 'v1.0PL0']);
    URL := URL + '&proto=1';
    Result := HTTP.HTTPMethod('GET', EncodeUrl(URL));
    if not Result then
      raise Exception.Create('CDDB')
    else
    begin
      Response.CopyFrom(HTTP.Document, 0);
      Response.Position := 0;
    end;
  finally
    HTTP.Free;
  end;
end;

function TDiscHelper.GetCategory(AQuery: string): string;
const
  SCmdQuery = 'cmd=cddb+query+%s';
var
  S: TMemoryStream;
  M: TCDDBQueryMatches;
  I: integer;
begin
  Result := '';
  M := TCDDBQueryMatches.Create(TCDDBQueryMatch);
  try
    S := TMemoryStream.Create;
    try
      if not DoCDDBCmd(Format(SCMdQuery, [AQuery]), S) then
        Exit;
      I := FParser.ParseCDDBQueryResponse(S, M, True);
    finally
      S.Free;
    end;
    //I:=SelectMatch(M);
    //If I<>-1 then
    Result := M[0].Category;
  finally
    M.Free;
  end;
end;

end.
