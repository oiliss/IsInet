program IsInetP;

uses
  Forms,
  IsInetU in 'IsInetU.pas' {IsInetF};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TIsInetF, IsInetF);
  Application.Run;
end.
