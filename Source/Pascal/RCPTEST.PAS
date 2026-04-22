Program TestRecipeFile;
USES CRT,FXFGen,FxFRcp;


VAR RecipeLine : TRecipeLineRecord;
    ErrInt : INTEGER;
    LineNo : INTEGER;
    LastHeader,LastLineNo : LONGINT;

BEGIN
 init_system;
 LineNo := 0;
 FillChar(RecipeLine,SizeOf(REcipeLine),#0);
 TextAttr := 7;
 ClrScr;
 LastHeader := 0;
 LastLineNo := 0;
 IF RecipeLineFile^.OpenFile = 0 THEN
  BEGIN
   ErrInt := RecipeLineFile^.ReadRecord('GF',FALSE,FALSE,RecipeLine,0);
   WHILE (ErrInt =0) DO
    BEGIN
     WITH RecipeLine DO
      BEGIN
       WRITE(
        RL_UniqueRef:6,' ',
        RL_RecipeNo,' ',
        RL_LineNo:3,' ',
        RL_HUniqueRef:4,' ',
        RL_Ingredient,' ',
        RL_KeyProduct,' ',
        RL_Ratio:9:3,' ',
        RL_ContainerSize:9:3,' ',
        RL_Yield:9:3,' ');
       IF (LastHeader = RL_HUniqueRef) AND (RL_LineNo = LastLineNo) THEN
        Write('  Match');
       WriteLn;
       LastHeader := RL_HUniqueRef;
       LastLineNo := RL_LineNo;
       INC(LineNo);
       IF LineNo = 23 THEN
        BEGIN
         WriteLn('Press Any Key To Continue');
         IF ReadKey = #0 THEN ReadKey;
         ClrScr;
         LineNo := 0;
        END;
      END;
     ErrInt := RecipeLineFile^.ReadRecord('GN',FALSE,FALSE,RecipeLine,0);
    END;
   RecipeLineFile^.CloseFile;
  END;
END.

