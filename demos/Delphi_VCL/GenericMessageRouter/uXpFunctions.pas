unit uXpFunctions;
// NOT MY SOURCE
// Origionally acquired from
// https://github.com/zhangdongfarmer/task_tool/blob/master/trunk/module/browser_app/comm/uXpFunctions.pas
// however since we downloaded it the project has since been removed.
//
// I did find a clone of it there.. https://github.com/mohdfaiad/task_tool/blob/master/trunk/module/browser_app/comm/uXpFunctions.pas
// which has a GPL 3.0 license..
// https://github.com/mohdfaiad/task_tool/blob/master/LICENSE
interface

uses
  uCEFInterfaces, uCEFv8Value;

type
  TXpFunction = class
  public
    class function TCefv8ValueRef_NewObject(const Accessor: ICefV8Accessor; const AObj: TObject): ICefv8Value;
  end;

implementation


{ TXpFunction }

class function TXpFunction.TCefv8ValueRef_NewObject(
  const Accessor: ICefV8Accessor; const AObj: TObject): ICefv8Value;
begin
  {$IFDEF XP_2623}
  Result := TCefv8ValueRef.NewObject(Accessor);
  {$ELSE}
  Result := TCefv8ValueRef.NewObject(Accessor, nil);
  {$ENDIF}
end;

end.
