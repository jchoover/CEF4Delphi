unit cef_message_router;
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
  uCEFTypes,
  uCEFInterfaces,
  Generics.Collections,
  Generics.Defaults;

type
  TRequestInfo = record
    success_callback: ICefV8Value;
    failure_callback: ICefV8Value;
    persistent: Boolean;
  end;

  PRequestInfo = ^TRequestInfo;

  TCefMessageRouterConfig = record
    js_query_function: ustring;
    js_cancel_function: ustring;
  end;

const
  DefaultConfig: TCefMessageRouterConfig = ( js_query_function : 'cefQuery'; js_cancel_function:'cefQueryCancel';);

  function ValidateConfig(config: TCefMessageRouterConfig): Boolean;

type
  TCefMessageRouterRendererSide<RequestType, ResponseType> = class(TObject)
  protected
    function SendQuery(browser:ICefBrowser; frame_id:Int64; is_main_frame: Boolean;
                context_id: Integer; message_id: Integer; request: RequestType; persistent: Boolean;
                success_callback: ICefV8Value; failure_callback: ICefV8Value): Integer; virtual; abstract;
    function SendCancel(browser:ICefBrowser; context_id: Integer; request_id: Integer):Boolean; virtual; abstract;
    function GetRequestInfo(browser_id: Integer; request_id: Integer; context_id: integer; always_remove: Boolean; var removed: Boolean): PRequestInfo; virtual; abstract;
    procedure ExecuteSuccessCallback(browser_id: Integer; context_id: integer;request_id: Integer; response: ResponseType); virtual; abstract;
    procedure ExecuteFailureCallback(browser_id: Integer; context_id: integer;request_id: Integer; error_code: Integer; error_message: ustring); virtual; abstract;
  public
    function GetPendingCount(browser: ICefBrowser; context: ICefV8Context): Integer; virtual; abstract;
    procedure OnContextCreated(browser: ICefBrowser;frame: ICefFrame; context: ICefV8Context); virtual; abstract;
    procedure OnContextReleased(browser: ICefBrowser;frame: ICefFrame; context: ICefV8Context); virtual; abstract;
    function OnProcessMessageReceived(browser: ICefBrowser; process: TCefProcessId; message: ICefProcessMessage): Boolean; virtual; abstract;
  end;

  TCefMessageRouterBrowserSide<RequestType, ResponseType> = class(TObject)
  public
    type
      ICefCallback = interface(IUnknown)
        ['{F83795BB-05E5-481B-99CA-7073877546BB}']
        procedure Success(response: ResponseType);
        procedure Failure(error_code: Integer; error_message: ustring);
        procedure Detach;
      end;
      TCefCallback = class(TInterfacedObject, ICefCallback)
      public
      procedure Success(response: ResponseType); virtual; abstract;
      procedure Failure(error_code: Integer; error_message: ustring); virtual; abstract;
      procedure Detach; virtual; abstract;
      end;

      TCefHandler = class(TObject)
      public
      function OnQuery(browser: ICefBrowser; frame: ICefFrame; query_id: Int64; message_id: Integer; request: RequestType; persistent: Boolean; callback: ICefCallback): Boolean; virtual; abstract;
      procedure OnQueryCanceled(browser: ICefBrowser; frame: ICefFrame; query_id: Int64); virtual; abstract;
      end;

      TQueryInfo = record
        browser: ICefBrowser;
        frame_id: Int64;
        is_main_frame: Boolean;
        context_id: Integer;
        request_id: Integer;
        message_id: Integer;
        persistent: Boolean;
        callback: ICefCallback;
        handler: TCefHandler;
      end;
      PQueryInfo = ^TQueryInfo;
  protected
    procedure OnCallbackSuccess(browser_id: Integer; query_id: Int64; response: ResponseType); virtual; abstract;
    procedure OnCallbackFailure(browser_id: Integer; query_id: Int64; error_code: Integer; error_message: ustring); virtual; abstract;
    procedure CancelPendingFor(browser: ICefBrowser; handler: TCefHandler; notify_renderer: Boolean); virtual; abstract;
  public
    function AddHandler(handler: TCefHandler; first: Boolean): Boolean; virtual; abstract;
    function RemoveHandler(handler: TCefHandler): Boolean; virtual; abstract;
    procedure CancelPending(browser: ICefBrowser; handler: TCefHandler); virtual; abstract;
    function GetPendingCount(browser: ICefBrowser; handler: TCefHandler): Integer; virtual; abstract;
    procedure CancelQuery(query_id: Int64; info: PQueryInfo; notify_renderer: Boolean); virtual; abstract;

    procedure OnBeforeClose(browser: ICefBrowser); virtual; abstract;
    procedure OnRenderProcessTerminated(browser: ICefBrowser); virtual; abstract;
    procedure OnBeforeBrowse(browser: ICefBrowser; frame: ICefFrame); virtual; abstract;
    function OnProcessMessageReceived(browser: ICefBrowser; source_process: TCefProcessId; message: ICefProcessMessage): Boolean; virtual; abstract;
  end;

  TIntIdGenerator = class(TObject)
  private
    FNextId: Integer;
  public
    constructor Create;
    function GetNextId: Integer;
  end;

  TInt64IdGenerator = class(TObject)
  private
    FNextId: Int64;
  public
    constructor Create;
    function GetNextId: Int64;
  end;
