unit ucdrom_helper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, jwawinioctl, Dialogs;

type

  { TCDRom_Helper }

  TCDRom_Helper = class
  public
    class function LockCD(hDrive: Handle): boolean;
    class function UnlockCD(hDrive: Handle): boolean;
    class function InjectCD(hDrive: Handle): boolean;
    class function EjectCD(hDrive: Handle): boolean;
    class function IsDeviceReady(hDrive: Handle): boolean;
  end;

implementation


{ TCDRom_Helper }

class function TCDRom_Helper.LockCD(hDrive: Handle): boolean;
var

  Dummy: cardinal;
  Event: PREVENT_MEDIA_REMOVAL;
begin

  if (hDrive = INVALID_HANDLE_VALUE) then
  begin
    Result := False;
    exit;
  end
  else
  begin
    Event.PreventMediaRemoval := True;
    Result := DeviceIoControl(hDrive, IOCTL_STORAGE_MEDIA_REMOVAL,
      @Event, SizeOf(Event), nil, 0, @Dummy, nil);
    if Result = False then
      ShowMessage(SysErrorMessage(GetLastError));
    //CloseHandle(hDrive);

  end;

end;

class function TCDRom_Helper.UnlockCD(hDrive: Handle): boolean;
var
  Dummy: cardinal;
  Event: PREVENT_MEDIA_REMOVAL;
begin
  if (hDrive = INVALID_HANDLE_VALUE) then
  begin
    Result := False;
    exit;
  end
  else
  begin
    Event.PreventMediaRemoval := False;
    Result := DeviceIoControl(hDrive, IOCTL_STORAGE_MEDIA_REMOVAL,
      @Event, SizeOf(Event), nil, 0, @Dummy, nil);
    if Result = False then
      ShowMessage(SysErrorMessage(GetLastError));
    //CloseHandle(hDrive);

  end;

end;

class function TCDRom_Helper.InjectCD(HDrive: Handle): boolean;
var
  Dummy: cardinal;
begin
  if (hDrive = INVALID_HANDLE_VALUE) then
  begin
    Result := False;
    exit;
  end
  else
  begin
    Result := DeviceIoControl(hDrive, IOCTL_STORAGE_LOAD_MEDIA,
      nil, 0, nil, 0, @Dummy, nil);
    if Result = False then
      ShowMessage(SysErrorMessage(GetLastError));
    //CloseHandle(hDrive);

  end;

end;

class function TCDRom_Helper.EjectCD(hDrive: Handle): boolean;
var
  Dummy: cardinal;
begin
  if (hDrive = INVALID_HANDLE_VALUE) then
  begin
    Result := False;
    exit;
  end
  else
  begin
    Result := DeviceIoControl(hDrive, IOCTL_STORAGE_EJECT_MEDIA,
      nil, 0, nil, 0, @Dummy, nil);
    if Result = False then
      ShowMessage(SysErrorMessage(GetLastError));
    //CloseHandle(hDrive);

  end;

end;

class function TCDRom_Helper.IsDeviceReady(hDrive: Handle): boolean;
var
  Dummy: cardinal;
begin
  if (hDrive = INVALID_HANDLE_VALUE) then
  begin
    Result := False;
    exit;
  end
  else
  begin
    Result := DeviceIoControl(hDrive, IOCTL_STORAGE_CHECK_VERIFY2,
      nil, 0, nil, 0, @Dummy, nil);
    //if Result = False then
      //ShowMessage(SysErrorMessage(GetLastError));
    // CloseHandle(hDrive);

  end;

end;

end.
