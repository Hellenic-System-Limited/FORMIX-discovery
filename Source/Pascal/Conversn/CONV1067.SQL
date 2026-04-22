SET TRUENULLCREATE=OFF#
ALTER TABLE Trans_Warnings IN DICTIONARY (
  DROP Reserved
)#
ALTER TABLE Trans_Warnings IN DICTIONARY (
  ADD  SrcConcessionNo  INTEGER,
  ADD  Reserved         BINARY(16)
)#
CREATE INDEX BySrcconcess IN DICTIONARY ON
 Trans_Warnings(SrcConcessionNo)#
SET TRUENULLCREATE=ON#
