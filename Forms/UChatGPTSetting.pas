{ *************************************************** }
{                                                     }
{ This is the setting form of the plugin.             }
{ Could be found in the main menu.                    }
{ Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com)     }
{                                                     }
{ *************************************************** }
unit UChatGPTSetting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, System.Win.Registry, System.SyncObjs,
  ToolsAPI, System.StrUtils, System.Generics.Collections, Vcl.Mask,
  Vcl.ComCtrls;

const
  DefaultURL = 'https://api.openai.com/v1/completions';
  DefaultModel = 'text-davinci-003';
  DefaultMaxToken = 2048;
  DefaultTemperature = 0;
  DefaultIdentifier = 'cpt';
  DefaultCodeFormatter = False;
  DefaultRTL = False;

type
  TProxySetting = class
  private
    FActive: Boolean;
    FProxyHost: string;
    FProxyPort: Integer;
    FProxyUsername: string;
    FProxyPassword: string;
  public
    property Active: Boolean read FActive write FActive;
    property ProxyHost: string read FProxyHost write FProxyHost;
    property ProxyPort: Integer read FProxyPort write FProxyPort;
    property ProxyUsername: string read FProxyUsername write FProxyUsername;
    property ProxyPassword: string read FProxyPassword write FProxyPassword;
  end;

  // Note: This class is thread-safe, since accessing the class variable is done in a critical section!
  TSingletonSettingObj = class(TObject)
  private
    FApiKey: string;
    FURL: string;
    FModel: string;
    FMaxToken: Integer;
    FTemperature: Integer;
    FIdentifier: string;
    FCodeFormatter: Boolean;
    FRightToLeft: Boolean;
    FRootMenuIndex: Integer;
    FProxySetting: TProxySetting;
    FCurrentActiveView: IOTAEditView;
    FHistoryEnabled: Boolean;
    FHistoryPath: string;
    FShouldReloadHistory: Boolean;

    class var FInstance: TSingletonSettingObj;
    class function GetInstance: TSingletonSettingObj; static;
    procedure LoadDefaults;
    constructor Create;
    destructor Destroy; override;
    function GetLeftIdentifier: string;
    function GetRightIdentifier: string;
  public
    procedure ReadRegistry;
    procedure WriteToRegistry;
    function GetSetting: string;
    function GetHistoryFullPath: string;
    Class Procedure RegisterFormClassForTheming(Const AFormClass: TCustomFormClass; Const Component: TComponent = Nil);

    class property Instance: TSingletonSettingObj read GetInstance;
    property ApiKey: string read FApiKey write FApiKey;
    property URL: string read FURL write FURL;
    property Model: string read FModel write FModel;
    property MaxToken: Integer read FMaxToken write FMaxToken;
    property Temperature: Integer read FTemperature write FTemperature;
    property CodeFormatter: Boolean read FCodeFormatter write FCodeFormatter;
    property Identifier: string read FIdentifier write FIdentifier;
    property LeftIdentifier: string read GetLeftIdentifier;
    property RightIdentifier: string read GetRightIdentifier;
    property RighToLeft: Boolean read FRightToLeft write FRightToLeft;
    property RootMenuIndex: Integer read FRootMenuIndex write FRootMenuIndex;
    property ProxySetting: TProxySetting read FProxySetting write FProxySetting;
    property CurrentActiveView: IOTAEditView read FCurrentActiveView write FCurrentActiveView;
    property HistoryEnabled: Boolean read FHistoryEnabled write FHistoryEnabled;
    property HistoryPath: string read FHistoryPath write FHistoryPath;
    property ShouldReloadHistory: Boolean read FShouldReloadHistory write FShouldReloadHistory;
  end;

  TFrm_Setting = class(TForm)
    pnl1: TPanel;
    grp_OpenAI: TGroupBox;
    pnlOpenAI: TPanel;
    lbl_1: TLabel;
    lbl_2: TLabel;
    lbl_3: TLabel;
    lbl_4: TLabel;
    lbl_5: TLabel;
    edt_Url: TEdit;
    edt_ApiKey: TEdit;
    edt_MaxToken: TEdit;
    edt_Temperature: TEdit;
    cbbModel: TComboBox;
    pnlOther: TPanel;
    pnlBottom: TPanel;
    Btn_Default: TButton;
    Btn_Save: TButton;
    GroupBox1: TGroupBox;
    pnlHistory: TPanel;
    chk_History: TCheckBox;
    lbEdt_History: TLabeledEdit;
    grp_Proxy: TGroupBox;
    pnlProxy: TPanel;
    lbEdt_ProxyHost: TLabeledEdit;
    lbEdt_ProxyPort: TLabeledEdit;
    chk_ProxyActive: TCheckBox;
    lbEdt_ProxyUserName: TLabeledEdit;
    lbEdt_ProxyPassword: TLabeledEdit;
    grp_Other: TGroupBox;
    pnlIDE: TPanel;
    lbl_6: TLabel;
    Edt_SourceIdentifier: TEdit;
    chk_CodeFormatter: TCheckBox;
    chk_Rtl: TCheckBox;
    Btn_HistoryPathBuilder: TButton;
    procedure Btn_SaveClick(Sender: TObject);
    procedure Btn_DefaultClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Btn_HistoryPathBuilderClick(Sender: TObject);
    procedure chk_HistoryClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Frm_Setting: TFrm_Setting;
  Cs: TCriticalSection;

