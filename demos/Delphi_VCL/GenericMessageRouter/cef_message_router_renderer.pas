unit cef_message_router_renderer;
(*
// Copyright (c) 2014 Marshall A. Greenblatt. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the name Chromium Embedded
// Framework nor the names of its contributors may be used to endorse
// or promote products derived from this software without specific prior
// written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------------------------

Jacob Hoover - Translated from C to Delphi.
*)

interface

uses uCEFApplication, uCEFTypes, uCEFINterfaces, uCEFMiscFunctions, uCEFv8Handler,
  uCEFProcessMessage, uCEFv8Context, uCEFv8Value, Generics.Collections,
  uCEFBaseRefCounted, cef_message_router, uCEFListValue;

type
  TBrowserRequestInfoMapIdType = TPair<Integer, Integer>;
  type TBrowserRequestInfoMapObjectType = PRequestInfo;

  TBrowserRequestInfoMap = class(TCefBrowserInfoMap<TBrowserRequestInfoMapIdType, TBrowserRequestInfoMapObjectType>)
  //TBrowserRequestInfoMap = class(TCefBrowserInfoMap<TPair<Integer, Integer>, PRequestInfo>)
  protected
    procedure Destruct(info: TBrowserRequestInfoMapObjectType); override;
  public
    type
      TVisitorGetCount = class(TVisitor)
      private
        FContextId: Integer;
        FCount: Integer;
      public
        constructor Create(context_id: Integer);
        //function OnNextInfo(browser_id: Integer; info_id: TPair<Integer, Integer>; info: PRequestInfo; var remove: Boolean): Boolean; override;
        function OnNextInfo(browser_id: Integer; info_id: TBrowserRequestInfoMapIdType; info: TBrowserRequestInfoMapObjectType; var remove: Boolean): Boolean; override;
        property Count: Integer read FCount;
      end;

      TVisitorGetItemOptionalRemove = class(TVisitor)
      private
        FAlwaysRemove: Boolean;
        FRemoved: Boolean;
      public
        constructor Create(always_remove: Boolean);
        function OnNextInfo(browser_id: Integer; info_id: TBrowserRequestInfoMapIdType; info: TBrowserRequestInfoMapObjectType; var remove: Boolean): Boolean; override;
        property Removed: Boolean read FRemoved;
      end;

      TVisitorCancelAllInContext = class(TVisitor)
      private
        FContextId: Integer;
        FCancelCount: Integer;
      public
        constructor Create(context_id: Integer);
        function OnNextInfo(browser_id: Integer; info_id: TBrowserRequestInfoMapIdType; info: TBrowserRequestInfoMapObjectType; var remove: Boolean): Boolean; override;
        property CancelCount: Integer read FCancelCount;
      end;
  end;

  TContextList = class(TDictionary<Integer, ICefv8Context>)
  end;

  TMessageRouterRendererSide = class(TCefMessageRouterRendererSide<ICefV8Value, ICefValue>)
  private
    FBrowserRequestInfoList: TBrowserRequestInfoMap;
    FConfig: TCefMessageRouterConfig;
    FContextList: TContextList;
    FContextIdGenerator: TIntIdGenerator;
    FRequestIdGenerator: TIntIdGenerator;
    FQueryMessageName: String;
    FCancelMessageName: String;
  private
    type
      TRendererV8Handler = class(TCefv8HandlerOwn)
      private
        FRouter: TMessageRouterRendererSide;
        FConfig: TCefMessageRouterConfig;
        FContextId: Integer;
        function GetIDForContext(context: ICefv8Context) : Integer;
      protected
        function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
      public
        constructor Create(router: TMessageRouterRendererSide; config: TCefMessageRouterConfig); reintroduce;
      end;
  protected
    // Used when JS initiates call to Native and may need notification of success or fail
    function SendQuery(browser:ICefBrowser; frame_id:Int64; is_main_frame: Boolean;
            context_id: Integer; message_id: Integer; request: ICefV8Value; persistent: Boolean;
            success_callback: ICefV8Value; failure_callback: ICefV8Value): Integer; override;
    function SendCancel(browser:ICefBrowser; context_id: Integer; request_id: Integer):Boolean; override;
    // Used when Native calls JS, and JS triggers a response back to Native.
    function SendNotify(browser:ICefBrowser; frame_id:Int64; is_main_frame: Boolean;
            context_id: Integer; message_type: String; message_id: String; request: ICefV8Value): Integer;

    function GetIDForMessage(message: ustring): Integer; virtual; abstract;
    function GetRequestInfo(browser_id: Integer; context_id: integer;request_id: Integer; always_remove: Boolean; var removed: Boolean): PRequestInfo; override;
    procedure ExecuteSuccessCallback(browser_id: Integer; context_id: integer;request_id: Integer; response: ICefValue); override;
    procedure ExecuteFailureCallback(browser_id: Integer; context_id: integer;request_id: Integer; error_code: Integer; error_message: ustring); override;
    property Config: TCefMessageRouterConfig read FConfig;
    property RequestIdGenerator: TIntIdGenerator read FRequestIdGenerator;
  public
    constructor Create(config: TCefMessageRouterConfig);
    destructor Destroy; override;
    function CreateIDForContext(context: ICefv8Context) : Integer;
    function GetIDForContext(context: ICefv8Context; remove: Boolean) : Integer;
    function GetContextByID(context_id: Integer) : ICefv8Context;

    function GetPendingCount(browser: ICefBrowser; context: ICefV8Context): Integer; override;
    procedure OnContextCreated(browser: ICefBrowser;frame: ICefFrame; context: ICefV8Context); override;
    procedure OnContextReleased(browser: ICefBrowser;frame: ICefFrame; context: ICefV8Context); override;
    function OnProcessMessageReceived(browser: ICefBrowser; process: TCefProcessId; message: ICefProcessMessage): Boolean; override;
  end;

