unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  StdCtrls, ExtCtrls, Windows, Cdrom, LConvEncoding, regexpr, uaudiocd, uextractor;

type

  { TMainForm }

  TMainForm = class(TForm)
    ImageList1: TImageList;
    InfoPanel: TPanel;
    refreshBtn: TButton;
    Label1: TLabel;
    artistLbl: TLabel;
    Label2: TLabel;
    albumLbl: TLabel;
    Genre: TLabel;
    genreLbl: TLabel;
    Label3: TLabel;
    saveDlg: TSelectDirectoryDialog;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    yearLbl: TLabel;
    TrackListView: TListView;
    setDeviceBtn: TButton;
    device_box: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure refreshBtnClick(Sender: TObject);
    procedure setDeviceBtnClick(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
    procedure ToolButton4Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
  private

  public
    procedure OtherControlsOnOff(key: boolean);

  end;

var
  MainForm: TMainForm;
  //DiscHelper: TAudioCD_Helper;
  Ripper: TAudioCD;
  Dir: string;
  sDir: boolean = True;


implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.OtherControlsOnOff(key: boolean);
var
  i: integer;
begin
  for i := 0 to ComponentCount - 1 do
    if (not (Components[i] is TPanel)) and (Components[i] is TControl) then
      (Components[i] as TControl).Enabled := Key;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Drives: array[1..10] of string;
  I, Count: integer;
begin
  Count := GetCDRomDevices(Drives);
  for I := 1 to Count do
    Device_Box.Items.add(Drives[i]);
  if Device_Box.Items.Count > 0 then
    Device_Box.ItemIndex := 0
  else
  begin
    raise Exception.Create('Cd\DVD\BDRom not found!');
    application.Destroy;
  end;
  //DiscHelper := TAudioCD_Helper.Create;
  //Parser := TCDDBParser.Create(self);
  ripper := TAudioCD.Create();
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ripper.Destroy;
  //DiscHelper.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  InfoPanel.Parent := MainForm;
  InfoPanel.Left := 10;
  InfoPanel.Top := MainForm.Height div 2;
end;

procedure TMainForm.refreshBtnClick(Sender: TObject);
begin
  if ripper.IsReady(Device_Box.Items[Device_Box.ItemIndex]) then
    setDeviceBtn.Enabled := True
  else
  begin
    ShowMessage(SysErrorMessage(GetLastError));
    setDeviceBtn.Enabled := False;
  end;
end;

procedure TMainForm.setDeviceBtnClick(Sender: TObject);
var
  i,j: integer;
  Item: TListItem;
  Drive: string;

begin
  refreshBtnClick(Sender);
  if not setDeviceBtn.Enabled then
    exit;
  if TrackListView.Items.Count > 0 then
  begin
    TrackListView.BeginUpdate;
    TrackListView.Clear;
    TrackListView.EndUpdate;
  end;
  setDeviceBtn.Enabled := False;
  refreshBtn.Enabled:= False;
  Drive := Device_Box.Items[Device_Box.ItemIndex];
  ripper.SetDrive(Drive);
  ArtistLbl.Caption := CP1251ToUTF8(ripper.DiscInfo.Performer);
  AlbumLbl.Caption := CP1251ToUTF8(ripper.DiscInfo.Title);
  Genrelbl.Caption := ripper.DiscInfo.Genre;
  YearLbl.Caption := ripper.DiscInfo.Year;
  for i := 0 to ripper.TrackList.Count - 1 do
  begin
    item := TrackListView.Items.Add;
    Caption := '';
    item.SubItems.Add(IntToStr(ripper.TrackList[i].Number));
    item.SubItems.Add(CP1251ToUTF8(ripper.TrackList[i].Title));
    item.SubItems.Add(TimeToStr(ripper.TrackList[i].Duration));
    item.SubItems.Add(ripper.TrackList[i].Length);
    item.Checked := False;
  end;
  setDeviceBtn.Enabled := True;
  refreshBtn.Enabled:= True;
  MainForm.Caption:='SimpleCDRipper v 0.1';

  //DiscHelper.SetDisc(Device_Box.Items[Device_Box.ItemIndex]);
end;

procedure TMainForm.ToolButton1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.ToolButton3Click(Sender: TObject);
begin
  Ripper.AudioHelper.InjectDrive();
end;

procedure TMainForm.ToolButton4Click(Sender: TObject);
begin
  Ripper.AudioHelper.EjectDrive();
end;

procedure TMainForm.ToolButton5Click(Sender: TObject);
var
  Extractor: TExtractor;
begin
  if TrackListView.Items.Count = 0 then
  begin
    ShowMessage('Track list is empty!');
    Exit;
  end;
  if SaveDlg.Execute then
    Dir := SaveDlg.FileName
  else
    exit;
  //OtherControlsOnOff(False);
  MainForm.Enabled:=false;
  Extractor := TExtractor.Create(@InfoPanel);
  try
  Extractor.DoWork;

  finally
    Extractor.Free;
  end;

  //OtherControlsOnOff(True);
  MainForm.Enabled:=true;
end;

procedure TMainForm.ToolButton7Click(Sender: TObject);
begin
  ShowMessage('Not Implemented Yet');
end;

end.