implementation

{$R *.dfm}

{ TSingletonSettingObj }
constructor TSingletonSettingObj.Create;
begin
  inherited;
  FProxySetting := TProxySetting.Create;
  CurrentActiveView := nil;
  LoadDefaults;
end;

destructor TSingletonSettingObj.Destroy;
begin
  FProxySetting.Free;
  inherited;
end;

function TSingletonSettingObj.GetHistoryFullPath: string;
begin
  Result := FHistoryPath + '\History.sdb';
end;

class function TSingletonSettingObj.GetInstance: TSingletonSettingObj;
begin
  if not Assigned(FInstance) then
    FInstance := TSingletonSettingObj.Create;
  Result := FInstance;
end;

function TSingletonSettingObj.GetLeftIdentifier: string;
begin
  Result := FIdentifier + ':';
end;

function TSingletonSettingObj.GetRightIdentifier: string;
begin
  Result := ':' + FIdentifier;
end;

function TSingletonSettingObj.GetSetting: string;
begin
  Result := EmptyStr;
  ShowMessage
    ('You need an API key, please fill the setting parameters in setting form.');
  Frm_Setting := TFrm_Setting.Create(nil);
  try
    TSingletonSettingObj.RegisterFormClassForTheming(TFrm_Setting, Frm_Setting);
    // Apply Theme
    Frm_Setting.ShowModal;
  finally
    FreeAndNil(Frm_Setting);
  end;
  Result := TSingletonSettingObj.Instance.ApiKey;
end;

procedure TSingletonSettingObj.LoadDefaults;
begin
  FApiKey := '';
  FURL := DefaultURL;
  FModel := DefaultModel;
  FMaxToken := DefaultMaxToken;
  FTemperature := DefaultTemperature;
  FIdentifier := DefaultIdentifier;
  FCodeFormatter := DefaultCodeFormatter;
  FRightToLeft := DefaultRTL;
  FProxySetting.ProxyHost := '';
  FProxySetting.ProxyPort := 0;
  FProxySetting.ProxyUsername := '';
  FProxySetting.ProxyPassword := '';
  FProxySetting.Active := False;
  FHistoryEnabled := False;
  FShouldReloadHistory := False;
  FHistoryPath := '';
end;

procedure TSingletonSettingObj.ReadRegistry;
var
  LvRegKey: TRegistry;
