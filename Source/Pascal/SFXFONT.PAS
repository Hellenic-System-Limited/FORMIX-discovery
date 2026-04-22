(****************************************************************************
*  UNIT          : SFXFont                                                  *
*  AUTHOR        : N  S.                                                    *
*  DATE          : 02/05/95                                                 *
*  PURPOSE       : Scale Formix Default Fonts                               *
*  MODIFICATIONS :-                                                         *
*****************************************************************************)
{$O+,F+}
{$I F6COMP}
UNIT SFXFont;
INTERFACE
USES SFXGraph;

PROCEDURE FontInit;
PROCEDURE FontDone;

VAR
    RecipeNormalFont : PFontType;
    RecipeGreyedFont : PFontType;
    RecipeInverseFont: PFontType;
    DoubleHeightFont : PFontType;
    DoubleSizeFont   : PFontType;
    InversedDHFont   : PFontType;    {NOT Currently Used}
    KeyBoardNormal   : PFontType;
    ScaleFont        : PFontType;

IMPLEMENTATION

PROCEDURE FontInit;
BEGIN
{ RecipeNormalFont := CreateFont(1,1,HORIZ,FONT_8x16,FontNormal);}
 RecipeNormalFont := Font8x16;
 RecipeGreyedFont := CreateFont(1,1,HORIZ,FONT_8x16,FontNormal OR FontGreyed);
 RecipeInverseFont:= CreateFont(1,1,HORIZ,FONT_8x16,FontInversed);
 DoubleHeightFont := CreateFont(2,1,HORIZ,FONT_8x16,FontNormal);
 DoubleSizeFont   := CreateFont(2,2,HORIZ,FONT_8x16,FontNormal);
 KeyBoardNormal   := CreateFont(2,4,HORIZ,FONT_8X16,FontNormal);
 ScaleFont        := CreateFont(3,3,HORIZ,FONT_8X16,FontNormal);
END;

PROCEDURE FontDone;
BEGIN
{ IF (RecipeNormalFont <> NIL) THEN DeleteFont(RecipeNormalFont);}
 IF (RecipeGreyedFont  <> NIL) THEN DeleteFont(RecipeGreyedFont);
 IF (RecipeInverseFont <> NIL) THEN DeleteFont(RecipeInverseFont);
 IF (DoubleHeightFont  <> NIL) THEN DeleteFont(DoubleheightFont);
 IF (DoubleSizeFont    <> NIL) THEN DeleteFont(DoubleSizeFont);
 IF (KeyBoardNormal    <> NIL) THEN DeleteFont(KeyBoardNormal);
 IF (ScaleFont         <> NIL) THEN DeleteFont(ScaleFont);

 RecipeGreyedFont  := NIL;
 RecipeInverseFont := NIL;
 DoubleHeightFont  := NIL;
 KeyBoardNormal    := NIL;
 ScaleFont         := NIL;
END;

END.