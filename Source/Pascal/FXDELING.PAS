(****************************************************************************
*  UNIT          : FXDelIng                                                 *
*  AUTHOR        : N. S.                                                    *
*  DATE          : 17/05/96                                                 *
*  PURPOSE       : Ingredient Usage Cleardown Routines                      *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT FXDELING;
INTERFACE
USES CRT,F6StdCtv,F6StdUtl,F6stdUt1,F6StdWin,F6DTConv,FXModCtv,FXCfg,FXFNet;


PROCEDURE ClearDown_Ingredient_Usage;



IMPLEMENTATION


PROCEDURE ClearDown_Ingredient_Usage;
VAR
    NB,LF,HF,RB,RF : BYTE;
    NetRec         : TNetRecord;
    AtX            : INTEGER;
    NumDeleted     : INTEGER;
    DelWin         : WindowRecord;
    ToDate         : LONGINT;
BEGIN
 Save_Colours(NB,LF,HF,RB,RF);
 Set_Colours(Red,White,Yellow,LightGray,Red);
 SetWindow(20,07,60,18,TRUE,Red*16+White,Red*16+White,DelWin);
 Header('Clear Ingredient Usage File',1);
 WriteAt(2,3,'  This Option Clears All Ingredient');
 WriteAt(2,4,' weighing information before the');
 WriteAt(2,5,' Specific Date');
 WriteAt(2,7,' Delete To Date [  /  /    ]');
 Footer('ESC - EXIT   F2 - Cleardown',1);
 ToDate := Date_to_Days(Date);
 REPEAT
  GetDate(ToDate,18,7);
 UNTIL (ch1 = ESC) OR (ch1 = FN_F2);
 LoseWindow(DelWin);
 Set_Colours(NB,LF,HF,RB,RF);
 IF Ch1 = ESC THEN EXIT;
 CursorOff;
 SetWindow(22,7,60,14,TRUE,NormBack*16+LowFore,NormBack*16+LowFore,DelWin);
 Header('Deleting Ingredient Usage Details',1);
 WriteAt(2,3,'Records Deleted : ');
 AtX := WhereX;
 IF NetFile^.OpenFile = 0 THEN
  BEGIN
   NumDeleted := 0;
   Writeat(AtX,3,IntToStr(NumDeleted,1));
   FillChar(NetRec,SizeOf(TNetRecord),#0);
   NetFile^.ReadRecord('GF',TRUE,FALSE,NetRec,0);
   WHILE (NetFile^.BtrvErr = 0) AND (NetRec.NETW_Date <= ToDate) DO
    BEGIN
     INC(NumDeleted);
     Writeat(AtX,3,IntToStr(NumDeleted,1));
     NetFile^.DeleteRecord;
     NetFile^.ReadRecord('GN',TRUE,FALSE,NetRec,0);
    END;
   NetFile^.CloseFile;
  END;
 Set_Colours(Red,White,Yellow,White,Red);
 Footer('Complete',1);
 GetKey;
 LoseWindow(DelWin);
 Set_Colours(NB,LF,HF,RB,RF);
END;



END.