begin
  FApiKey := '';

  LvRegKey := TRegistry.Create;
  try
    try
      with LvRegKey do
      begin
        CloseKey;
        RootKey := HKEY_CURRENT_USER;

        if OpenKey('\SOFTWARE\ChatGPTWizard', False) then
        begin
          if ValueExists('ChatGPTApiKey') then
            FApiKey := ReadString('ChatGPTApiKey');

          if ValueExists('ChatGPTURL') then
            FURL := IfThen(ReadString('ChatGPTURL').IsEmpty, DefaultURL,
              ReadString('ChatGPTURL'))
          else
            FURL := DefaultURL;

          if ValueExists('ChatGPTModel') then
            FModel := IfThen(ReadString('ChatGPTModel').IsEmpty, DefaultModel,
              ReadString('ChatGPTModel'))
          else
            FModel := DefaultModel;

          if ValueExists('ChatGPTMaxToken') then
          begin
            FMaxToken := ReadInteger('ChatGPTMaxToken');
            if FMaxToken <= 0 then
              FMaxToken := DefaultMaxToken;
          end
          else
            FMaxToken := DefaultMaxToken;

          if ValueExists('ChatGPTTemperature') then
          begin
            FTemperature := ReadInteger('ChatGPTTemperature');
            if FTemperature <= -1 then
              FTemperature := DefaultTemperature;
          end
          else
            FTemperature := DefaultTemperature;

          if ValueExists('ChatGPTSourceIdentifier') then
            FIdentifier := IfThen(ReadString('ChatGPTSourceIdentifier').IsEmpty,
              DefaultIdentifier, ReadString('ChatGPTSourceIdentifier'))
          else
            FIdentifier := DefaultIdentifier;

          if ValueExists('ChatGPTCodeFormatter') then
            FCodeFormatter := ReadBool('ChatGPTCodeFormatter')
          else
            FCodeFormatter := DefaultCodeFormatter;

          if ValueExists('ChatGPTRTL') then
            FRightToLeft := ReadBool('ChatGPTRTL')
          else
            FRightToLeft := DefaultRTL;

          if ValueExists('ChatGPTProxyActive') then
            FProxySetting.Active := ReadBool('ChatGPTProxyActive')
          else
            FProxySetting.Active := False;

          if ValueExists('ChatGPTProxyHost') then
            FProxySetting.ProxyHost := ReadString('ChatGPTProxyHost')
          else
            FProxySetting.ProxyHost := '';

          if ValueExists('ChatGPTProxyPort') then
            FProxySetting.ProxyPort := ReadInteger('ChatGPTProxyPort')
          else
            FProxySetting.ProxyPort := 0;

          if ValueExists('ChatGPTProxyUsername') then
            FProxySetting.ProxyUsername := ReadString('ChatGPTProxyUsername')
          else
            FProxySetting.ProxyUsername := '';

          if ValueExists('ChatGPTProxyPassword') then
            FProxySetting.ProxyPassword := ReadString('ChatGPTProxyPassword')
          else
            FProxySetting.ProxyPassword := '';

          if ValueExists('ChatGPTHistoryEnabled') then
          begin
            FHistoryEnabled := ReadBool('ChatGPTHistoryEnabled');
            FShouldReloadHistory := FHistoryEnabled;
          end;

          if ValueExists('ChatGPTHistoryPath') then
            FHistoryPath := ReadString('ChatGPTHistoryPath');
        end;
      end;
    except
      LoadDefaults;
    end;
  finally
    LvRegKey.Free;
  end;
end;

class procedure TSingletonSettingObj.RegisterFormClassForTheming(const AFormClass: TCustomFormClass; const Component: TComponent);
{$IF CompilerVersion >= 32.0}
Var
{$IF CompilerVersion > 33.0} // Breaking change to the Open Tools API - They fixed the wrongly defined interface
  ITS: IOTAIDEThemingServices;
{$ELSE}
  ITS: IOTAIDEThemingServices250;
{$IFEND}
{$IFEND}
begin
{$IF CompilerVersion >= 32.0}
{$IF CompilerVersion > 33.0}
  If Supports(BorlandIDEServices, IOTAIDEThemingServices, ITS) Then
{$ELSE}
  If Supports(BorlandIDEServices, IOTAIDEThemingServices250, ITS) Then
{$IFEND}
    If ITS.IDEThemingEnabled Then
    begin
      ITS.RegisterFormClass(AFormClass);
      If Assigned(Component) Then
        ITS.ApplyTheme(Component);
    end;
{$IFEND}
end;

procedure TSingletonSettingObj.WriteToRegistry;
var
  LvRegKey: TRegistry;