(*
template <typename IdType,
          typename ObjectType,
          typename Traits = DefaultCefBrowserInfoMapTraits<ObjectType>>
class CefBrowserInfoMap {

  // Map IdType to ObjectType instance.
  typedef std::map<IdType, ObjectType> InfoMap;
  // Map browser ID to InfoMap instance.
  typedef std::map<int, InfoMap*> BrowserInfoMap;

  BrowserInfoMap browser_info_map_;

  typedef CefBrowserInfoMap<std::pair<int, int>, RequestInfo*>
      BrowserRequestInfoMap;
  BrowserRequestInfoMap browser_request_info_map_;
*)
  TCefBrowserInfoMap<IdType, ObjectType> = class(TObject)
  protected
    type
      TInfoMap = class(TDictionary<IdType, ObjectType>)
      public
        function Empty: Boolean;
        function Size: Integer;
      end;
      PInfoMap = ^TInfoMap;
      TBrowserInfoMap = class(TDictionary<Integer, TInfoMap>)
      public
        function Empty: Boolean;
      end;
  private
    FBrowserInfoMap: TBrowserInfoMap;
  protected
    //function CreateMap: TInfoMap; virtual;
    procedure Destruct(info: ObjectType); virtual; abstract;
    function GetEqualityComparer: IEqualityComparer<IdType>; virtual;
  public
    type
      InfoIdType = IdType;
    type
      InfoObjectType = ObjectType;
    type
      TVisitor = class(TObject)
      public
        function OnNextInfo(browser_id: Integer; info_id: InfoIdType; info: InfoObjectType; var remove: Boolean): Boolean; virtual; abstract;
      end;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(browser_id: Integer; info_id: IdType; info: ObjectType);
    function Empty: Boolean;
    function Find(browser_id: Integer; info_id: IdType; visitor: TVisitor): ObjectType;
    procedure FindAll(visitor: TVisitor); overload;
    procedure FindAll(browser_id: Integer; visitor: TVisitor); overload;
    function Size: Integer; overload;
    function Size(browser_id: Integer): Integer; overload;
    procedure Clear; overload;
    procedure Clear(browser_id: Integer); overload;
  end;


const
  kMessageSuffix = 'Msg';
  kReservedId = 0;
  kMemberMessage = 'message';
  kMemberRequest = 'request';
  kMemberOnSuccess = 'onSuccess';
  kMemberOnFailure = 'onFailure';
  kMemberPersistent = 'persistent';
  kCanceledErrorCode = -1;
  kCanceledErrorMessage = 'The query has been canceled';

implementation

uses
  SysUtils;

{ TIdGenerator }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TIntIdGenerator.Create;
begin
  FNextId := kReservedId;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TIntIdGenerator.GetNextId: Integer;
begin
  Inc(FNextID);
  if FNextId = kReservedId then
    Inc(FNextID);
  Result := FNextId;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function ValidateConfig(config: TCefMessageRouterConfig): Boolean;
begin
  if(string.IsNullOrEmpty(config.js_query_function) or string.IsNullOrEmpty(config.js_cancel_function)) then
    Result := False
  else
    Result := True;
end;

{ TCefBrowserInfoMap<IdType, ObjectType> }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TCefBrowserInfoMap<IdType, ObjectType>.Add(browser_id: Integer;
  info_id: IdType; info: ObjectType);
var
  info_map: TInfoMap;
begin
  info_map := nil;
  if not (FBrowserInfoMap.TryGetValue(browser_id, info_map)) then
    begin
    info_map := TInfoMap.Create(Self.GetEqualityComparer);
    FBrowserInfoMap.Add(browser_id, info_map);
    end
  else
    begin
    Assert(not(info_map.ContainsKey(info_id)));
    end;

  info_map.Add(info_id, info);
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.Find(browser_id: Integer; info_id: IdType; visitor: TVisitor): ObjectType;
var
  info_map: TInfoMap;
  info: ObjectType;
  remove: Boolean;
begin
  if (FBrowserInfoMap.Empty()) then
    Exit(Default(ObjectType)); // ?

  if not(FBrowserInfoMap.TryGetValue(browser_id, info_map)) then
    Exit(Default(ObjectType)); // ?

  if not(info_map.TryGetValue(info_id, info)) then
    Exit(Default(ObjectType)); // ?

  remove := False;

  if Assigned(visitor) then
    visitor.OnNextInfo(browser_id, info_id, info, remove);

  if remove then
    begin
    info_map.Remove(info_id);

    if info_map.Empty() then
      begin
      FBrowserInfoMap.Remove(browser_id);
      FreeAndNil(info_map);
      end;
    end;

  Result := info;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TCefBrowserInfoMap<IdType, ObjectType>.FindAll(browser_id: Integer;
  visitor: TVisitor);
var
  info_map: TInfoMap;
  info: ObjectType;
  remove: Boolean;
  keepGoing: Boolean;

  info_map_index: Integer;
  info_map_array: TArray<TPair<IdType, ObjectType>>;
  info_id: IdType;
begin
  Assert(Assigned(visitor));

  if (FBrowserInfoMap.Empty()) then
    Exit(); // ?


  if (FBrowserInfoMap.TryGetValue(browser_id, info_map)) then
    begin

    info_map_index := 0;
    // Expensive...
    info_map_array := info_map.ToArray;

    while (info_map_index < Length(info_map_array)) do
      begin
      info := info_map_array[info_map_index].Value;
      info_id := info_map_array[info_map_index].Key;

      remove := False;
      keepGoing := visitor.OnNextInfo(browser_id, info_id, info, remove);

      if remove then
        info_map.Remove(info_id);

      Inc(info_map_index);

      if not keepGoing then
        Break;
      end;

    if info_map.Empty then
      begin
      FBrowserInfoMap.Remove(browser_id);
      FreeAndNil(info_map);
      end;

    end;

end;

function TCefBrowserInfoMap<IdType, ObjectType>.GetEqualityComparer: IEqualityComparer<IdType>;
begin
  Result := TEqualityComparer<IdType>.Default;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.Size(browser_id: Integer): Integer;
var
  info_map: TInfoMap;
begin
  Result := 0;
  if (FBrowserInfoMap.Empty()) then
    Exit;
  if FBrowserInfoMap.TryGetValue(browser_id, info_map) then
    Result := info_map.Size;

end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.Size: Integer;
var
  item: TPair<Integer, TInfoMap>;
begin
  Result := 0;
  if (FBrowserInfoMap.Empty()) then
    Exit;

  for item in FBrowserInfoMap do
    Inc(Result, item.Value.Size);
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TCefBrowserInfoMap<IdType, ObjectType>.FindAll(visitor: TVisitor);
var
  info_map: TInfoMap;
  info: ObjectType;
  remove: Boolean;
  keepGoing: Boolean;


  browser_info_map_array: TArray<TPair<Integer, TInfoMap>>;
  browser_info_index: Integer;
  browser_id: Integer;

  info_map_index: Integer;
  info_map_array: TArray<TPair<IdType, ObjectType>>;
  info_id: IdType;
begin
  Assert(Assigned(visitor));

  if (FBrowserInfoMap.Empty()) then
    Exit(); // ?

  browser_info_index := 0;
  // Expensive...
  browser_info_map_array := FBrowserInfoMap.ToArray;

  while (browser_info_index < Length(browser_info_map_array)) do
    begin
    info_map := browser_info_map_array[browser_info_index].Value;
    browser_id := browser_info_map_array[browser_info_index].Key;

    info_map_index := 0;
    // Expensive...
    info_map_array := info_map.ToArray;

    while (info_map_index < Length(info_map_array)) do
      begin
      info := info_map_array[info_map_index].Value;
      info_id := info_map_array[info_map_index].Key;

      remove := False;
      keepGoing := visitor.OnNextInfo(browser_id, info_id, info, remove);

      if remove then
        info_map.Remove(info_id);

      Inc(info_map_index);

      if not keepGoing then
        Break;
      end;

    if info_map.Empty then
      begin
      FBrowserInfoMap.Remove(browser_id);
      FreeAndNil(info_map);
      end;

    Inc(browser_info_index);
    if not keepGoing then
      Break;
    end;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TCefBrowserInfoMap<IdType, ObjectType>.Clear;
var
  browser: TPair<Integer,TInfoMap>;
  info: TPair<IdType, ObjectType>;
begin
  if FBrowserInfoMap.Empty then
    Exit;

  for browser in FBrowserInfoMap do
    begin
    for info in browser.Value do
      Destruct(info.Value);
    browser.Value.Free;
    end;
  FBrowserInfoMap.Clear;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
procedure TCefBrowserInfoMap<IdType, ObjectType>.Clear(browser_id: Integer);
var
  info_map: TInfoMap;
  info: TPair<IdType, ObjectType>;
begin
  if FBrowserInfoMap.Empty then
    Exit;
  if FBrowserInfoMap.TryGetValue(browser_id, info_map) then
    begin
    for info in info_map do
      Destruct(info.Value);

    FBrowserInfoMap.Remove(browser_id);
    FreeAndNil(info_map);
    end;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
constructor TCefBrowserInfoMap<IdType, ObjectType>.Create;
begin
  FBrowserInfoMap := TBrowserInfoMap.Create;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
//function TCefBrowserInfoMap<IdType, ObjectType>.CreateMap: TInfoMap;
//begin
//  Result := TInfoMap.Create(Self.GetEqualityComparer);
//end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
destructor TCefBrowserInfoMap<IdType, ObjectType>.Destroy;
begin
  Clear;
  FreeAndNiL(FBrowserInfoMap);

  inherited;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.Empty: Boolean;
begin
  Result := FBrowserInfoMap.Empty();
end;

{ TCefBrowserInfoMap<IdType, ObjectType>.TBrowserInfoMap }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.TBrowserInfoMap.Empty: Boolean;
begin
  Result := Count = 0;
end;

{ TCefBrowserInfoMap<IdType, ObjectType>.TInfoMap }

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.TInfoMap.Empty: Boolean;
begin
  Result := Count = 0;
end;

{-------------------------------------------------------------------------------
-------------------------------------------------------------------------------}
function TCefBrowserInfoMap<IdType, ObjectType>.TInfoMap.Size: Integer;
begin
  Result := Count;
end;



{ TIdGenerator<T> }

constructor Tint64IdGenerator.Create;
begin
  FNextId := kReservedId;
end;

function TInt64IdGenerator.GetNextId: Int64;
begin
  Inc(FNextID);
  if FNextId = kReservedId then
    Inc(FNextID);
  Result := FNextId;
end;

end.
