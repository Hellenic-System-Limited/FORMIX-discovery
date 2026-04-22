{$O+,F+}
{$I F6COMP}
UNIT FXChoice;
INTERFACE
USES SFXBtn,SFXGraph;


TYPE
    PChoiceBtn = ^TChoiceBtn;
    TChoiceBtn = OBJECT(TChildAreaObject)

      {Position, Return Value,String}
      CONSTRUCTOR Init(X1,Y1:INTEGER;Parent : PSFWindow;RetVal : INTEGER;DispStr : STRING;LargeButtons : BOOLEAN);
      DESTRUCTOR  Done;VIRTUAL;
      FUNCTION    UserActivateFunction(X,Y : INTEGER) : BOOLEAN; VIRTUAL;
      PROCEDURE   Draw;Virtual;
      FUNCTION    GetTypeName : STRING;VIRTUAL;

      FUNCTION    GetReturnValue : INTEGER;
      PROCEDURE   SetText(NewText : STRING);

     private
      ReturnValue : INTEGER;
      DispTxt : STRING[30];
    END;

IMPLEMENTATION
USES SFXCOLR;

{==========================================================================}
{===================== CHOICE BUTTON METHODS =============================}
CONSTRUCTOR TChoiceBtn.Init(X1,Y1:INTEGER;Parent : PSFWindow;RetVal : INTEGER;DispStr : STRING;LargeButtons : BOOLEAN);
BEGIN
 ReturnValue := RetVal;
 DispTxt     := DispStr;
 INHERITED INIT(X1,Y1,Parent,LargeButtons);
END;

DESTRUCTOR TChoiceBtn.Done;
BEGIN
 INHERITED Done;
END;

FUNCTION TChoiceBtn.GetReturnValue : INTEGER;
BEGIN
 GetReturnValue := ReturnValue;
END;

PROCEDURE TChoiceBtn.SetText(NewText : STRING);
BEGIN
 DispTxt := NewText;
END;


FUNCTION TChoiceBtn.GetTypeName : STRING;
BEGIN
 GetTypeName := 'TCHOICEBTN';
END;

FUNCTION TChoiceBtn.UserActivateFunction(X,Y : INTEGER) : BOOLEAN;
BEGIN
 UserActivateFunction := FALSE;
 SendMsg(hParent,ReturnValue);
END;

PROCEDURE TChoiceBtn.Draw;
VAR SaveCol : BYTE;
BEGIN
 SaveCol := SetTextColour(C_TextButton);
 DisplayText(1,DispTxt);
 SetTextColour(SaveCol);
 INHERITED Draw;
END;

END.