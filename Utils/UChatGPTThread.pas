{***************************************************}
{                                                   }
{   This unit contains a worker thread to do        }
{   API calls and some other stuff.                 }
{   Auhtor: Ali Dehbansiahkarbon(adehban@gmail.com) }
{                                                   }
{***************************************************}
unit UChatGPTThread;

interface
uses
  System.Classes, System.SysUtils, IdHTTP, IdSSLOpenSSL, IdComponent, Vcl.Dialogs,
  XSuperObject, System.Generics.Collections, Winapi.Messages, Winapi.Windows, UChatGPTSetting;

const
  WM_UPDATE_MESSAGE = WM_USER + 5874;
  WM_PROGRESS_MESSAGE = WM_USER + 5875;

type
  TExecutorTrd = class(TThread)
  private
    FHandle: HWND;
    FPrompt: string;
    FMaxToken: Integer;
    FTemperature: Integer;
    FModel: string;
    FApiKey: string;
    FFormattedResponse: TStringList;
    FUrl: string;
    FProxySetting: TProxySetting;
  protected
    procedure Execute; override;
  public
    constructor Create(AHandle: HWND; AApiKey, AModel, APrompt, AUrl: string; AMaxToken, ATemperature: Integer;
                       AActive: Boolean; AProxyHost: string; AProxyPort: Integer; AProxyUsername: string; 
                       AProxyPassword: string);
    destructor Destroy; override;
  end;

  TRequestJSON = class
  private
    FModel: string;
    FPrompt: string;
    FMax_tokens: Integer;
    FTemperature: Integer;
  public
    property model: string read FModel write FModel;
    property prompt: string read FPrompt write FPrompt;
    property max_tokens: Integer read FMax_tokens write FMax_tokens;
    property temperature: Integer read FTemperature write FTemperature;
  end;

  TChoice = class
  private
    FText: string;
    FIndex: Integer;
    FLogProbs: string;
    FFinish_reason: string;
  published
    property text: string read FText write FText;
    property &index: Integer read FIndex write FIndex;
    property logprobs: string read FLogProbs write FLogProbs;
    property finish_reason: string read FFinish_reason write FFinish_reason;
  end;

  TUsage = class
  private
    FPrompt_Tokens: Integer;
    FCompletion_Tokens: Integer;
    FTotal_Tokens: Integer;
  published
    property prompt_tokens: Integer read FPrompt_Tokens write FPrompt_Tokens;
    property completion_tokens: Integer read FCompletion_Tokens write FCompletion_Tokens;
    property total_tokens: Integer read FTotal_Tokens write FTotal_Tokens;
  end;

  TChatGPTResponse = class
  private
    FId: string;
    FObject: string;
    FCreated: Integer;
    FModel: string;
    FChoices: TObjectList<TChoice>;
    FUsage: Tusage;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property id: string read FId write FId;
    property &object: string read FObject write FObject;
    property created: Integer read FCreated write FCreated;
    property model: string read FModel write FModel;
    property choices: TObjectList<TChoice> read FChoices write FChoices;
    property usage: Tusage read FUsage write FUsage;
  end;
  
  TOpenAIAPI = class
  private
    FAccessToken: string;
    FUrl: string;
    FProxySetting: TProxySetting;
  public
    constructor Create(const AAccessToken, AUrl: string; AProxySetting: TProxySetting);
    function Query(const AModel: string; const APrompt: string; AMaxToken: Integer; Aemperature: Integer): string;
  end;

implementation

constructor TOpenAIAPI.Create(const AAccessToken, AUrl: string; AProxySetting: TProxySetting);
begin
  inherited Create;
  FAccessToken := AAccessToken;
  FUrl := AUrl;
  FProxySetting := AProxySetting;
end;

function TOpenAIAPI.Query(const AModel: string; const APrompt: string; AMaxToken: Integer; Aemperature: Integer): string;
var
  LvHttpClient: TIdHTTP;
  LvSslIOHandler: TIdSSLIOHandlerSocketOpenSSL;
  LvParamStream: TStringStream;

  LvRequestJSON: TRequestJSON;
  LvChatGPTResponse: TChatGPTResponse;

  LvResponseStream: TStringStream;
