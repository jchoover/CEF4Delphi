unit cef_message_router_browser;
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

uses
  uCEFTypes, uCEFInterfaces, cef_message_router, Generics.Collections;

type

  (*type*) TBrowserQueryInfoMapIdType = Int64;



  TCefMessageRouterBrowserSideValue = TCefMessageRouterBrowserSide<ICefValue, ICefValue>;


  TMessageRouterBrowserSide = class(TCefMessageRouterBrowserSideValue)
  public
    type
    TCefHandlerSet = class(TList<TCefMessageRouterBrowserSideValue.TCefHandler>)
    public
      function Empty: Boolean;
    end;

  type
    TBrowserQueryInfoMapObjectType = TCefMessageRouterBrowserSideValue.PQueryInfo;

    TBrowserQueryInfoMap = class(TCefBrowserInfoMap<TBrowserQueryInfoMapIdType, TBrowserQueryInfoMapObjectType>)
    protected
      procedure Destruct(info: TBrowserQueryInfoMapObjectType); override;
    public
      type
        TVisitorGetCount = class(TVisitor)
        private
          FHandler: TCefMessageRouterBrowserSideValue.TCefHandler;
          FCount: Integer;
        public
          constructor Create(handler: TCefMessageRouterBrowserSideValue.TCefHandler);
          function OnNextInfo(browser_id: Integer; info_id: TBrowserQueryInfoMapIdType; info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean; override;
          property Count: Integer read FCount;
        end;
        TVisitorCancelQuery = class(TVisitor)
        private
          FRouter: TCefMessageRouterBrowserSideValue;
          FContextId: Integer;
          FRequestId: Integer;

        public
          constructor Create(router: TCefMessageRouterBrowserSideValue; context_id: Integer; request_id: Integer);
          function OnNextInfo(browser_id: Integer; info_id: TBrowserQueryInfoMapIdType; info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean; override;
        end;

        TVisitorCancelPendingFor = class(TVisitor)
        private
          FRouter: TCefMessageRouterBrowserSideValue;
          FHandler: TCefMessageRouterBrowserSideValue.TCefHandler;
          FNotifyRenderer: Boolean;
        public
          constructor Create(router: TCefMessageRouterBrowserSideValue; handler: TCefMessageRouterBrowserSideValue.TCefHandler; notify_renderer: Boolean);
          function OnNextInfo(browser_id: Integer; info_id: TBrowserQueryInfoMapIdType; info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean; override;

        end;

        TVisitorGetQueryinfo = class(TVisitor)
        private
          FAlwaysRemove: Boolean;
          FRemoved: Boolean;
        public
          constructor Create(always_remove: Boolean);
          function OnNextInfo(browser_id: Integer; info_id: TBrowserQueryInfoMapIdType; info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean; override;
          property Removed: Boolean read FRemoved;
        end;

        TVisitorDump = class(TVisitor)
        public
          function OnNextInfo(browser_id: Integer; info_id: TBrowserQueryInfoMapIdType; info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean; override;
        end;
    end;

  private
    FConfig: TCefMessageRouterConfig;
    FQueryMessageName: String;
    FCancelMessageName: String;
    FBrowserQueryInfoList: TBrowserQueryInfoMap;
    FHandelerSet: TCefHandlerSet;
    FQueryIdGenerator: TInt64IdGenerator;
  private
    procedure SendQuerySuccess(info: TCefMessageRouterBrowserSideValue.PQueryInfo ; response: ICefValue); overload;
    procedure SendQueryFailure(info: TCefMessageRouterBrowserSideValue.PQueryInfo ;error_code: Integer; error_message: ustring); overload;
    procedure SendQueryFailure(browser: ICefbrowser; context_id: Integer; request_id: Integer; error_code: Integer; error_message: ustring); overload;
    procedure CancelUnhandledQuery(browser: ICefBrowser; context_id: Integer; request_id: Integer);
  protected
    procedure CancelPendingFor(browser: ICefBrowser; handler: TCefMessageRouterBrowserSideValue.TCefHandler; notify_renderer: Boolean);override;
    function GetQueryInfo(browser_id: Integer; query_id: Int64; always_remove: Boolean; var removed: Boolean): TCefMessageRouterBrowserSideValue.PQueryInfo;
    procedure OnCallbackSuccess(browser_id: Integer; query_id: Int64; response: ICefValue); override;
    procedure OnCallbackFailure(browser_id: Integer; query_id: Int64; error_code: Integer; error_message: ustring); override;
    procedure SendQuerySuccess(browser: ICefbrowser; context_id: Integer; request_id: Integer; response: ICefValue); overload; virtual;
    property HandelerSet: TCefHandlerSet read FHandelerSet;
  public
    type TCallback = class(TCefCallback)
    private
      FRouter: TMessageRouterBrowserSide;
      FBrowserId: Integer;
      FQueryId: Int64;
      FPersistent: Boolean;
    public
      constructor Create(router: TMessageRouterBrowserSide; browser_id: Integer; query_id: Int64; persistent: Boolean);
      destructor Destroy; override;

      procedure Success(response: ICefValue); override;
      procedure Failure(error_code: Integer; error_message: ustring); override;
      procedure Detach; override;

    end;
  public
    constructor Create(config: TCefMessageRouterConfig);
    destructor Destroy; override;

    function AddHandler(handler: TCefMessageRouterBrowserSideValue.TCefHandler; first: Boolean): Boolean; override;
    function RemoveHandler(handler: TCefMessageRouterBrowserSideValue.TCefHandler): Boolean; override;
    procedure CancelPending(browser: ICefBrowser; handler: TCefMessageRouterBrowserSideValue.TCefHandler); override;
    function GetPendingCount(browser: ICefBrowser; handler: TCefMessageRouterBrowserSideValue.TCefHandler): Integer; override;
    procedure CancelPendingRequest(browser_id: Integer; context_id: Integer; request_id: Integer);
    procedure CancelQuery(query_id: Int64; info: TCefMessageRouterBrowserSideValue.PQueryInfo; notify_renderer: Boolean); override;

    procedure OnBeforeClose(browser: ICefBrowser); override;
    procedure OnRenderProcessTerminated(browser: ICefBrowser); override;
    procedure OnBeforeBrowse(browser: ICefBrowser; frame: ICefFrame); override;
    function OnProcessMessageReceived(browser: ICefBrowser; source_process: TCefProcessId; message: ICefProcessMessage): Boolean; override;
  end;

//  TMessageRouterBrowserSideString = class(TMessageRouterBrowserSide<ustring, ustring>)
//  private
//    procedure SendQuerySuccess(browser: ICefbrowser; context_id: Integer; request_id: Integer; response: ustring); override;
//  public
//    function OnProcessMessageReceived(browser: ICefBrowser; source_process: TCefProcessId; message: ICefProcessMessage): Boolean; override;
//  end;
//  TMessageRouterBrowserSideVarArg = class(TMessageRouterBrowserSide<ICefValue, ICefValue>)
//  protected
//    procedure SendQuerySuccess(browser: ICefbrowser; context_id: Integer; request_id: Integer; response: ICefValue); override;
//  public
//    function OnProcessMessageReceived(browser: ICefBrowser; source_process: TCefProcessId; message: ICefProcessMessage): Boolean; override;
//  end;
(*
procedure CefBrowserProcess_OnBeforeClose(browser: ICefBrowser);
procedure CefBrowserProcess_OnRenderProcessTerminated(browser: ICefBrowser);
procedure CefBrowserProcess_OnBeforeBrowse(browser: ICefBrowser; frame: ICefFrame);
procedure CefBrowserProcess_OnProcessMessageReceived(const browser: ICefBrowser; sourceProcess: TCefProcessId; const message: ICefProcessMessage; var aHandled : boolean);
*)

implementation

uses
  uCEFMiscFunctions, uCefLibFunctions, uCefTask, uCefProcessmessage, SysUtils,
  uCefConstants, CefCapsCommon;

(*
var
  MessageRouterConfig: TCefMessageRouterConfig;
  MessageRouter: TMessageRouterBrowserSide;

{ TMessageRouterBrowserSide.TCallback }
procedure CefBrowserProcess_OnBeforeClose(browser: ICefBrowser);
begin
  MessageRouter.OnBeforeClose(browser);
end;

procedure CefBrowserProcess_OnRenderProcessTerminated(browser: ICefBrowser);
begin
  MessageRouter.OnRenderProcessTerminated(browser);
end;

procedure CefBrowserProcess_OnBeforeBrowse(browser: ICefBrowser; frame: ICefFrame);
begin
  MessageRouter.OnBeforeBrowse(browser, frame);
end;

procedure CefBrowserProcess_OnProcessMessageReceived(const browser: ICefBrowser; sourceProcess: TCefProcessId; const message: ICefProcessMessage; var aHandled : boolean);
begin
  MessageRouter.OnProcessMessageReceived(browser, sourceProcess, message);
end;
*)
constructor TMessageRouterBrowserSide.TCallback.Create(
  router: TMessageRouterBrowserSide; browser_id: Integer; query_id: Int64;
  persistent: Boolean);
begin
  inherited Create;
  FRouter := router;
  FBrowserId := browser_id;
  FQueryId := query_id;
  FPersistent := persistent;
end;

destructor TMessageRouterBrowserSide.TCallback.Destroy;
begin
  Assert(not(Assigned(FRouter)));
  inherited;
end;

procedure TMessageRouterBrowserSide.TCallback.Detach;
begin
  inherited;
  // CEF_REQUIRE_UI_THREAD();
  FRouter := nil;
end;

procedure TMessageRouterBrowserSide.TCallback.Failure(error_code: Integer;
  error_message: ustring);
var
  Router: TMessageRouterBrowserSide;
begin
  inherited;
  if (Cef_Currently_On(TID_UI) = 0) then
    begin
    CefPostTask(TID_UI, TCefFastTask.Create(procedure()
        begin
        Failure(error_code, error_message);
        end));
      Exit;
    end;

  if Assigned(FRouter) then
    begin
    Router := FRouter;
    CefPostTask(TID_UI, TCefFastTask.Create(procedure()
        begin
        Router.OnCallbackFailure(FBrowserId, FQueryId, error_code, error_message);
        end));

    FRouter := nil;
    end;
end;

procedure TMessageRouterBrowserSide.TCallback.Success(response: ICefValue);
var
  Router: TMessageRouterBrowserSide;
begin
  inherited;
  if (Cef_Currently_On(TID_UI) = 0) then
    begin
    CefPostTask(TID_UI, TCefFastTask.Create(procedure()
        begin
        Success(response);
        end));
      Exit;
    end;

  if Assigned(FRouter) then
    begin
    Router := FRouter;
    CefPostTask(TID_UI, TCefFastTask.Create(procedure()
        begin
        Router.OnCallbackSuccess(FBrowserId, FQueryId, response);
        end));
    if not FPersistent then
      FRouter := nil;
    end;

end;

{ TMessageRouterBrowserSide }

function TMessageRouterBrowserSide.AddHandler(handler: TCefMessageRouterBrowserSideValue.TCefHandler; first: Boolean): Boolean;
begin
  // CEF_REQUIRE_UI_THREAD();
  if not FHandelerSet.Contains(handler) then
    begin
    if first then
      FHandelerSet.Insert(0, handler)
    else
      FHandelerSet.Add(handler);

    Exit(True);
    end;
  Exit(False);

end;

procedure TMessageRouterBrowserSide.CancelPending(browser: ICefBrowser;
  handler: TCefMessageRouterBrowserSideValue.TCefHandler);
begin
  inherited;
  CancelPendingFor(browser, handler, true);
end;


{ TBrowserQueryInfoMap.TVisitorCancelPendingFor }

constructor TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorCancelPendingFor.Create(
  router: TCefMessageRouterBrowserSideValue;
  handler: TCefMessageRouterBrowserSideValue.TCefHandler; notify_renderer: Boolean);
begin
  inherited Create;
  FRouter := router;
  FHandler := handler;
  FNotifyRenderer := notify_renderer;
end;

function TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorCancelPendingFor.OnNextInfo(
  browser_id: Integer; info_id: TBrowserQueryInfoMapIdType;
  info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean;
begin
  if (not Assigned(FHandler) or (info.handler = FHandler)) then
    begin
    remove := True;
    FRouter.CancelQuery(info_id, info, FNotifyRenderer);
    Dispose(info);
    end;
  Result := True;
end;

constructor TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorGetQueryinfo.Create(
  always_remove: Boolean);
begin
  inherited Create;
  FRemoved := false;
  FAlwaysRemove := always_remove;
end;

function TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorGetQueryinfo.OnNextInfo(
  browser_id: Integer; info_id: TBrowserQueryInfoMapIdType;
  info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean;
begin
  remove := (FAlwaysRemove or not info.persistent);
  FRemoved := remove;
  Result := True;
end;

procedure TMessageRouterBrowserSide.CancelPendingFor(browser: ICefBrowser;
  handler: TCefMessageRouterBrowserSideValue.TCefHandler; notify_renderer: Boolean);
var
  visitor: TBrowserQueryInfoMap.TVisitorCancelPendingFor;
begin
  inherited;
  if (Cef_Currently_On(TID_UI) = 0) then
    begin
    CefPostTask(TID_UI, TCefFastTask.Create(procedure()
        begin
        CancelPendingFor(browser, handler, notify_renderer);
        end));
      Exit;
    end;

  if FBrowserQueryInfoList.Empty then
    Exit;

  visitor := TBrowserQueryInfoMap.TVisitorCancelPendingFor.Create(Self, handler, notify_renderer);

  if Assigned(browser) then
    FBrowserQueryInfoList.FindAll(browser.Identifier, visitor)
  else
    FBrowserQueryInfoList.FindAll(visitor);

  FreeAndNil(visitor);
end;

procedure TMessageRouterBrowserSide.CancelPendingRequest(browser_id,
  context_id, request_id: Integer);
var
  visitor: TBrowserQueryInfoMap.TVisitorCancelQuery;
begin
  visitor := TBrowserQueryInfoMap.TVisitorCancelQuery.Create(self, context_id, request_id);
  FBrowserQueryInfoList.FindAll(browser_id, visitor);
  FreeAndNil(visitor);

end;

procedure TMessageRouterBrowserSide.CancelQuery(query_id: Int64;
  info: TCefMessageRouterBrowserSideValue.PQueryInfo; notify_renderer: Boolean);
var
  frame: ICefFrame;
begin
  if (notify_renderer) then
    SendQueryFailure(info, kCanceledErrorCode, kCanceledErrorMessage);

  if(info.is_main_frame) then
    frame := info.browser.MainFrame
  else
    frame := info.browser.GetFrameByident(info.frame_id);

  info.handler.OnQueryCanceled(info.browser, frame, query_id);
  info.callback.Detach;
end;

procedure TMessageRouterBrowserSide.CancelUnhandledQuery(browser: ICefBrowser;
  context_id, request_id: Integer);
begin
  SendQueryFailure(browser, context_id, request_id, kCanceledErrorCode, kCanceledErrorMessage);
end;

constructor TMessageRouterBrowserSide.Create(config: TCefMessageRouterConfig);
begin
  inherited Create;

  FConfig := config;
  FQueryMessageName := Format('%s%s', [FConfig.js_query_function, kMessageSuffix]);
  FCancelMessageName := Format('%s%s', [FConfig.js_cancel_function, kMessageSuffix]);
  FBrowserQueryInfoList := TBrowserQueryInfoMap.Create;
  FHandelerSet := TCefHandlerSet.Create;
  FQueryIdGenerator := TInt64IdGenerator.Create;
end;

destructor TMessageRouterBrowserSide.Destroy;
var
  visitor: TBrowserQueryInfoMap.TVisitorDump;
begin
  if not FBrowserQueryInfoList.Empty then
    begin
    // Whats in here...
    visitor:= TBrowserQueryInfoMap.TVisitorDump.Create;
    try
      FBrowserQueryInfoList.FindAll(visitor);
    finally
      FreeAndNil(visitor);
    end;
    end;
  Assert(FBrowserQueryInfoList.Empty);
  FreeAndNil(FBrowserQueryInfoList);
  FreeAndNil(FHandelerSet);
  FreeAndNil(FQueryIdGenerator);
  inherited;
end;

function TMessageRouterBrowserSide.GetPendingCount(browser: ICefBrowser;
  handler: TCefMessageRouterBrowserSideValue.TCefHandler): Integer;
var
  visitor: TBrowserQueryInfoMap.TVisitorGetCount;
begin
  // CEF_REQUIRE_UI_THREAD();
  if FBrowserQueryInfoList.Empty then
    Exit(0);

  if Assigned(handler) then
    begin
    visitor := TBrowserQueryInfoMap.TVisitorGetCount.Create(handler);
    if Assigned(browser) then
      FBrowserQueryInfoList.FindAll(browser.Identifier, visitor)
    else
      FBrowserQueryInfoList.FindAll(visitor);

    Result := visitor.Count;
    FreeAndNil(visitor);
    end
  else if Assigned(browser) then
    begin
    Result := FBrowserQueryInfoList.Size(browser.Identifier);

    end
  else
    Result := FBrowserQueryInfoList.Size;
end;

procedure TMessageRouterBrowserSide.OnBeforeBrowse(browser: ICefBrowser;
  frame: ICefFrame);
begin
  inherited;
  if frame.IsMain then
    CancelPendingFor(browser, nil, false);
end;

procedure TMessageRouterBrowserSide.OnBeforeClose(browser: ICefBrowser);
begin
  inherited;
  CancelPendingFor(browser, nil, false);
end;

function TMessageRouterBrowserSide.GetQueryInfo(browser_id: Integer; query_id: Int64; always_remove: Boolean; var removed: Boolean): TCefMessageRouterBrowserSideValue.PQueryInfo;
var
  visitor: TBrowserQueryInfoMap.TVisitorGetQueryinfo;
begin
  visitor := TBrowserQueryInfoMap.TVisitorGetQueryinfo.Create(always_remove);
  Result := FBrowserQueryInfoList.Find(browser_id, query_id, visitor);

  if Assigned(result) then
    removed := visitor.Removed;
  FreeAndNil(Visitor);

end;


procedure TMessageRouterBrowserSide.OnCallbackSuccess(browser_id: Integer; query_id: Int64; response: ICefValue);
var
  removed: Boolean;
  info: PQueryInfo;
begin
  // CEF_REQUIRE_UI_THREAD();
  info := GetQueryInfo(browser_id, query_id, false, removed);

  if Assigned(info) then
    begin
    SendQuerySuccess(info, response);
    if removed then
      Dispose(info);
    end;
end;

procedure TMessageRouterBrowserSide.OnCallbackFailure(browser_id: Integer; query_id: Int64; error_code: Integer; error_message: ustring);
var
  removed: Boolean;
  info: PQueryInfo;
begin
  // CEF_REQUIRE_UI_THREAD();
  info := GetQueryInfo(browser_id, query_id, false, removed);

  if Assigned(info) then
    begin
    SendQueryFailure(info, error_code, error_message);
    Dispose(info);
    end;
end;


function TMessageRouterBrowserSide.OnProcessMessageReceived(
  browser: ICefBrowser; source_process: TCefProcessId;
  message: ICefProcessMessage): Boolean;
var
  message_name: ustring;
  args: ICefListValue;
  frame_id: Int64;
  is_main_frame: Boolean;
  context_id: Integer;
  request_id: Integer;
  message_id: Integer;
  request: ICefValue;
  persistent: Boolean;
  browser_id: Integer;
  query_id: Int64;

  frame: ICefFrame;

  handlerSet: TCefHandlerSet;
  handler: TCefMessageRouterBrowserSideValue.TCefHandler;
  handled: Boolean;
  callback: TCefMessageRouterBrowserSideValue.ICefCallback;

  info: PQueryInfo;
begin
  // CEF_REQUIRE_UI_THREAD();
  message_name := message.Name;
  if (message_name = FQueryMessageName) then
    begin
    args := message.ArgumentList;
    Assert(args.GetSize = 8);

    frame_id := CefInt64Set(args.GetInt(0), args.GetInt(1));
    is_main_frame := args.GetBool(2);
    context_id := args.GetInt(3);
    message_id := args.GetInt(4);
    request_id := args.GetInt(5);
    request := args.GetValue(6);
    persistent := args.GetBool(7);

    if(FHandelerSet.Empty) then
      begin
      CancelUnhandledQuery(browser, context_id, request_id);
      Exit(True);
      end;

    browser_id := browser.Identifier;
    query_id := FQueryIdGenerator.GetNextId;
    if is_main_frame then
      frame := browser.MainFrame
    else
      frame := browser.GetFrameByident(frame_id);

    callback := TCallback.Create(self, browser_id, query_id, persistent);
    handlerSet := TCefHandlerSet.Create(FHandelerSet);
    handled := False;
    handler := nil;

    for handler in handlerSet do
      begin
      handled := handler.OnQuery(browser, frame, query_id, message_id, request, persistent, callback);

      if handled then
        Break;
      end;
    FreeAndNil(handlerSet);

    // ? DCHECK(handled || callback->HasOneRef());

    if handled then
      begin
//      if message_id in [UM_ON_SELECTOR_SAVESTATE, UM_ON_SELECTOR_LOADSTATE] then
//        Exit(True);

      New(info);
      info.browser := browser;
      info.frame_id := frame_id;
      info.is_main_frame := is_main_frame;
      info.context_id := context_id;
      info.request_id := request_id;
      info.message_id := message_id;
      info.persistent := persistent;
      info.callback := callback;
      info.handler := handler;
      FBrowserQueryInfoList.Add(browser_id, query_id, info);
      end
    else
      begin
      callback.Detach;
      CancelUnhandledQuery(browser , context_id, request_id);
      // FreeAndNil(callback);
      end;

    Exit(True);
    end
  else if (message_name = FCancelMessageName) then
    begin
    args := message.ArgumentList;
    Assert(args.GetSize = 2);
    browser_id := browser.Identifier;
    context_id := args.GetInt(0);
    request_id := args.GetInt(1);
    CancelPendingRequest(browser_id, context_id, request_id);
    Exit(True);
    end;

  Exit(False);
end;

procedure TMessageRouterBrowserSide.OnRenderProcessTerminated(
  browser: ICefBrowser);
begin
  inherited;
  CancelPendingFor(browser, nil, false);
end;

function TMessageRouterBrowserSide.RemoveHandler(handler: TCefMessageRouterBrowserSideValue.TCefHandler): Boolean;
begin
  // CEF_REQUIRE_UI_THREAD();
  if FHandelerSet.Remove(handler) > -1 then
    begin
    CancelPendingFor(nil, handler, true);
    Exit(True)
    end;
  Exit(False);
end;

procedure TMessageRouterBrowserSide.SendQueryFailure(
  info: TCefMessageRouterBrowserSideValue.PQueryInfo; error_code: Integer;
  error_message: ustring);
begin
  SendQueryFailure(info.browser, info.context_id, info.request_id, error_code, error_message);
end;

procedure TMessageRouterBrowserSide.SendQueryFailure(browser: ICefbrowser;
  context_id, request_id, error_code: Integer; error_message: ustring);
var
  message: ICefProcessMessage;
  args: ICefListValue;
begin
  message := TCefProcessMessageRef.New(FQueryMessageName);
  args := message.ArgumentList;
  args.SetInt(0, context_id);
  args.SetInt(1, request_id);
  args.SetBool(2, false);
  args.SetInt(3, error_code);
  args.SetString(4, error_message);
  browser.MainFrame.SendProcessMessage(PID_RENDERER, message);
end;

procedure TMessageRouterBrowserSide.SendQuerySuccess(browser: ICefbrowser;
  context_id, request_id: Integer; response: ICefValue);
var
  message: ICefProcessMessage;
  args: ICefListValue;
begin
  message := TCefProcessMessageRef.New(FQueryMessageName);
  args := message.ArgumentList;
  args.SetInt(0, context_id);
  args.SetInt(1, request_id);
  args.SetBool(2, true);
  args.SetValue(3, response);
  browser.MainFrame.SendProcessMessage(PID_RENDERER, message);
end;


procedure TMessageRouterBrowserSide.SendQuerySuccess(info: TCefMessageRouterBrowserSideValue.PQueryInfo ; response: ICefValue);
begin
  SendQuerySuccess(info.browser, info.context_id, info.request_id, response);
end;

{ TBrowserQueryInfoMap.TVisitorGetCount }

constructor TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorGetCount.Create(
  handler: TCefMessageRouterBrowserSideValue.TCefHandler);
begin
  inherited Create;
  FHandler := handler;
  FCount := 0;
end;

function TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorGetCount.OnNextInfo(browser_id: Integer;
  info_id: TBrowserQueryInfoMapIdType; info: TBrowserQueryInfoMapObjectType;
  var remove: Boolean): Boolean;
begin
  if info.handler = FHandler then
    Inc(FCount);

  Result := True;
end;

{ TCefHandlerSet }

function TMessageRouterBrowserSide.TCefHandlerSet.Empty: Boolean;
begin
  Result := Count = 0;
end;

{ TBrowserQueryInfoMap.TVisitorCancelQuery }

constructor TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorCancelQuery.Create(
  router: TCefMessageRouterBrowserSideValue; context_id, request_id: Integer);
begin
  inherited Create;
  FRouter := router;
  FContextId := context_id;
  FRequestId := request_id;
end;

function TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorCancelQuery.OnNextInfo(
  browser_id: Integer; info_id: TBrowserQueryInfoMapIdType;
  info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean;

begin
  if (info.context_id = FContextId) and ((FRequestId = kReservedId) or (info.request_id = FRequestId)) then
    begin
    remove := true;
    FRouter.CancelQuery(info_id, info, false);
    Dispose(info);
    Exit(FRequestId = kReservedId);
    end;
    Exit(True);
end;

{ TBrowserQueryInfoMap }

procedure TMessageRouterBrowserSide.TBrowserQueryInfoMap.Destruct(info: TBrowserQueryInfoMapObjectType);
begin
  inherited;
  Dispose(info);
end;

(*
initialization
  MessageRouterConfig := DefaultConfig;
  MessageRouter:= TMessageRouterBrowserSide.Create(MessageRouterConfig);
finalization
  FreeAndNil(MessageRouter);
*)
{ TMessageRouterBrowserSideString }

//function TMessageRouterBrowserSideString.OnProcessMessageReceived(
//  browser: ICefBrowser; source_process: TCefProcessId;
//  message: ICefProcessMessage): Boolean;
//var
//  message_name: ustring;
//  args: ICefListValue;
//  frame_id: Int64;
//  is_main_frame: Boolean;
//  context_id: Integer;
//  request_id: Integer;
//  request: ustring;
//  persistent: Boolean;
//  browser_id: Integer;
//  query_id: Int64;
//
//  frame: ICefFrame;
//
//  handlerSet: TCefHandlerSet;
//  handler: TCefMessageRouterBrowserSide<ustring, ustring>.TCefHandler;
//  handled: Boolean;
//  callback: TCefMessageRouterBrowserSide<ustring, ustring>.ICefCallback;
//
//  info: PQueryInfo;
//begin
//  // CEF_REQUIRE_UI_THREAD();
//  message_name := message.Name;
//  if (message_name = FQueryMessageName) then
//    begin
//    args := message.ArgumentList;
//    Assert(args.GetSize = 7);
//
//    frame_id := CefInt64Set(args.GetInt(0), args.GetInt(1));
//    is_main_frame := args.GetBool(2);
//    context_id := args.GetInt(3);
//    request_id := args.GetInt(4);
//    request := args.GetString(5);
//    persistent := args.GetBool(6);
//
//    if(FHandelerSet.Empty) then
//      begin
//      CancelUnhandledQuery(browser, context_id, request_id);
//      Exit(True);
//      end;
//
//    browser_id := browser.Identifier;
//    query_id := FQueryIdGenerator.GetNextId;
//    if is_main_frame then
//      frame := browser.MainFrame
//    else
//      frame := browser.GetFrameByident(frame_id);
//
//    callback := TCallback.Create(self, browser_id, query_id, persistent);
//    handlerSet := TCefHandlerSet.Create(FHandelerSet);
//    handled := False;
//    handler := nil;
//
//    for handler in handlerSet do
//      begin
//      handled := handler.OnQuery(browser, frame, query_id, request, persistent, callback);
//
//      if handled then
//        Break;
//      end;
//    FreeAndNil(handlerSet);
//
//    // ? DCHECK(handled || callback->HasOneRef());
//
//    if handled then
//      begin
//      New(info);
//      info.browser := browser;
//      info.frame_id := frame_id;
//      info.is_main_frame := is_main_frame;
//      info.context_id := context_id;
//      info.request_id := request_id;
//      info.persistent := persistent;
//      info.callback := callback;
//      info.handler := handler;
//      FBrowserQueryInfoList.Add(browser_id, query_id, info);
//      end
//    else
//      begin
//      callback.Detach;
//      CancelUnhandledQuery(browser , context_id, request_id);
//      // FreeAndNil(callback);
//      end;
//
//    Exit(True);
//    end
//  else if (message_name = FCancelMessageName) then
//    begin
//    args := message.ArgumentList;
//    Assert(args.GetSize = 2);
//    browser_id := browser.Identifier;
//    context_id := args.GetInt(0);
//    request_id := args.GetInt(1);
//    CancelPendingRequest(browser_id, context_id, request_id);
//    Exit(True);
//    end;
//
//  Exit(False);
//
//end;
//
//procedure TMessageRouterBrowserSideString.SendQuerySuccess(browser: ICefbrowser;
//  context_id, request_id: Integer; response: ustring);
//var
//  message: ICefProcessMessage;
//  args: ICefListValue;
//begin
//  message := TCefProcessMessageRef.New(FQueryMessageName);
//  args := message.ArgumentList;
//  args.SetInt(0, context_id);
//  args.SetInt(1, request_id);
//  args.SetBool(2, true);
//  args.SetString(3, response);
//  browser.SendProcessMessage(PID_RENDERER, message);
//end;

{ TMessageRouterBrowserSideVarArg }
//
//function TMessageRouterBrowserSideVarArg.OnProcessMessageReceived(
//  browser: ICefBrowser; source_process: TCefProcessId;
//  message: ICefProcessMessage): Boolean;
//var
//  message_name: ustring;
//  args: ICefListValue;
//  frame_id: Int64;
//  is_main_frame: Boolean;
//  context_id: Integer;
//  request_id: Integer;
//  message_id: Integer;
//  request: ICefValue;
//  persistent: Boolean;
//  browser_id: Integer;
//  query_id: Int64;
//
//  frame: ICefFrame;
//
//  handlerSet: TCefHandlerSet;
//  handler: TCefMessageRouterBrowserSide<ICefValue, ICefValue>.TCefHandler;
//  handled: Boolean;
//  callback: TCefMessageRouterBrowserSide<ICefValue, ICefValue>.ICefCallback;
//
//  info: PQueryInfo;
//begin
//  // CEF_REQUIRE_UI_THREAD();
//  message_name := message.Name;
//  if (message_name = FQueryMessageName) then
//    begin
//    args := message.ArgumentList;
//    Assert(args.GetSize = 7);
//
//    frame_id := CefInt64Set(args.GetInt(0), args.GetInt(1));
//    is_main_frame := args.GetBool(2);
//    context_id := args.GetInt(3);
//    request_id := args.GetInt(4);
//    message_id := args.GetInt(5);
//    request := args.GetValue(6);
//    persistent := args.GetBool(7);
//
//    if(FHandelerSet.Empty) then
//      begin
//      CancelUnhandledQuery(browser, context_id, request_id);
//      Exit(True);
//      end;
//
//    browser_id := browser.Identifier;
//    query_id := FQueryIdGenerator.GetNextId;
//    if is_main_frame then
//      frame := browser.MainFrame
//    else
//      frame := browser.GetFrameByident(frame_id);
//
//    callback := TCallback.Create(self, browser_id, query_id, persistent);
//    handlerSet := TCefHandlerSet.Create(FHandelerSet);
//    handled := False;
//    handler := nil;
//
//    for handler in handlerSet do
//      begin
//      handled := handler.OnQuery(browser, frame, query_id, message_id, request, persistent, callback);
//
//      if handled then
//        Break;
//      end;
//    FreeAndNil(handlerSet);
//
//    // ? DCHECK(handled || callback->HasOneRef());
//
//    if handled then
//      begin
//      New(info);
//      info.browser := browser;
//      info.frame_id := frame_id;
//      info.is_main_frame := is_main_frame;
//      info.context_id := context_id;
//      info.request_id := request_id;
//      info.message_id := message_id;
//      info.persistent := persistent;
//      info.callback := callback;
//      info.handler := handler;
//      FBrowserQueryInfoList.Add(browser_id, query_id, info);
//      end
//    else
//      begin
//      callback.Detach;
//      CancelUnhandledQuery(browser , context_id, request_id);
//      // FreeAndNil(callback);
//      end;
//
//    Exit(True);
//    end
//  else if (message_name = FCancelMessageName) then
//    begin
//    args := message.ArgumentList;
//    Assert(args.GetSize = 2);
//    browser_id := browser.Identifier;
//    context_id := args.GetInt(0);
//    request_id := args.GetInt(1);
//    CancelPendingRequest(browser_id, context_id, request_id);
//    Exit(True);
//    end;
//
//  Exit(False);
//end;
//
//procedure TMessageRouterBrowserSideVarArg.SendQuerySuccess(browser: ICefbrowser;
//  context_id, request_id: Integer; response: ICefValue);
//var
//  message: ICefProcessMessage;
//  args: ICefListValue;
//begin
//  message := TCefProcessMessageRef.New(FQueryMessageName);
//  args := message.ArgumentList;
//  args.SetInt(0, context_id);
//  args.SetInt(1, request_id);
//  args.SetBool(2, true);
//  args.SetValue(3, response);
//  browser.SendProcessMessage(PID_RENDERER, message);
//
//end;

{ TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorDump }

function TMessageRouterBrowserSide.TBrowserQueryInfoMap.TVisitorDump.OnNextInfo(
  browser_id: Integer; info_id: TBrowserQueryInfoMapIdType;
  info: TBrowserQueryInfoMapObjectType; var remove: Boolean): Boolean;
var
  Msg: String;
begin
  Msg := Format('browser_id: %d, info_id: %d, request_id:%d, message_id: %d, persistent: %s', [browser_id, info_id, info.request_id, info.message_id, BoolToStr(info.persistent, True)]);
  CefDebugLog(Msg, CEF_LOG_SEVERITY_ERROR);
  Result := True;
end;

end.
