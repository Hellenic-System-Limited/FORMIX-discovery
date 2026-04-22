SET TRUENULLCREATE=OFF#
ALTER TABLE "Mix_Total" IN DICTIONARY (
  DROP "Reserved",
  DROP "QA_Complete")#
ALTER TABLE "Mix_Total" IN DICTIONARY (
  ADD "QA_Complete"       BIT,
  ADD "Meat_QA_done"      BIT,
  ADD "Seasoning_QA_done" BIT,
  ADD "Water_QA_done"     BIT,
  ADD "Reserved" CHAR(7)
)#
SET TRUENULLCREATE=ON#