begin
  LvHttpClient := TIdHTTP.Create(nil);
  if (FProxySetting.Active) and (not LvHttpClient.ProxyParams.ProxyServer.IsEmpty) then
  begin  
    LvHttpClient.ProxyParams.ProxyServer := FProxySetting.ProxyHost;
    LvHttpClient.ProxyParams.ProxyPort := FProxySetting.ProxyPort;
    LvHttpClient.ProxyParams.ProxyUsername := FProxySetting.ProxyUsername;
    LvHttpClient.ProxyParams.ProxyPassword := FProxySetting.ProxyPassword;
  end;    
  
  LvSslIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  LvChatGPTResponse := TChatGPTResponse.Create;
  LvRequestJSON := TRequestJSON.Create;

  with LvRequestJSON do
  begin
    model := AModel;
    prompt := APrompt;
    max_tokens := AMaxToken;
    temperature := Aemperature;
  end;

  try
    LvHttpClient.IOHandler := LvSslIOHandler;
    LvSslIOHandler.SSLOptions.SSLVersions := [sslvTLSv1_2];
    LvParamStream := TStringStream.Create(LvRequestJSON.AsJSON(True), TEncoding.UTF8);

    LvHttpClient.Request.CustomHeaders.AddValue('Authorization', 'Bearer '+ FAccessToken);
    LvHttpClient.Request.ContentType := 'application/json';
    LvHttpClient.Request.AcceptEncoding := 'deflate, gzip;q=1.0, *;q=0.5';

    try
      LvResponseStream := TStringStream.Create;
      LvHttpClient.Post(FUrl , LvParamStream, LvResponseStream);

      if not LvResponseStream.DataString.IsEmpty then
        Result :=  UTF8ToString(LvChatGPTResponse.FromJSON(LvResponseStream.DataString).Choices[0].Text.Trim);
    except on E: Exception do
      Result := E.Message;
    end;
  finally
    LvResponseStream.Free;
    LvRequestJSON.Free;
    LvParamStream.Free;
    LvChatGPTResponse.Free;
    LvSslIOHandler.Free;
    LvHttpClient.Free;
  end;
end;

{ TChatGPTResponse }

constructor TChatGPTResponse.Create;
begin
  inherited Create;
  FChoices := TObjectList<TChoice>.Create;
  FUsage := Tusage.Create;
end;

destructor TChatGPTResponse.Destroy;
begin
  FChoices.Free;
  FUsage.Free;
  inherited;
end;

{ TExecutorTrd }
constructor TExecutorTrd.Create(AHandle: HWND; AApiKey, AModel, APrompt, AUrl: string; AMaxToken, ATemperature: Integer;
                       AActive: Boolean; AProxyHost: string; AProxyPort: Integer; AProxyUsername: string; 
                       AProxyPassword: string);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FFormattedResponse := TStringList.Create;
  FApiKey := AApiKey;
  FModel := AModel;
  FPrompt := APrompt;
  FMaxToken := AMaxToken;
  FTemperature := ATemperature;
  FHandle := AHandle;
  FUrl := AUrl;
  FProxySetting := TProxySetting.Create;
  PostMessage(FHandle, WM_PROGRESS_MESSAGE, 1, 0);
end;

destructor TExecutorTrd.Destroy;
begin
  FFormattedResponse.Free;
  FProxySetting.Free;
  PostMessage(FHandle, WM_PROGRESS_MESSAGE, 0, 0);
  inherited;
end;

procedure TExecutorTrd.Execute;
var
  LvAPI: TOpenAIAPI;
  LvResult: string;
begin
  inherited;
  LvAPI := TOpenAIAPI.Create(FApiKey, FUrl, FProxySetting);
  try
    try
      if not Terminated then
        LvResult := LvAPI.Query(FModel, FPrompt, FMaxToken, FTemperature).Trim;

      if (not Terminated) and (not LvResult.IsEmpty) then
        SendMessageW(FHandle, WM_UPDATE_MESSAGE, Integer(LvResult), 0);
    except on E: Exception do
      begin
        Sleep(10);
        SendMessageW(FHandle, WM_UPDATE_MESSAGE, Integer(E.Message), 1);
        Terminate;
      end;
    end;
  finally
    LvAPI.Free;
  end;
end;
end.
