SET TRUENULLCREATE=OFF#
ALTER TABLE "Transactions" IN DICTIONARY (
  DROP "Reserved",
  DROP "Source_code_id",
  DROP "Weight_on_Scale",
  DROP "Calc_Post_Mix_Wt",
  DROP "User_ID",
  DROP "Reserved7"
)#
ALTER TABLE "Transactions" IN DICTIONARY (
  ADD "TempChecked"      UTINYINT,
  ADD "User_ID"          CHAR(8),
  ADD "Calc_Post_Mix_Wt" DOUBLE,
  ADD "Weight_on_Scale"  DOUBLE,
  ADD "Source_code_id"   INTEGER,
  ADD "Temperature"      DOUBLE
)#
SET TRUENULLCREATE=ON#
UPDATE "Transactions" SET "TempChecked" = 0, "Temperature" = 0.0#