begin
  LvRegKey := TRegistry.Create;
  try
    with LvRegKey do
    begin
      CloseKey;
      RootKey := HKEY_CURRENT_USER;
      if OpenKey('\SOFTWARE\ChatGPTWizard', True) then
      begin
        WriteString('ChatGPTApiKey', FApiKey);
        WriteString('ChatGPTURL', FURL);
        WriteString('ChatGPTModel', FModel);
        WriteInteger('ChatGPTMaxToken', FMaxToken);
        WriteInteger('ChatGPTTemperature', FTemperature);
        WriteString('ChatGPTSourceIdentifier', FIdentifier);
        WriteBool('ChatGPTCodeFormatter', FCodeFormatter);
        WriteBool('ChatGPTRTL', FRightToLeft);
        WriteBool('ChatGPTProxyActive', FProxySetting.Active);
        WriteString('ChatGPTProxyHost', FProxySetting.ProxyHost);
        WriteInteger('ChatGPTProxyPort', FProxySetting.ProxyPort);
        WriteString('ChatGPTProxyUsername', FProxySetting.ProxyUsername);
        WriteString('ChatGPTProxyChatGPTProxyPassword', FProxySetting.ProxyPassword);
        WriteBool('ChatGPTHistoryEnabled', FHistoryEnabled);
        WriteString('ChatGPTHistoryPath', FHistoryPath);
      end;
    end;
  finally
    LvRegKey.Free;
  end;
end;

procedure TFrm_Setting.Btn_DefaultClick(Sender: TObject);
begin
  edt_ApiKey.Text := '';
  edt_Url.Text := DefaultURL;
  cbbModel.ItemIndex := 0;
  edt_MaxToken.Text := IntToStr(DefaultMaxToken);
  edt_Temperature.Text := IntToStr(DefaultTemperature);
  chk_CodeFormatter.Checked := DefaultCodeFormatter;
  chk_Rtl.Checked := DefaultRTL;
  lbEdt_ProxyHost.Text := '';
  lbEdt_ProxyPort.Text := '';
  lbEdt_ProxyUserName.Text := '';
  lbEdt_ProxyPassword.Text := '';
  chk_History.Checked := False;
  lbEdt_History.Text := '';
end;

procedure TFrm_Setting.Btn_HistoryPathBuilderClick(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders];
    if Execute then
      lbEdt_History.Text := FileName;
  finally
    Free;
  end;
end;

procedure TFrm_Setting.Btn_SaveClick(Sender: TObject);
var
  LvSettingObj: TSingletonSettingObj;
begin
  if chk_History.Checked then
  begin
    if Trim(lbEdt_History.Text).IsEmpty then
    begin
      ShowMessage('Please indicate the history path.');
      Exit;
    end;
  end;

  LvSettingObj := TSingletonSettingObj.Instance;
  LvSettingObj.ApiKey := Trim(edt_ApiKey.Text);
  LvSettingObj.URL := Trim(edt_Url.Text);
  LvSettingObj.Model := Trim(cbbModel.Text);
  LvSettingObj.MaxToken := StrToInt(edt_MaxToken.Text);
  LvSettingObj.Temperature := StrToInt(edt_Temperature.Text);
  LvSettingObj.RighToLeft := chk_Rtl.Checked;
  LvSettingObj.CodeFormatter := chk_CodeFormatter.Checked;
  LvSettingObj.Identifier := Edt_SourceIdentifier.Text;
  LvSettingObj.ProxySetting.ProxyHost := lbEdt_ProxyHost.Text;
  LvSettingObj.ProxySetting.ProxyPort := StrToIntDef(lbEdt_ProxyPort.Text, 0);
  LvSettingObj.ProxySetting.Active := chk_ProxyActive.Checked;
  LvSettingObj.ProxySetting.ProxyUsername := lbEdt_ProxyUserName.Text;
  LvSettingObj.ProxySetting.ProxyPassword := lbEdt_ProxyPassword.Text;
  if (chk_History.Checked) and (not LvSettingObj.HistoryEnabled) then
    LvSettingObj.ShouldReloadHistory := True;

  LvSettingObj.HistoryEnabled := chk_History.Checked;
  LvSettingObj.HistoryPath := lbEdt_History.Text;
  lbEdt_History.Enabled := chk_History.Checked;
  Btn_HistoryPathBuilder.Enabled := chk_History.Checked;

  LvSettingObj.WriteToRegistry;
  Close;
end;

procedure TFrm_Setting.chk_HistoryClick(Sender: TObject);
begin
  lbEdt_History.Enabled := chk_History.Checked;
  Btn_HistoryPathBuilder.Enabled := chk_History.Checked;
end;

procedure TFrm_Setting.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Ord(Key) = 27 then
    Close;
end;

initialization

Cs := TCriticalSection.Create;

finalization

Cs.Free;

end.