//  TMessageRouterRendererSideVarArgs = class(TCefMessageRouterRendererSide<ICefV8Value, ICefValue>)
//  private
//    FBrowserRequestInfoList: TBrowserRequestInfoMap;
//    FConfig: TCefMessageRouterConfig;
//    FContextList: TContextList;
//    FContextIdGenerator: TIntIdGenerator;
//    FRequestIdGenerator: TIntIdGenerator;
//    FQueryMessageName: String;
//    FCancelMessageName: String;
//  protected
//    type
//      TRendererV8Handler = class(TCefv8HandlerOwn)
//      private
//        FRouter: TMessageRouterRendererSideVarArgs;
//        FConfig: TCefMessageRouterConfig;
//        FContextId: Integer;
//      protected
//        function GetIDForContext(context: ICefv8Context) : Integer;
//        function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
//        property Config: TCefMessageRouterConfig read FConfig;
//        property ContextId: Integer read FContextId;
//        property Router: TMessageRouterRendererSideVarArgs read FRouter;
//      public
//        constructor Create(router: TMessageRouterRendererSideVarArgs; config: TCefMessageRouterConfig); reintroduce;
//      end;
//  protected
//    function CreateHandler(router: TMessageRouterRendererSideVarArgs; config: TCefMessageRouterConfig): TRendererV8Handler; virtual;
//    function SendQuery(browser:ICefBrowser; frame_id:Int64; is_main_frame: Boolean;
//            context_id: Integer; message_id: Integer; request: ICefV8Value; persistent: Boolean;
//            success_callback: ICefV8Value; failure_callback: ICefV8Value): Integer; override;
//    function SendCancel(browser:ICefBrowser; context_id: Integer; request_id: Integer):Boolean; override;
//    function GetIDForMessage(message: ustring): Integer; virtual; abstract;
//    function GetRequestInfo(browser_id: Integer; context_id: integer;request_id: Integer; always_remove: Boolean; var removed: Boolean): PRequestInfo; override;
//    procedure ExecuteSuccessCallback(browser_id: Integer; context_id: integer;request_id: Integer; response: ICefValue); override;
//    procedure ExecuteFailureCallback(browser_id: Integer; context_id: integer;request_id: Integer; error_code: Integer; error_message: ustring); override;
//
//  public
//    constructor Create(config: TCefMessageRouterConfig);
//    destructor Destroy; override;
//    function CreateIDForContext(context: ICefv8Context) : Integer;
//    function GetIDForContext(context: ICefv8Context; remove: Boolean) : Integer;
//    function GetContextByID(context_id: Integer) : ICefv8Context;
//
//    function GetPendingCount(browser: ICefBrowser; context: ICefV8Context): Integer; override;
//    procedure OnContextCreated(browser: ICefBrowser;frame: ICefFrame; context: ICefV8Context); override;
//    procedure OnContextReleased(browser: ICefBrowser;frame: ICefFrame; context: ICefV8Context); override;
//    function OnProcessMessageReceived(browser: ICefBrowser; process: TCefProcessId; message: ICefProcessMessage): Boolean; override;
//  end;

//procedure CefRenderProcess_OnContextCreated(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
//procedure CefRenderProcess_OnContextReleased(const browser: ICefBrowser;const frame: ICefFrame; const context: ICefV8Context);
//procedure CefRenderProcess_OnProcessMessageReceived(const browser: ICefBrowser; sourceProcess: TCefProcessId; const message: ICefProcessMessage; var aHandled : boolean);
//procedure CefRenderProcess_OnWebKitInitialized;

implementation

uses
  SysUtils, uCefTask, Windows, Classes, uVVCefFunctions, uCEFConstants, StrUtils;


