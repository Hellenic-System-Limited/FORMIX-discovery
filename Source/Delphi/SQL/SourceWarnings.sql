select "Source_Codes"."Code", "Source_Codes"."ID",
       "Transactions"."MC_ID", "Transactions"."Serial_No",
       "Trans_Warnings"."Warning"
from "SOURCE_CODES", "Transactions", "Trans_Warnings"
where "Source_Codes"."Code" like '02000146%'
  and "Transactions"."Source_Code_ID" = "Source_codes"."ID"
  and "Trans_Warnings"."MC_ID" = "Transactions"."MC_ID"
  and "Trans_Warnings"."Serial_No" = "Transactions"."Serial_No";