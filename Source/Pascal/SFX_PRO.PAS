(****************************************************************************
*  UNIT          : SFX_PRO                                                  *
*  AUTHOR        : N.S.                                                     *
*  DATE          : 4/6/96                                                   *
*  PURPOSE       : PERFORMS BACKGROUND TASKING DURING WAIT FOR USER INPUT   *
*  MODIFICATIONS : -                                                        *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
{$C FIXED PRELOAD PERMANENT}
UNIT SFX_Pro;
INTERFACE

{Task numbers}
(*
CONST
     NoProcess         : WORD = $0000;
     GetTareWt         : WORD = $0001;
     CancelTareWt      : WORD = $0002;
     FlashingCursor    : WORD = $0004;
     FlashSemiAutoTare : WORD = $0008;
     TimedOrderRefresh : WORD = $0010;
     ZeroScale         : WORD = $0020;
     WaitForZeroWt     : WORD = $0040;
     WaitForNonZeroWt  : WORD = $0080;
*)

TYPE
    PBackGroundTask = ^TBackGroundTask;
    TBackGroundTask = OBJECT
     PRIVATE
       NextTask    : PBackGroundTask;
       ActiveTask  : BOOLEAN;
       SuspendWhenModalWinUp : BOOLEAN;
     PUBLIC
       CONSTRUCTOR Init(DisableWhenModalWinUp : BOOLEAN);
       DESTRUCTOR  Done; VIRTUAL;
       PROCEDURE   DisableTask; VIRTUAL;
       PROCEDURE   EnableTask; VIRTUAL;
       PROCEDURE   Execute; VIRTUAL;
       FUNCTION    Active : BOOLEAN;
       PROCEDURE   SetActive(bActive : BOOLEAN);
    END;

TYPE PProcessObject = ^TProcessObject;
     TProcessObject = OBJECT
      TaskList        : PBackGroundTask;
      CurrentTask     : PBackGroundTask;
      NumberOfTasks   : LONGINT;
      ModalWinIsUp    : BOOLEAN;

      CONSTRUCTOR Init;
      DESTRUCTOR  Done; VIRTUAL;
      PROCEDURE   AddBackGroundTask(TaskPtr : PBackGroundTask);
      PROCEDURE   RemoveBackGroundTask(TaskPtr : PBackGroundTask);
      PROCEDURE   RunTaskCycle;
(*
      PROCEDURE   SaveProcess;
      PROCEDURE   RestoreProcess;
*)
     END;


(*
TYPE
    PProcessObject = ^TProcessObject;
    TProcessObject = OBJECT

     ProcessOn  : WORD;                {Process Currently Being Activated}
     SavedPro   : WORD;

     X,Y        : INTEGER;             {X,Y Co-ordinate For Flashing cursor}
     FlashingCh : Char;                {Char that is flashing}
     InverseFont: PFontType;           {Inversed Font While Flashing}

     RefreshTime,RefreshCount : LONGINT;
     NextMsgCheck  : LONGINT;
     MsgTimeCount  : LONGINT;
     MsgReadingOn  : BOOLEAN;

     CONSTRUCTOR Init;
     DESTRUCTOR  Done;
     PROCEDURE RunTaskCycle;
     PROCEDURE SaveProcess;
     PROCEDURE RestoreProcess;
     PROCEDURE ClearProcess;

     PROCEDURE SetCharacterFlashing(Xpos,Ypos : INTEGER;Ch : CHAR;InvFont : PFontType);
     PROCEDURE StopFlashing;

     PROCEDURE ResetObjectForScaleTare;

     PROCEDURE InitTimedOrderRefresh;
     PROCEDURE CancelTimedOrderRefresh;

     PROCEDURE SetSemiAutoTareFlashing;
     PROCEDURE StopSemiAutoTareFlashing;

     PROCEDURE ClearTareProcess;
     PROCEDURE SetCancelTare;
     PROCEDURE StartMsgReading;
     PROCEDURE WaitForScaleToZero;
     PROCEDURE WaitForScaleTare;
PRIVATE
     PROCEDURE SetProcess(ProcessNum : WORD);
     PROCEDURE EndProcess(ProcessNum : WORD);
    END;
*)
PROCEDURE ProcessStart;
PROCEDURE ProcessStop;

VAR ProcessObject : PProcessObject;



IMPLEMENTATION

CONSTRUCTOR TBackGroundTask.Init(DisableWhenModalWinUp : BOOLEAN);
BEGIN
 NextTask   := NIL;
 SuspendWhenModalWinUp := DisableWhenModalWinUp;
 ActiveTask := TRUE;
 ProcessObject^.AddBackGroundTask(@Self);
END;

DESTRUCTOR TBackGroundTask.Done;
BEGIN
END;

PROCEDURE TBackGroundTask.DisableTask;
BEGIN
 ActiveTask := FALSE;
END;

PROCEDURE TBackGroundTask.EnableTask;
BEGIN
 ActiveTask := TRUE;
END;

FUNCTION  TBackGroundTask.Active : BOOLEAN;
BEGIN
 Active := ActiveTask;
END;

PROCEDURE TBackGroundTask.SetActive(bActive : BOOLEAN);
BEGIN
 ActiveTask := bActive;
END;

PROCEDURE TBackGroundTask.Execute;
BEGIN
 {Abstract Really}
END;

{ ************************************************************************* }
{ TProcessObject Methods                                                    }
{ ************************************************************************* }

CONSTRUCTOR TProcessObject.Init;
BEGIN
 TaskList         := NIL;
 CurrentTask      := NIL;
 NumberOfTasks    := 0;
 ModalWinIsUp     := FALSE;
END;

DESTRUCTOR TProcessObject.Done;
VAR DeleteTaskPtr : PBackGroundTask;
BEGIN
 WHILE (TaskList <> NIL) DO
  BEGIN
   DeleteTaskPtr := TaskList;
   TaskList := TaskList^.NextTask;
   Dispose(DeleteTaskPtr,Done);
   DEC(NumberOfTasks);
  END;
END;

PROCEDURE TProcessObject.AddBackGroundTask(TaskPtr : PBackGroundTask);
VAR LoopPtr : PBAckGroundTask;
BEGIN
 IF (TaskList = NIL) THEN
  BEGIN
   TaskPtr^.NextTask := TaskList;
   TaskList := TaskPtr;
  END
 ELSE
  BEGIN
   LoopPtr := TaskList;
   WHILE (LoopPtr^.NextTask <> NIL) DO LoopPtr := LoopPtr^.NextTask;
   TaskPtr^.NextTask := NIL;
   LoopPtr^.NextTask := TaskPtr;
  END;
 INC(NumberOfTasks);                             { Increment Task Counter   }
END;

PROCEDURE TProcessObject.RemoveBackGroundTask(TaskPtr : PBackGroundTask);
VAR DeleteTaskPtr : PBackGroundTask;
    LastPtr       : PBackGroundTask;
BEGIN
 IF (CurrentTask = TaskPtr) THEN CurrentTask := CurrentTask^.NextTask;
 DeleteTaskPtr := TaskList;
 LastPtr       := NIL;
 WHILE (DeleteTaskPtr <> NIL) DO
  BEGIN
   IF (DeleteTaskPtr = TaskPtr) THEN
    BEGIN
     IF (TaskPtr = TaskList) THEN TaskList := TaskList^.NextTask
     ELSE
      BEGIN                                      { Task Located             }
       LastPtr^.NextTask := DeleteTaskPtr^.NextTask;
      END;
     Dispose(TaskPtr,Done);                      { Dispose Task Object      }
     DEC(NumberOfTasks);                         { Decrement Task Counter   }
     BREAK;                                      { Exit Loop                }
    END;
   LastPtr := DeleteTaskPtr;
   DeleteTaskPtr := DeleteTaskPtr^.NextTask;     { Retrieve Ptr To Next Task}
  END;
END;

PROCEDURE TProcessObject.RunTaskCycle;
BEGIN
 CurrentTask := TaskList;
 WHILE (CurrentTask <> NIL) DO
  BEGIN
   IF  (CurrentTask^.Active)
   AND ((NOT ModalWinIsUp) OR (NOT CurrentTask^.SuspendWhenModalWinUp)) THEN
    BEGIN
     CurrentTask^.Execute;
    END;
   IF (CurrentTask <> NIL) THEN CurrentTask := CurrentTask^.NextTask;
  END;
END;

PROCEDURE ProcessStart;
BEGIN
 New(ProcessObject,Init);
(*
{$IFDEF DISPMEM}
 New(MemDisp,Init);
{$ENDIF}
*)
END;

PROCEDURE ProcessStop;
BEGIN
 IF ProcessObject  = NIL THEN EXIT;
 Dispose(ProcessObject,Done);
 ProcessObject := NIL;
END;


BEGIN
 ProcessObject := NIL;
END.