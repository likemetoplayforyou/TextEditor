program TextEditor;

uses
  Forms,
  UTextEditForm in 'UTextEditForm.pas' {frmTextEditor},
  UFunctionTextGenerator in 'Include\UFunctionTextGenerator.pas',
  UUtils in 'UUtils.pas',
  UTypes in 'UTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmTextEditor, frmTextEditor);
  Application.Run;
end.
