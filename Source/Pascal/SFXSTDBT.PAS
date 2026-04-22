(****************************************************************************
*  UNIT          : SFXStdBt                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 02/05/96                                                 *
*  PURPOSE       : Standard Buttons Used On The Scale                       *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXStdBt;
INTERFACE
USES SFXGraph,SFXTime,SFXScale,SFXDate,SFXFont,SFXMsg;

PROCEDURE StdWinInit;
PROCEDURE StdWinDone;

CONST StdWinCreated : BOOLEAN = FALSE;

{INSTANCES OF THE OBJECTS}

IMPLEMENTATION

{TimeWindow Methods}
PROCEDURE StdWinInit;
BEGIN
{ DateWindow.Init(28,10);}
{ DateWindow.HideWindow;}
{ DateWindow^.ChangeWindowFont(DoubleHeightFont);}
(*
 TimeWindow.Init(40,1);
 TimeWindow.HideWindow;
 TimeWindow.ChangeWindowFont(DoubleHeightFont);
*)
 MessageWin.Init;
 StdWinCreated := TRUE;
END;

PROCEDURE StdWinDone;
BEGIN
 IF NOT StdWinCreated THEN EXIT;
{ DateWindow.Done;}
(* TimeWindow.Done;*)
 MessageWin.Done;
END;



END.