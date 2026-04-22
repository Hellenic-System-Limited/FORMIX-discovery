SELECT X$File.XF$Name, Xe$Offset, Xe$Name, Xe$DataType, "Xe$Size"
FROM "X$Field", "X$File" WHERE (X$File.XF$Id = Xe$File) AND (Xe$Datatype <> 255)
ORDER BY 1, 2, Xe$Dec#
SELECT "X$File"."Xf$Name", "X$Index"."Xi$Number", "X$Index"."Xi$Part", "X$Index"."Xi$Flags", 
"KEYNAMES"."Xe$Name" "Key Name", "X$Field1"."Xe$Name"
FROM (("X$Index" JOIN X$File ON "X$Index"."Xi$File" = "X$File"."Xf$Id")
LEFT OUTER JOIN X$Field AS X$Field1 ON "X$Index".Xi$Field = X$Field1.Xe$Id)
LEFT OUTER JOIN X$Field AS KEYNAMES ON ("X$Index"."Xi$File" = "KEYNAMES"."Xe$File")
                                   AND ("X$Index"."Xi$Number" = "KEYNAMES"."Xe$Offset")
                                   AND (KEYNAMES.Xe$Datatype = 255)                                
ORDER BY 1, 2, 3#
