unit uwthread;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, ExtCtrls, SysUtils, StdCtrls, Math, Forms, Controls;

const
  THREAD_PAINT_SLEEP = 600;

type
  PPanel = ^TPanel;
{ TWThread }
type
  TWThread = class(TThread)
  private
    pSplashPanel: PPanel;
    TrackProgressBar: TProgressBar;
    OverallProgressBar: TProgressBar;

    TrackProgress: cardinal;
    OverallProgress: cardinal;
    SplashMessage: string;
    lbState: TLabel;

    lastTimePaint: cardinal;

    procedure PaintSplash;
    procedure DisablePanel;
    //procedure OtherControlsOnOff(key: boolean);
  public
    constructor Create(pSplashPanel_: PPanel);
    destructor Destroy; override;
  protected
    TrackProgressMax: cardinal;
    OverallProgressMax: cardinal;
    procedure DoWork(); virtual;
    procedure Execute; override;
    procedure ShowProgress(IncTrackProgress, IncOverallProgress: integer;
      msg: string = '');


  end;

implementation

constructor TWThread.Create(pSplashPanel_: PPanel);
begin
  inherited Create(True);
  Self.FreeOnTerminate := False;
  Self.Priority := tpNormal;
  lastTimePaint := GetTickCount64;
  Self.pSplashPanel := pSplashPanel_;
end;


destructor TWThread.Destroy;
begin
  FreeAndNil(lbState);
  DisablePanel;
  TrackProgressBar.Free;
  OverallProgressBar.Free;

  //OtherControlsOnOff(True);
  inherited;
end;

procedure TWThread.DoWork();
begin

end;

procedure TWThread.Execute;
begin
  Synchronize(@DoWork);
  //inherited;
end;

procedure TWThread.PaintSplash;
begin
  if GetTickCount64 - lastTimePaint < THREAD_PAINT_SLEEP then
    Exit;
  lastTimePaint := GetTickCount64;

  if pSplashPanel = nil then
    Exit;

  if not TPanel(pSplashPanel^).Visible then
  begin
    //OtherControlsOnOff(False);


    TPanel(pSplashPanel^).Enabled := True;
    TPanel(pSplashPanel^).Visible := True;

    TrackProgressBar := TProgressBar.Create(TPanel(pSplashPanel^));
    TrackProgressBar.Parent := TPanel(pSplashPanel^);
    TrackProgressBar.Top := 28;
    TrackProgressBar.Left := 10;
    TrackProgressBar.Width := 612;
    TrackProgressBar.Height := 10;
    TrackProgressBar.Min := 0;
    TrackProgressBar.Max := TrackProgressMax;
    //TrackProgressBar.Style:=pbstMarquee;
    TrackProgressBar.Position := 0;

    OverallProgressBar := TProgressBar.Create(TPanel(pSplashPanel^));
    OverallProgressBar.Parent := TPanel(pSplashPanel^);
    OverallProgressBar.Top := 48;
    OverallProgressBar.Left := 10;
    OverallProgressBar.Width := 612;
    OverallProgressBar.Height := 10;
    OverallProgressBar.Min := 0;
    OverallProgressBar.Max := OverallProgressMax;
    //OverallProgressBar.Style:=pbstMarquee;
    OverallProgressBar.Position := 0;


    lbState := TLabel.Create(TPanel(pSplashPanel^));
    lbState.Parent := TPanel(pSplashPanel^);
    lbState.Top := 2;
    lbState.Left := 2;
    lbState.AutoSize := True;
    lbState.Width := TPanel(pSplashPanel^).ClientWidth;
    lbState.Alignment := taCenter;
    //lbState.Visible := true;
  end;
  TrackProgressBar.Position := TrackProgress;
  OverallProgressBar.Position := OverallProgress;
  lbState.Caption := SplashMessage;
  TPanel(pSplashPanel^).Repaint;
end;

procedure TWThread.DisablePanel;
begin
  TPanel(pSplashPanel^).Enabled := False;
  TPanel(pSplashPanel^).Visible := False;
end;



procedure TWThread.ShowProgress(IncTrackProgress, IncOverallProgress: integer;
  msg: string);
begin
  if IncTrackProgress < 0 then
    TrackProgress := 0
  else
    TrackProgress := IncTrackProgress;

  if IncOverallProgress < 0 then
    OverallProgress := 0
  else
    OverallProgress := IncOverallProgress;
  if TrackProgressMax > 0 then
    msg := msg + #32 + FormatFloat('0.00 %', RoundTo(TrackProgress *
      100.0 / TrackProgressMax, -2));

  if msg > '' then
    SplashMessage := msg;

  PaintSplash;
end;


end.
