SET TRUENULLCREATE=OFF#
ALTER TABLE "Recipe_Header" IN DICTIONARY (DROP "Reserved")#
ALTER TABLE "Recipe_Header" IN DICTIONARY (
  ADD "Reserved3"      UTINYINT    NOT NULL,
  ADD "Work_Group"     CHAR(3)     NOT NULL,
  ADD "Job_Number"     SMALLINT    NOT NULL,
  ADD "Reserved "      CHAR(14)    NOT NULL
)#
SET TRUENULLCREATE=ON#