{ TMessageRouterRendererSide.TVisitorGetCount }
{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TBrowserRequestInfoMap.TVisitorGetCount.Create(
  context_id: Integer);
begin
  FContextId := context_id;
  FCount := 0;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TBrowserRequestInfoMap.TVisitorGetCount.OnNextInfo(
  browser_id: Integer; info_id: TBrowserRequestInfoMapIdType (*TPair<Integer, Integer>*);
  info: TBrowserRequestInfoMapObjectType(*PRequestInfo*);
  var remove: Boolean): Boolean;
begin
  inherited OnNextInfo(browser_id, info_id, info, remove);
  if info_id.Key = FContextId then
    Inc(FCount);
  Result := true;

  //TBrowserRequestInfoMap.TVisitor.Create.OnNextInfo()
end;

{ TBrowserRequestInfoMap }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TBrowserRequestInfoMap.Destruct(info: TBrowserRequestInfoMapObjectType);
begin
  inherited;
  Dispose(info);
end;

{ TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove.Create(
  always_remove: Boolean);
begin
  inherited Create;
  FAlwaysRemove := always_remove;
  FRemoved:= False;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove.OnNextInfo(
  browser_id: Integer; info_id: TBrowserRequestInfoMapIdType;
  info: TBrowserRequestInfoMapObjectType; var remove: Boolean): Boolean;
begin
  FRemoved := (FAlwaysRemove or not info.persistent);
  remove := FRemoved;
  Result := True;
end;

{ TBrowserRequestInfoMap.TVisitorCancelAllInContext }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TBrowserRequestInfoMap.TVisitorCancelAllInContext.Create(
  context_id: Integer);
begin
  inherited Create;
  FContextId := context_id;
  FCancelCount := 0;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TBrowserRequestInfoMap.TVisitorCancelAllInContext.OnNextInfo(
  browser_id: Integer; info_id: TBrowserRequestInfoMapIdType;
  info: TBrowserRequestInfoMapObjectType; var remove: Boolean): Boolean;
begin
  if info_id.Key = FContextId then
    begin
    remove := True;
    Dispose(info);
    Inc(FCancelCount);
    end;
  Result := True;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TMessageRouterRendererSide.Create(config: TCefMessageRouterConfig);
begin
  inherited Create();
  if not ValidateConfig(config) then
    raise Exception.Create('Invalid config');

  FConfig := config;
  FContextList:= TContextList.Create;
  FContextIdGenerator := TIntIdGenerator.Create;
  FRequestIdGenerator := TIntIdGenerator.Create;
  FBrowserRequestInfoList:= TBrowserRequestInfoMap.Create;

  FQueryMessageName := Format('%s%s', [FConfig.js_query_function, kMessageSuffix]);
  FCancelMessageName := Format('%s%s', [FConfig.js_cancel_function, kMessageSuffix]);
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.CreateIDForContext(context: ICefv8Context): Integer;
begin
  Assert(GetIDForContext(context, false)= kReservedId);
  Result := FContextIdGenerator.GetNextId();
  FContextList.Add(Result, context);
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
destructor TMessageRouterRendererSide.Destroy;
begin
  FreeAndNil(FContextList);
  FreeAndNil(FContextIdGenerator);
  FreeAndNil(FRequestIdGenerator);

  inherited;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TMessageRouterRendererSide.ExecuteFailureCallback(browser_id,
  context_id, request_id, error_code: Integer; error_message: ustring);
var
  removed: Boolean;
  info: PRequestInfo;
  context: ICefv8Context;
  args: TCefv8ValueArray;
begin
  inherited;
  CefDebugLog(Format('TMessageRouterRendererSide.ExecuteFailureCallback(browser_id: %d, request_id:%d, error_code: %d, error_message: %s)', [browser_id,request_id,error_code, error_message]), CEF_LOG_SEVERITY_WARNING);
  // CEF_REQUIRE_RENDERER_THREAD();
  // -TODO: -oJCH: I see BCR ass calling convention, but BRC as implementation...
  info := GetRequestInfo(browser_id, context_id, request_id, True, removed);
  if not(Assigned(info)) then
    Exit;

  context := GetContextByID(context_id);

  if Assigned(context) and Assigned(info.failure_callback) then
    begin
    SetLength(args, 2);
    args[0] := TCefV8ValueRef.NewInt(error_code);
    args[1] := TCefV8ValueRef.NewString(error_message);
    info.failure_callback.ExecuteFunctionWithContext(context, nil, args);
    end;

  Assert(removed);

  Dispose(info);

end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TMessageRouterRendererSide.ExecuteSuccessCallback(browser_id,
  context_id, request_id: Integer; response: ICefValue);
var
  removed: Boolean;
  info: PRequestInfo;
  context: ICefv8Context;
  args: TCefv8ValueArray;
  ret: ICefV8Value;
begin
//  inherited;
  // CEF_REQUIRE_RENDERER_THREAD();
  // -TODO: -oJCH: I see BCR as calling convention, but BRC as implementation...
  CefDebugLog(Format('TMessageRouterRendererSide.ExecuteSuccessCallback (browser_id: %d, request_id:%d, Param: %s)', [browser_id,request_id,CefValueToJsonString(response)]), CEF_LOG_SEVERITY_INFO);

  info := GetRequestInfo(browser_id, context_id, request_id, False, removed);
  if not(Assigned(info)) then
    Exit;

  context := GetContextByID(context_id);
  // CefDebugLog('Has Info', CEF_LOG_SEVERITY_WARNING);

  if Assigned(context) and Assigned(info.success_callback) then
    begin
    SetLength(args, 1);
    context.Enter;
    try
      args[0] := CefValueToCefV8Value(response);
    finally
      context.Exit;
    end;

    CefDebugLog('ExecuteFunctionWithContext', CEF_LOG_SEVERITY_INFO);
    ret := info.success_callback.ExecuteFunctionWithContext(context, nil, args);
    CefDebugLog('ExecuteFunctionWithContext returned ' + CefValueToJsonString(CefV8ValueToCefValue(ret)), CEF_LOG_SEVERITY_INFO);
    end;

  if removed then
    begin
    CefDebugLog(Format('(browser_id: %d, request_id:%d, Removed: %s)', [browser_id,request_id,BoolToStr(removed, True)]), CEF_LOG_SEVERITY_INFO);
    Dispose(info);
    end;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.GetContextByID(context_id: Integer): ICefv8Context;
begin
  if not FContextList.TryGetValue(context_id, Result) then
    Result := nil;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.GetIDForContext(context: ICefv8Context; remove: Boolean): Integer;
var
  pair: TPair<Integer,ICefv8Context>;
begin
  Result := kReservedId;

  for pair in FContextList do
    if pair.Value.IsSame(context) then
      begin
      Result := pair.Key;
      if remove then
        FContextList.Remove(Result);
      Break;
      end;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.GetPendingCount(browser: ICefBrowser; context: ICefV8Context): Integer;
var
  context_id: Integer;
  visitor: TBrowserRequestInfoMap.TVisitorGetCount;
begin
  // CEF_REQUIRE_RENDERER_THREAD();
  if FBrowserRequestInfoList.Empty() then
    Exit(0);

  if Assigned(context) and context.IsValid then
    begin
    context_id := GetIDForContext(context, False);

    if (context_id = kReservedId) then
      Exit(0);

    visitor := TBrowserRequestInfoMap.TVisitorGetCount.Create(context_id);

    if Assigned(browser) then
      FBrowserRequestInfoList.FindAll(browser.Identifier, visitor)
    else
      FBrowserRequestInfoList.FindAll(visitor);

    Exit(visitor.Count);
    end
  else if Assigned(browser) then
    Exit(FBrowserRequestInfoList.Size(browser.Identifier))
  else
    Exit(FBrowserRequestInfoList.Size);
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.GetRequestInfo(browser_id:Integer; context_id: integer;request_id: Integer; always_remove: Boolean;
  var removed: Boolean): PRequestInfo;
var
  visitor: TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove;
begin
  visitor := TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove.Create(always_remove);
  Result := FBrowserRequestInfoList.Find(browser_id, TBrowserRequestInfoMapIdType.Create(context_id, request_id) , visitor);
  if Assigned(Result) then
    removed := visitor.Removed;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TMessageRouterRendererSide.OnContextCreated(browser: ICefBrowser;
  frame: ICefFrame; context: ICefV8Context);
var
  window: ICefv8Value;
  handler: TRendererV8Handler;
  query_func : ICefV8Value;
  cancel_func : ICefV8Value;
// TODO: Enable hiding the functions within an object(s)
//  queryFunctionName: String;
//  cancelFunctionName: String;
//  queryFunctionPath: TStrings;
//  cancelQueryFunctionPath: TStrings;

begin
  inherited;
  //CEF_REQUIRE_RENDERER_THREAD();

  window := context.Global;
  handler := TRendererV8Handler.Create(Self, FConfig);
  query_func := TCefv8ValueRef.NewFunction(FConfig.js_query_function, handler);

  (* typedef enum {
  V8_PROPERTY_ATTRIBUTE_NONE = 0,            // Writeable, Enumerable,
                                             //   Configurable
  V8_PROPERTY_ATTRIBUTE_READONLY = 1 << 0,   // Not writeable
  V8_PROPERTY_ATTRIBUTE_DONTENUM = 1 << 1,   // Not enumerable
  V8_PROPERTY_ATTRIBUTE_DONTDELETE = 1 << 2  // Not configurable
  } cef_v8_propertyattribute_t;*)

  //TCefV8PropertyAttributes
  window.SetValueByKey(FConfig.js_query_function, query_func, 7 (*V8_PROPERTY_ATTRIBUTE_READONLY|V8_PROPERTY_ATTRIBUTE_DONTENUM|V8_PROPERTY_ATTRIBUTE_DONTDELETE*));

  cancel_func := TCefv8ValueRef.NewFunction(FConfig.js_cancel_function, handler);
  window.SetValueByKey(FConfig.js_cancel_function, cancel_func, 7 (*V8_PROPERTY_ATTRIBUTE_READONLY|V8_PROPERTY_ATTRIBUTE_DONTENUM|V8_PROPERTY_ATTRIBUTE_DONTDELETE*));
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TMessageRouterRendererSide.OnContextReleased(browser: ICefBrowser;
  frame: ICefFrame; context: ICefV8Context);
var
  context_id: Integer;
begin
  inherited;
  //CEF_REQUIRE_RENDERER_THREAD();
  context_id := GetIDForContext(context, true);
  if (context_id <> kReservedId) then
    SendCancel(browser, context_id, kReservedId);


end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.OnProcessMessageReceived(
  browser: ICefBrowser; process: TCefProcessId;
  message: ICefProcessMessage): Boolean;
var
  localmessage: ICefProcessMessage;
  message_name: ustring;
  args: ICefListValue;
  context_id: Integer;
  request_id: Integer;
  is_success: Boolean;
  response: ICefValue;
  error_code: Integer;
  error_message: ustring;
  index: Integer;
  logMsg: String;
begin

  logMsg := 'TMessageRouterRendererSide.OnProcessMessageReceived(' + message.Name + ', ';

  args := message.ArgumentList;
  for index := 0 to args.GetSize -1 do
    logMsg := logMsg + CefValueToJsonString(args.GetValue(index)) + ', ';

  // Kill the trailing ", "
  logMsg := LeftStr(logMsg, Length(logMsg)-2) + ')';
  CefDebugLog(logMsg,CEF_LOG_SEVERITY_INFO);

  // CEF_REQUIRE_RENDERER_THREAD();
  message_name := message.Name;

  if (message_name = FQueryMessageName) then
    begin
    // OutputDebugMessage('TMessageRouterRendererSide.OnProcessMessageReceived(' + message_name + ')');
    args := message.ArgumentList;
    Assert(args.GetSize > 3);

    context_id := args.GetInt(0);
    request_id := args.GetInt(1);
    is_success := args.GetBool(2);

    if is_success then
      begin
      Assert(args.GetSize = 4);
      localmessage := message.Copy;
      args := localmessage.ArgumentList;
      response := args.GetValue(3);

      CefPostTask(TID_RENDERER, TCefFastTask.Create(procedure()
        begin
        ExecuteSuccessCallback(browser.Identifier, context_id, request_id, response);
        localmessage := nil;
        end));
      end
    else
      begin
      Assert(args.GetSize = 5);
      error_code := args.GetInt(3);
      error_message := args.GetString(4);
      CefPostTask(TID_RENDERER, TCefFastTask.Create(procedure()
        begin
        ExecuteFailureCallback(browser.Identifier, context_id, request_id, error_code, error_message);
        end));
      end;

      Exit(True);
    end;
    Exit(False);
end;


{ TMessageRouterRendererSide.TRendererV8Handler }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TMessageRouterRendererSide.TRendererV8Handler.Create(
  router: TMessageRouterRendererSide; config: TCefMessageRouterConfig);
begin
  inherited Create;
  FRouter := router;
  FConfig := config;
  FContextId := kReservedId;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.TRendererV8Handler.Execute(
  const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  arg: ICefV8Value;
  messageVal: ICefV8Value;
  requestVal: ICefV8Value;
  successVal: ICefV8Value;
  failureVal: ICefV8Value;
  persistentVal: ICefV8Value;

  context: ICefV8Context;
  context_id: Integer;
  frame_id: Int64;
  is_main_frame: Boolean;
  persistent: Boolean;
  request_id: Integer;
  message_id: Integer;
begin
  successVal := nil;
  failureVal := nil;
  // OutputDebugMessage('TRendererV8Handler.Execute(' + name + ')');
  if (name = FConfig.js_query_function) then
    begin
    if (Length(arguments) <> 1) or not(arguments[0].IsObject()) then
      begin
      exception := 'Invalid arguments; expecting a single object';
      Exit(true);
      end;

    arg := arguments[0];
    messageVal := arg.GetValueByKey(kMemberMessage);
    if not(Assigned(messageVal)) or messageVal.IsUndefined or messageVal.IsNull or not (messageVal.IsString) then
      begin
      exception := Format('Invalid arguments; object member "%s" is required and must have type string', [kMemberMessage]);
      Exit(true);
      end
    else
      message_id := FRouter.GetIDForMessage(messageVal.GetStringValue);


    requestVal := arg.GetValueByKey(kMemberRequest);
    if not(Assigned(requestVal)) or requestVal.IsUndefined or requestVal.IsNull then
      begin

      if requestVal.IsNull then
        OutputDebugString(PChar('IsNull = True'));
      if requestVal.IsObject then
        OutputDebugString(PChar('IsObject = True'));
      if requestVal.IsUndefined then
        OutputDebugString(PChar('IsUndefined = True'));
      exception := Format('Invalid arguments; object member "%s" is required', [kMemberRequest]);
      Exit(true);
      end;

    if arg.HasValueByKey(kMemberOnSuccess) then
      begin
      successVal := arg.GetValueByKey(kMemberOnSuccess);
      if not successVal.IsFunction then
        begin
        exception := Format('Invalid arguments; object member "%s" must have type function', [kMemberOnSuccess]);
        Exit(true);
        end;
      end;

    if arg.HasValueByKey(kMemberOnFailure) then
      begin
      failureVal := arg.GetValueByKey(kMemberOnFailure);
      if not failureVal.IsFunction then
        begin
        exception := Format('Invalid arguments; object member "%s" must have type function', [kMemberOnFailure]);
        Exit(true);
        end;
      end;

    if arg.HasValueByKey(kMemberPersistent) then
      begin
      persistentVal := arg.GetValueByKey(kMemberPersistent);
      if not persistentVal.IsBool then
        begin
        exception := Format('Invalid arguments; object member "%s" must have type boolean', [kMemberPersistent]);
        Exit(true);
        end;
      end;


    context := TCefV8ContextRef.Current;
    context_id := GetIDForContext(context);
    frame_id := context.Frame.Identifier;
    is_main_frame := context.Frame.IsMain;
    persistent := Assigned(persistentVal) and persistentVal.GetBoolValue();
    request_id := FRouter.SendQuery(context.Browser, frame_id, is_main_frame, context_id, message_id, requestVal, persistent, successVal, failureVal);
    retVal := TCefV8ValueRef.NewInt(request_id);
    Exit(true);
    end
  else if (name = FConfig.js_cancel_function) then
    begin
    if (Length(arguments) <> 1) or not(arguments[0].IsInt()) then
      begin
      exception := 'Invalid arguments; expecting a single integer';
      Exit(true);
      end;

    Result := False;
    request_id := arguments[0].GetIntValue;
    if (request_id <> kReservedId) then
      begin
      context := TCefV8ContextRef.Current;
      context_id := GetIDForContext(context);
      Result := FRouter.SendCancel(context.Browser, context_id, request_id);
      end;

    retVal := TCefV8ValueRef.NewBool(Result);
    Exit(True);
    end;

  Result := False;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.TRendererV8Handler.GetIDForContext(
  context: ICefv8Context): Integer;
begin
//  if FContextId = kReservedId then
//    FContextId := FRouter.CreateIDForContext(context);

  if FContextId = kReservedId then
    begin
    FContextId := FRouter.GetIDForContext(context, False);
    if FContextId = kReservedId then
      FContextId := FRouter.CreateIDForContext(context);
    end;
  Result := FContextId;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.SendCancel(browser: ICefBrowser; context_id,
  request_id: Integer): Boolean;
var
  browser_id: Integer;
  cancel_count: Integer;
  removed: Boolean;
  info: PRequestInfo;
  visitor: TBrowserRequestInfoMap.TVisitorCancelAllInContext;
  message: ICefProcessMessage;
  args: ICefListValue;
begin
  browser_id := browser.Identifier;
  cancel_count := 0;

  if (request_id <> kReservedId) then
    begin
    info := GetRequestInfo(browser_id, context_id, request_id, true, removed);
    if Assigned(info) then
      begin
      Dispose(info);
      cancel_count := 1;
      end;

    end
  else
    begin
    visitor := TBrowserRequestInfoMap.TVisitorCancelAllInContext.Create(context_id);
    FBrowserRequestInfoList.FindAll(browser_id, visitor);
    cancel_count := visitor.CancelCount;
    FreeAndNil(visitor);
    end;

  if cancel_count > 0 then
    begin
    message := TCefProcessMessageRef.New(FCancelMessageName);
    args := message.ArgumentList;
    args.SetInt(0, context_id);
    args.SetInt(1, request_id);
    browser.MainFrame.SendProcessMessage(PID_BROWSER, message);
    Exit(True);
    end;

  Exit(False);
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.SendNotify(browser: ICefBrowser;
  frame_id: Int64; is_main_frame: Boolean; context_id: Integer;
  message_type: String; message_id: String; request: ICefV8Value): Integer;
var
  info: PRequestInfo;
  message: ICefProcessMessage;
  args: ICefListValue;
begin
  CefDebugLog('TMessageRouterRendererSide.SendNotify(' + (message_id) + ')', CEF_LOG_SEVERITY_INFO);
  Result := FRequestIdGenerator.GetNextId;

  message := TCefProcessMessageRef.New(message_type);
  args := message.ArgumentList;
  args.SetInt(0, CefInt64GetLow(frame_id));
  args.SetInt(1, CefInt64GetHigh(frame_id));
  args.SetBool(2, is_main_frame);
  args.SetInt(3, context_id);
  args.SetString(4, message_id);
  args.SetInt(5, Result (*request_id*));
  args.SetValue(6, CefV8ValueToCefValue(request));

  browser.MainFrame.SendProcessMessage(PID_BROWSER, message);

end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TMessageRouterRendererSide.SendQuery(
  browser: ICefBrowser; frame_id: Int64; is_main_frame: Boolean;
  context_id: Integer; message_id: Integer; request: ICefV8Value; persistent: Boolean; success_callback,
  failure_callback: ICefV8Value): Integer;
var
  info: PRequestInfo;
  message: ICefProcessMessage;
  args: ICefListValue;
begin
  // OutputDebugMessage('TMessageRouterRendererSide.SendQuery(' + IntToStr(message_id) + ')');
  Result := FRequestIdGenerator.GetNextId;
  New(info);

  info.persistent := persistent;
  info.success_callback := success_callback;
  info.failure_callback := failure_callback;

  FBrowserRequestInfoList.Add(browser.Identifier,TBrowserRequestInfoMapIdType.Create(context_id, Result),  info);

  message := TCefProcessMessageRef.New(FQueryMessageName);
  args := message.ArgumentList;
  args.SetInt(0, CefInt64GetLow(frame_id));
  args.SetInt(1, CefInt64GetHigh(frame_id));
  args.SetBool(2, is_main_frame);
  args.SetInt(3, context_id);
  args.SetInt(4, message_id);
  args.SetInt(5, Result (*request_id*));
  args.SetValue(6, CefV8ValueToCefValue(request));
  args.SetBool(7, persistent);

  browser.MainFrame.SendProcessMessage(PID_BROWSER, message);

end;


{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
//constructor TMessageRouterRendererSideVarArgs.Create(config: TCefMessageRouterConfig);
//begin
//  inherited Create();
//  if not ValidateConfig(config) then
//    raise Exception.Create('Invalid config');
//
//  FConfig := config;
//  FContextList:= TContextList.Create;
//  FContextIdGenerator := TIntIdGenerator.Create;
//  FRequestIdGenerator := TIntIdGenerator.Create;
//  FBrowserRequestInfoList:= TBrowserRequestInfoMap.Create;
//
//  FQueryMessageName := Format('%s%s', [FConfig.js_query_function, kMessageSuffix]);
//  FCancelMessageName := Format('%s%s', [FConfig.js_cancel_function, kMessageSuffix]);
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.CreateHandler(
//  router: TMessageRouterRendererSideVarArgs;
//  config: TCefMessageRouterConfig): TRendererV8Handler;
//begin
//  Result := TRendererV8Handler.Create(router, config);
//end;
//
//function TMessageRouterRendererSideVarArgs.CreateIDForContext(context: ICefv8Context): Integer;
//begin
//  Assert(GetIDForContext(context, false)= kReservedId);
//  Result := FContextIdGenerator.GetNextId();
//  FContextList.Add(Result, context);
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//destructor TMessageRouterRendererSideVarArgs.Destroy;
//begin
//  FreeAndNil(FContextList);
//  FreeAndNil(FContextIdGenerator);
//  FreeAndNil(FRequestIdGenerator);
//
//  inherited;
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//procedure TMessageRouterRendererSideVarArgs.ExecuteFailureCallback(browser_id,
//  context_id, request_id, error_code: Integer; error_message: ustring);
//var
//  removed: Boolean;
//  info: PRequestInfo;
//  context: ICefv8Context;
//  args: TCefv8ValueArray;
//begin
//  inherited;
//  // CEF_REQUIRE_RENDERER_THREAD();
//  // -TODO: -oJCH: I see BCR ass calling convention, but BRC as implementation...
//  info := GetRequestInfo(browser_id, context_id, request_id, True, removed);
//  if not(Assigned(info)) then
//    Exit;
//
//  context := GetContextByID(context_id);
//
//  if Assigned(context) and Assigned(info.failure_callback) then
//    begin
//    SetLength(args, 2);
//    args[0] := TCefV8ValueRef.NewInt(error_code);
//    args[1] := TCefV8ValueRef.NewString(error_message);
//    info.failure_callback.ExecuteFunctionWithContext(context, nil, args);
//    end;
//
//  Assert(removed);
//
//  Dispose(info);
//
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//procedure TMessageRouterRendererSideVarArgs.ExecuteSuccessCallback(browser_id,
//  context_id, request_id: Integer; response: ICefValue);
//var
//  removed: Boolean;
//  info: PRequestInfo;
//  context: ICefv8Context;
//  args: TCefv8ValueArray;
//begin
////  inherited;
//  // CEF_REQUIRE_RENDERER_THREAD();
//  // -TODO: -oJCH: I see BCR as calling convention, but BRC as implementation...
//  info := GetRequestInfo(browser_id, context_id, request_id, False, removed);
//  if not(Assigned(info)) then
//    Exit;
//
//  context := GetContextByID(context_id);
//
//  if Assigned(context) and Assigned(info.success_callback) then
//    begin
//    SetLength(args, 1);
//    context.Enter;
//    try
//      args[0] := CefValueToCefV8Value(response);
//    finally
//      context.Exit;
//    end;
//    info.success_callback.ExecuteFunctionWithContext(context, nil, args);
//    end;
//
//  if removed then
//    Dispose(info);
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.GetContextByID(context_id: Integer): ICefv8Context;
//begin
//  if not FContextList.TryGetValue(context_id, Result) then
//    Result := nil;
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.GetIDForContext(context: ICefv8Context; remove: Boolean): Integer;
//var
//  pair: TPair<Integer,ICefv8Context>;
//begin
//  for pair in FContextList do
//    if pair.Value.IsSame(context) then
//      begin
//      Result := pair.Key;
//      if remove then
//        FContextList.Remove(Result);
//      end;
//  Result := kReservedId;
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.GetPendingCount(browser: ICefBrowser; context: ICefV8Context): Integer;
//var
//  context_id: Integer;
//  visitor: TBrowserRequestInfoMap.TVisitorGetCount;
//begin
//  // CEF_REQUIRE_RENDERER_THREAD();
//  if FBrowserRequestInfoList.Empty() then
//    Exit(0);
//
//  if Assigned(context) and context.IsValid then
//    begin
//    context_id := GetIDForContext(context, False);
//
//    if (context_id = kReservedId) then
//      Exit(0);
//
//    visitor := TBrowserRequestInfoMap.TVisitorGetCount.Create(context_id);
//
//    if Assigned(browser) then
//      FBrowserRequestInfoList.FindAll(browser.Identifier, visitor)
//    else
//      FBrowserRequestInfoList.FindAll(visitor);
//
//    Exit(visitor.Count);
//    end
//  else if Assigned(browser) then
//    Exit(FBrowserRequestInfoList.Size(browser.Identifier))
//  else
//    Exit(FBrowserRequestInfoList.Size);
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.GetRequestInfo(browser_id:Integer; context_id: integer;request_id: Integer; always_remove: Boolean;
//  var removed: Boolean): PRequestInfo;
//var
//  visitor: TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove;
//begin
//  visitor := TBrowserRequestInfoMap.TVisitorGetItemOptionalRemove.Create(always_remove);
//  Result := FBrowserRequestInfoList.Find(browser_id, TBrowserRequestInfoMapIdType.Create(context_id, request_id) , visitor);
//  if Assigned(Result) then
//    removed := visitor.Removed;
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//procedure TMessageRouterRendererSideVarArgs.OnContextCreated(browser: ICefBrowser;
//  frame: ICefFrame; context: ICefV8Context);
//var
//  window: ICefv8Value;
//  handler: TRendererV8Handler;
//  query_func : ICefV8Value;
//  cancel_func : ICefV8Value;
//begin
//  inherited;
//  //CEF_REQUIRE_RENDERER_THREAD();
//
//  window := context.Global;
//  handler := CreateHandler(Self, FConfig);
//  query_func := TCefv8ValueRef.NewFunction(FConfig.js_query_function, handler);
//
//  (* typedef enum {
//  V8_PROPERTY_ATTRIBUTE_NONE = 0,            // Writeable, Enumerable,
//                                             //   Configurable
//  V8_PROPERTY_ATTRIBUTE_READONLY = 1 << 0,   // Not writeable
//  V8_PROPERTY_ATTRIBUTE_DONTENUM = 1 << 1,   // Not enumerable
//  V8_PROPERTY_ATTRIBUTE_DONTDELETE = 1 << 2  // Not configurable
//  } cef_v8_propertyattribute_t;*)
//
//  //TCefV8PropertyAttributes
//  window.SetValueByKey(FConfig.js_query_function, query_func, 7 (*V8_PROPERTY_ATTRIBUTE_READONLY|V8_PROPERTY_ATTRIBUTE_DONTENUM|V8_PROPERTY_ATTRIBUTE_DONTDELETE*));
//
//  cancel_func := TCefv8ValueRef.NewFunction(FConfig.js_cancel_function, handler);
//  window.SetValueByKey(FConfig.js_cancel_function, cancel_func, 7 (*V8_PROPERTY_ATTRIBUTE_READONLY|V8_PROPERTY_ATTRIBUTE_DONTENUM|V8_PROPERTY_ATTRIBUTE_DONTDELETE*));
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//procedure TMessageRouterRendererSideVarArgs.OnContextReleased(browser: ICefBrowser;
//  frame: ICefFrame; context: ICefV8Context);
//var
//  context_id: Integer;
//begin
//  inherited;
//  //CEF_REQUIRE_RENDERER_THREAD();
//  context_id := GetIDForContext(context, true);
//  if (context_id <> kReservedId) then
//    SendCancel(browser, context_id, kReservedId);
//
//
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.OnProcessMessageReceived(
//  browser: ICefBrowser; process: TCefProcessId;
//  message: ICefProcessMessage): Boolean;
//var
//  message_name: ustring;
//  args: ICefListValue;
//  context_id: Integer;
//  request_id: Integer;
//  is_success: Boolean;
//  response: ICefValue;
//  error_code: Integer;
//  error_message: ustring;
//  lst: ICefListValue;
//  localmessage: ICefProcessMessage;
//begin
//  // CEF_REQUIRE_RENDERER_THREAD();
//  message_name := message.Name;
//
//  if (message_name = FQueryMessageName) then
//    begin
//    args := message.ArgumentList;
//    Assert(args.GetSize > 3);
//
//    context_id := args.GetInt(0);
//    request_id := args.GetInt(1);
//    is_success := args.GetBool(2);
//
//    if is_success then
//      begin
//      Assert(args.GetSize = 4);
//      localmessage := message.Copy;
//      args := localmessage.ArgumentList;
//      response := args.GetValue(3);
//      CefPostTask(TID_RENDERER, TCefFastTask.Create(procedure()
//        begin
//        ExecuteSuccessCallback(browser.Identifier, context_id, request_id, response);
//        localmessage := nil;
//        end));
//      end
//    else
//      begin
//      Assert(args.GetSize = 5);
//      error_code := args.GetInt(3);
//      error_message := args.GetString(4);
//      CefPostTask(TID_RENDERER, TCefFastTask.Create(procedure()
//        begin
//        ExecuteFailureCallback(browser.Identifier, context_id, request_id, error_code, error_message);
//        end));
//      end;
//
//      Exit(True);
//    end;
//    Exit(False);
//end;
//
//
//{ TMessageRouterRendererSideVarArgs.TRendererV8Handler }
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//constructor TMessageRouterRendererSideVarArgs.TRendererV8Handler.Create(
//  router: TMessageRouterRendererSideVarArgs; config: TCefMessageRouterConfig);
//begin
//  inherited Create;
//  FRouter := router;
//  FConfig := config;
//  FContextId := kReservedId;
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.TRendererV8Handler.Execute(
//  const name: ustring; const obj: ICefv8Value;
//  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
//  var exception: ustring): Boolean;
//var
//  arg: ICefV8Value;
//  requestVal: ICefV8Value;
//  successVal: ICefV8Value;
//  failureVal: ICefV8Value;
//  persistentVal: ICefV8Value;
//
//  context: ICefV8Context;
//  context_id: Integer;
//  frame_id: Int64;
//  is_main_frame: Boolean;
//  persistent: Boolean;
//  request_id: Integer;
//
////  request_args: ICefListValue;
//begin
//  successVal := nil;
//  failureVal := nil;
//
//  if (name = FConfig.js_query_function) then
//    begin
//    if (Length(arguments) <> 1) or not(arguments[0].IsObject()) then
//      begin
//      exception := 'Invalid arguments; expecting a single object';
//      Exit(true);
//      end;
//
//    arg := arguments[0];
//    requestVal := arg.GetValueByKey(kMemberRequest);
//    if not(Assigned(requestVal)) or requestVal.IsUndefined then
//      begin
//
//      if requestVal.IsNull then
//        OutputDebugString(PChar('IsNull = True'));
//      if requestVal.IsObject then
//        OutputDebugString(PChar('IsObject = True'));
//      if requestVal.IsUndefined then
//        OutputDebugString(PChar('IsUndefined = True'));
//      exception := Format('Invalid arguments; object member "%s" is required', [kMemberRequest]);
//      Exit(true);
//      end;
//
//    if arg.HasValueByKey(kMemberOnSuccess) then
//      begin
//      successVal := arg.GetValueByKey(kMemberOnSuccess);
//      if not successVal.IsFunction then
//        begin
//        exception := Format('Invalid arguments; object member "%s" must have type function', [kMemberOnSuccess]);
//        Exit(true);
//        end;
//      end;
//
//    if arg.HasValueByKey(kMemberOnFailure) then
//      begin
//      failureVal := arg.GetValueByKey(kMemberOnFailure);
//      if not failureVal.IsFunction then
//        begin
//        exception := Format('Invalid arguments; object member "%s" must have type function', [kMemberOnFailure]);
//        Exit(true);
//        end;
//      end;
//
//    if arg.HasValueByKey(kMemberPersistent) then
//      begin
//      persistentVal := arg.GetValueByKey(kMemberPersistent);
//      if not persistentVal.IsBool then
//        begin
//        exception := Format('Invalid arguments; object member "%s" must have type boolean', [kMemberPersistent]);
//        Exit(true);
//        end;
//      end;
//
//
//    context := TCefV8ContextRef.Current;
//    context_id := GetIDForContext(context);
//    frame_id := context.Frame.Identifier;
//    is_main_frame := context.Frame.IsMain;
//    persistent := Assigned(persistentVal) and persistentVal.GetBoolValue();
//
//    //request_args := TCefListValueRef.New;
//    //requestVal.GetKeys();
//    // ?
//    request_id := FRouter.SendQuery(context.Browser, frame_id, is_main_frame, context_id, requestVal, persistent, successVal, failureVal);
//    retVal := TCefV8ValueRef.NewInt(request_id);
//    Exit(true);
//    end
//  else if (name = FConfig.js_cancel_function) then
//    begin
//    if (Length(arguments) <> 1) or not(arguments[0].IsInt()) then
//      begin
//      exception := 'Invalid arguments; expecting a single integer';
//      Exit(true);
//      end;
//
//    Result := False;
//    request_id := arguments[0].GetIntValue;
//    if (request_id <> kReservedId) then
//      begin
//      context := TCefV8ContextRef.Current;
//      context_id := GetIDForContext(context);
//      Result := FRouter.SendCancel(context.Browser, context_id, request_id);
//      end;
//
//    retVal := TCefV8ValueRef.NewBool(Result);
//    Exit(True);
//    end;
//
//  Result := False;
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.TRendererV8Handler.GetIDForContext(
//  context: ICefv8Context): Integer;
//begin
//  if FContextId = kReservedId then
//    FContextId := FRouter.CreateIDForContext(context);
//  Result := FContextId;
//end;
//
////procedure TMessageRouterRendererSideVarArgs.TRendererV8Handler.ValueToListValue(
////  arg: ICefV8Value; request_args: ICefListValue);
////var
////  TempKeys : TStringList;
////  i, j: Integer;
////  TempValue : ICefValue;
////begin
////  TempKeys := TStringList.Create;
////  try
////    arg.GetKeys(TempKeys);
////    i := 0;
////    j := TempKeys.Count;
////
////    while (i < j) do
////      begin
////      TempValue := arg.GetValueByKey(TempKeys[i]);
////
////      request_args.
////      inc(i);
////      end;
////
////  finally
////    FreeAndNil(TempKeys);
////  end;
////end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.SendCancel(browser: ICefBrowser; context_id,
//  request_id: Integer): Boolean;
//var
//  browser_id: Integer;
//  cancel_count: Integer;
//  removed: Boolean;
//  info: PRequestInfo;
//  visitor: TBrowserRequestInfoMap.TVisitorCancelAllInContext;
//  message: ICefProcessMessage;
//  args: ICefListValue;
//begin
//  browser_id := browser.Identifier;
//  cancel_count := 0;
//
//  if (request_id <> kReservedId) then
//    begin
//    info := GetRequestInfo(browser_id, context_id, request_id, true, removed);
//    if Assigned(info) then
//      begin
//      Dispose(info);
//      cancel_count := 1;
//      end;
//
//    end
//  else
//    begin
//    visitor := TBrowserRequestInfoMap.TVisitorCancelAllInContext.Create(context_id);
//    FBrowserRequestInfoList.FindAll(browser_id, visitor);
//    cancel_count := visitor.CancelCount;
//    FreeAndNil(visitor);
//    end;
//
//  if cancel_count > 0 then
//    begin
//    message := TCefProcessMessageRef.New(FCancelMessageName);
//    args := message.ArgumentList;
//    args.SetInt(0, context_id);
//    args.SetInt(1, request_id);
//    browser.SendProcessMessage(PID_BROWSER, message);
//    Exit(True);
//    end;
//
//  Exit(False);
//end;
//
//{-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------}
//function TMessageRouterRendererSideVarArgs.SendQuery(
//  browser: ICefBrowser; frame_id: Int64; is_main_frame: Boolean;
//  context_id: Integer; request: ICefV8Value; persistent: Boolean; success_callback,
//  failure_callback: ICefV8Value): Integer;
//var
//  info: PRequestInfo;
//  message: ICefProcessMessage;
//  args: ICefListValue;
//begin
//  Result := FRequestIdGenerator.GetNextId;
//  New(info);
//
//  info.persistent := persistent;
//  info.success_callback := success_callback;
//  info.failure_callback := failure_callback;
//
//  FBrowserRequestInfoList.Add(browser.Identifier,TBrowserRequestInfoMapIdType.Create(context_id, Result),  info);
//
//  message := TCefProcessMessageRef.New(FQueryMessageName);
//  args := message.ArgumentList;
//  args.SetInt(0, CefInt64GetLow(frame_id));
//  args.SetInt(1, CefInt64GetHigh(frame_id));
//  args.SetBool(2, is_main_frame);
//  args.SetInt(3, context_id);
//  args.SetInt(4, Result (*request_id*));
//  args.SetValue(5, CefV8ValueToCefValue(request));
//  args.SetBool(6, persistent);
//
//  browser.SendProcessMessage(PID_BROWSER, message);
//
//end;


//initialization
//  MessageRouterConfig := DefaultConfig;
//  MessageRouter:= TMessageRouterRendererSide.Create(MessageRouterConfig);
//  MessageRouterConfigOnProductSelected := DefaultConfigOnProductSelected;
//  MessageRouterOnProductSelected:= TMessageRouterRendererSide.Create(MessageRouterConfigOnProductSelected);
//  MessageRouterConfigOnTabChanged:= DefaultConfigOnTabChanged;
//  MessageRouterOnTabChanged := TMessageRouterRendererSide.Create(MessageRouterConfigOnTabChanged);
//  MessageRouterConfigElevation:= DefaultConfigElevation;
//  MessageRouterElevation := TMessageRouterRendererSideVarArgs.Create(MessageRouterConfigElevation);
//  MessageRouterConfigPowerFrequency := DefaultConfigPowerFrequency;
//  MessageRouterPowerFrequency := TMessageRouterRendererSideVarArgs.Create(MessageRouterConfigPowerFrequency);
//finalization
//  FreeAndNil(MessageRouter);
//  FreeAndNil(MessageRouterOnProductSelected);
//  FreeAndNil(MessageRouterOnTabChanged);
//  FreeAndNil(MessageRouterElevation);
//  FreeAndNil(MessageRouterPowerFrequency);

end.
