unit IsInetU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Ping, ExtCtrls, StdCtrls, Menus, CoolTrayIcon, ImgList;

type
  TIsInetF = class(TForm)
    IsInetP: TPing;
    IsInetT: TTimer;
    IsInetCTI: TCoolTrayIcon;
    IsInetPM: TPopupMenu;
    tmClose: TMenuItem;
    tmLog: TMenuItem;
    IsInetL: TLabel;
    IsInetHideT: TTimer;
    IsInetM: TMemo;
    LogFrmtM: TMemo;
    IsInetIL: TImageList;
    procedure IsInetTTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmCloseClick(Sender: TObject);
    procedure IsInetCTIMouseEnter(Sender: TObject);
    procedure IsInetCTIMouseExit(Sender: TObject);
    procedure tmLogClick(Sender: TObject);
    procedure IsInetHideTTimer(Sender: TObject);
  private
    { Private declarations }
    isIsPingT: boolean;
    isInetOK: boolean;
    isMaybeNoInet: boolean;
    maybeNoInetDT: TDateTime;
    noInetDT: TDateTime;
    curDT: TDateTime;
    strBalloonTitle: string;
    strBalloonText: string;
    procedure SaveLog(s: String);
    function CheckInet: boolean;
  public
    { Public declarations }
  end;

var
  IsInetF: TIsInetF;

implementation

uses ShellAPI;

{$R *.dfm}

procedure TIsInetF.SaveLog(s: String);
var FN: string;
  F: TextFile;
  sDateTime: string;
begin
  DateTimeToString(sDateTime, 'dd.mm.yyyy hh:nn:ss', Now());
  FN := copy(Application.ExeName, 1, length(Application.ExeName) - 4) + '.log';
  AssignFile(F, FN);
  if FileExists(FN) then begin
    Append(F);
  end else begin
    Rewrite(F);
  end;
  Writeln(F, '[' + sDateTime + '] ' + s);
  CloseFile(F);
end;

function TIsInetF.CheckInet: boolean;
var n: integer;
  numIP: integer;
  res: boolean;
  count: integer;
begin
  IsInetL.Caption := 'CheckInet';
  count := 0;
  repeat
    count := count + 1;
    res := true;
    n := IsInetP.Ping;
    if (n = 0) then begin
      res := false;
    end;
    if (not res) then begin
      for numIP := 0 to IsInetM.Lines.Count - 1 do begin
        if ((IsInetM.Lines[numIP] <> IsInetP.Address) and
          (IsInetM.Lines[numIP] <> '')) then begin
          IsInetP.Address := IsInetM.Lines[numIP];
          break;
        end;
      end;
    end;
    Application.ProcessMessages;
  until res or (count >= 1); // сколько раз повторять пинг
  if (res) then begin
    IsInetCTI.IconIndex := 0;
  end else begin
    IsInetCTI.IconIndex := 1;
  end;
  Result := res;
end;

procedure TIsInetF.IsInetTTimer(Sender: TObject);
var isInet: boolean;
  s, logS: string;
  dtNow: TDAteTime;
