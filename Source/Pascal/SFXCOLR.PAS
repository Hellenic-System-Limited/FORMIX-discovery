(****************************************************************************
*  UNIT          : SFXCOLR                                              *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Colour Properties                                 *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXCOLR;

INTERFACE

USES FXFINI;



VAR   C_BackGround       : BYTE;
      C_WindowHeader     : BYTE;
      C_WindowStaticText : BYTE;
      C_WindowText       : BYTE;
      C_PickListNormal   : BYTE;
      C_TextButton       : BYTE;
      C_MessageWin       : BYTE;

      C_FillBarInTol     : BYTE;
      C_FillBarOutTol    : BYTE;
      C_MixBar           : BYTE;
      L_FillBarLineStyle : BYTE;
      L_MixBarLineStyle  : BYTE;

{
      C_PickListDisabled : BYTE;
}

PROCEDURE SetColourScheme;

IMPLEMENTATION
USES SFXCONST,SFXGraph;

PROCEDURE SetColourScheme;
BEGIN
  IF ScaleConfRec.ColourDisplay THEN
   BEGIN
    C_BackGround := 8;
    C_WindowHeader     := GetExtNum(CWindowHeader     ,all,0,$FF,$CF);
    C_WindowStaticText := GetExtNum(CWindowStaticText ,all,0,$FF,$F0);
    C_WindowText       := GetExtNum(CWindowText       ,all,0,$FF,$FC);
    C_PickListNormal   := GetExtNum(CPickList         ,all,0,$FF,$70);

    C_TextButton       := GetExtNum(CButtonText       ,all,0,$FF,$F0);
    C_MessageWin       := GetExtNum(CMessageWin       ,all,0,$FF,$0F  );

    C_FillBarOutTol    := GetExtNum(CFillBarOutTol    ,all,0,$0F,$09);
    C_FillBarInTol     := GetExtNum(CFillBarInTol     ,all,0,$0F,$0A);
    C_MixBar           := GetExtNum(CMixBar           ,all,0,$0F,$04);
    L_FillBarLineStyle := 0;
    L_MixBarLineStyle  := 0;

{
    C_PickListDisabled := GetExtNum(CPickListDisabled ,all,0,$FF,$F7);
}

   END
  ELSE
   BEGIN
    C_BackGround :=15;
    C_WindowHeader     := GetExtNum(CWindowHeader     ,all,0,$FF,$0F);
    C_WindowStaticText := GetExtNum(CWindowStaticText ,all,0,$FF,$F0);
    C_WindowText       := GetExtNum(CWindowText       ,all,0,$FF,$F0);
    C_PickListNormal   := GetExtNum(CPickList         ,all,0,$FF,$F0);


    C_TextButton       := GetExtNum(CButtonText       ,all,0,$FF,$F0);
    C_MessageWin       := GetExtNum(CMessageWin       ,all,0,$FF,$0F);

    C_FillBarOutTol    := GetExtNum(CFillBarOutTol    ,all,0,$0F,$00);
    C_FillBarInTol     := GetExtNum(CFillBarInTol     ,all,0,$0F,$00);
    C_MixBar           := GetExtNum(CMixBar           ,all,0,$0F,$00);

    C_TextButton       := $F0;
    C_MessageWin       := $0F;

    C_FillBarOutTol    := $0;
    C_FillBarInTol     := $0;
    C_MixBar           := $0;
    L_FillBarLineStyle := 5;
    L_MixBarLineStyle  := 4;

{
    C_PickListDisabled := GetExtNum(CPickListDisabled ,all,0,$FF,$F7);
}

   END;
  SetBackColour(C_BackGround);
  SetTextColour(C_BackGround SHL 4);
END;

END.