begin
  if (not isIsPingT) then begin
    isIsPingT := true;
    isInet := CheckInet;
    if (isInet) then begin
      Hide;
      if (isMaybeNoInet) then begin
        //SaveLog('Восстановлено');
      end;
      isMaybeNoInet := false;
    end;
    if ((not isInet) and (strBalloonTitle = 'All OK')) then begin
      strBalloonTitle := '?';
      strBalloonText := 'Ждем выяснения обстоятельств' + #13#10 + '[ip=' + IsInetP.Address + ']';
    end;
    if (isInet and (strBalloonTitle = '?')) then begin
      strBalloonTitle := 'All OK';
      strBalloonText := 'All OK' + #13#10 + '[ip=' + IsInetP.Address + ']';
    end;
    if (isInet and not isInetOK) then begin
      logS := LogFrmtM.Lines[0];
      curDT := Now();
      DateTimeToString(s, 'dd.mm.yyyy', curDT);
      logS := StringReplace(logS, '%cur_d%', s, [rfReplaceAll, rfIgnoreCase]);
      DateTimeToString(s, 'hh:nn:ss', curDT);
      logS := StringReplace(logS, '%cur_t%', s, [rfReplaceAll, rfIgnoreCase]);
      DateTimeToString(s, 'hh:nn:ss', curDT - noInetDT);
      logS := StringReplace(logS, '%no_inet_t%', s, [rfReplaceAll, rfIgnoreCase]);
      SaveLog(logS);

      //strBalloonTitle := 'Инета не было!';
      //DateTimeToString(s, 'dd.mm.yyyy hh:nn:ss', noInetDT);
      //strBalloonText := 'с ' + s + #13#10;
      //logS := '' + s + ' - ';
      //DateTimeToString(s, 'dd.mm.yyyy hh:nn:ss', curDT);
      //strBalloonText := strBalloonText + 'по ' + s + #13#10;
      //logS := logS + s + '';
      //DateTimeToString(s, 'hh:nn:ss', curDT - noInetDT);
      //strBalloonText := 'в течение ' + s + #13#10 + strBalloonText + #13#10 + ' [ip=' + IsInetP.Address + ']';
      ////logS := s + ' ' + logS;
      //SaveLog('Internet ' + s + ' RESTORED! ' + logS + ' [ip=' + IsInetP.Address + ']');
    end;
    if (isInetOK and not isInet) then begin
      if (not isMaybeNoInet) then begin
        isMaybeNoInet := true;
        maybeNoInetDT := Now();
        isInet := true;
        //SaveLog(FloatToStr(maybeNoInetDT));
      end else begin
        // число, на которое делим, это количество секунд
        //подтверждения отсутствия инета
        dtNow := Now();
        //SaveLog(FloatToStr(dtNow) + ' - ' + FloatToStr(maybeNoInetDT) +
        //        ' ? ' + FloatToStr(1/(24*60*60)));
        if ((dtNow - maybeNoInetDT) < 30/(24*60*60)) then begin
          isInet := true;
        end;
      end;
      if (not isInet) then begin
        noInetDT := maybeNoInetDT;
        DateTimeToString(s, 'dd.mm.yyyy hh:nn:ss', noInetDT);
        SaveLog('Internet            ABSENT! ' + s + ' [ip=' + IsInetP.Address + ']');
      end;
    end;
    isInetOK := isInet;
    isIsPingT := false;
  end;
end;

procedure TIsInetF.FormCreate(Sender: TObject);
//var isInet: boolean;
begin
  isIsPingT := true;
  isMaybeNoInet := false;
  SaveLog('Programm started');
  //isInet := CheckInet;
  //if (isInet) then begin
  //  SaveLog('Internet OK!');
  //end else begin
  //  SaveLog('Internet ABSENT!');
  //  noInetDT := Now();
  //end;//
  //isInetOK := isInet;
  isInetOK := true;
  strBalloonTitle := 'All OK';
  strBalloonText := 'All OK';
  IsInetM.Text := '';
  IsInetM.Lines.LoadFromFile(
    copy(Application.ExeName, 1,
    length(Application.ExeName) - 4) + '.ip_list.txt');
  LogFrmtM.Text := '';
  LogFrmtM.Lines.LoadFromFile(
    copy(Application.ExeName, 1,
    length(Application.ExeName) - 4) + '.log_frmt.txt');
  isIsPingT := false;
  IsInetTTimer(Sender);
end;

procedure TIsInetF.FormClose(Sender: TObject; var Action: TCloseAction);
var s, logS: string;
begin
    if (not isInetOK) then begin
      curDT := Now();
      DateTimeToString(s, 'dd.mm.yyyy hh:nn:ss', noInetDT);
      logS := '(' + s + ' - ';
      DateTimeToString(s, 'dd.mm.yyyy hh:nn:ss', curDT);
      logS := logS + s + ')';
      DateTimeToString(s, 'hh:nn:ss', curDT - noInetDT);
      logS := s + ' ' + logS;
      SaveLog('Internet RESTORED! ' + logS + ' [ip=' + IsInetP.Address + ']');
    end;
    SaveLog('Programm Closed');
end;

procedure TIsInetF.tmCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TIsInetF.IsInetCTIMouseEnter(Sender: TObject);
begin
  if (strBalloonTitle = 'All OK') then begin
    IsInetCTI.ShowBalloonHint(strBalloonTitle, strBalloonText, bitInfo, 10);
  end else if (strBalloonTitle = '?') then begin
    IsInetCTI.ShowBalloonHint(strBalloonTitle, strBalloonText, bitWarning, 10);
  end else begin
    IsInetCTI.ShowBalloonHint(strBalloonTitle, strBalloonText, bitError, 10);
  end;
end;

procedure TIsInetF.IsInetCTIMouseExit(Sender: TObject);
begin
  IsInetCTI.HideBalloonHint;
end;

procedure TIsInetF.tmLogClick(Sender: TObject);
var FN: string;
begin
  FN := copy(Application.ExeName, 1, length(Application.ExeName) - 4) + '.log';
  ShellExecute(IsInetF.handle, 'open', PAnsiChar(FN), nil, nil, SW_SHOW);
end;

procedure TIsInetF.IsInetHideTTimer(Sender: TObject);
begin
  Hide;
  IsInetHideT.Enabled := false;
end;

end.
