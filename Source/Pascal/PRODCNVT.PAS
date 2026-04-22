USES FXFProd,FXModCtv;


CONST oldProd : TProductRef  = '2BREATRST ';
      newprod : TProductRef  = '2BREASTRST';


VAR ProdHRec : TProdHeaderRecord;
    ProdLRec : TProdLineRecord;
    ProdDRec : TProdDescription;
    filepos  : longint;

BEGIN
 New(ProdHeaderFile,Init(Product_Header_FileName));
 IF NOT Assigned(ProdHeaderFile) THEN EXIT;
 New(ProdLineFile,Init(Product_Line_FileName));
 IF NOT Assigned(ProdLineFile) THEN EXIT;
 New(ProdDescFile,Init(Product_Desc_FileName));
 IF NOT Assigned(ProdDescFile) THEN EXIT;

 ProdHeaderFile^.Openfile;
 ProdLineFile^.Openfile;
 ProdDescFile^.Openfile;
 {convert header}
 writeln('converting header');
 FillChar(ProdHRec,SizeOF(ProdHRec),#0);
 ProdHRec.PH_ProductCode := oldprod;
 prodheaderfile^.readrecord('EQ',false,false,prodhrec,0);
 prodhrec.ph_productcode := newprod;
 prodheaderfile^.addrecord(prodhrec);

 writeln('converting lines');
 {convert lines}
 fillchar(prodlrec,sizeof(prodlrec),#0);
 prodlrec.pl_productcode := oldprod;
 prodlinefile^.readrecord('GE',false,false,prodlrec,0);
 while (prodlinefile^.btrverr = 0) and (prodlrec.pl_productcode = oldprod) do
  begin
   writeln('converting record - ',prodlrec.pl_recipeno);
   prodlrec.pl_productcode := newprod;
   prodlinefile^.addrecord(prodlrec);
   prodlinefile^.readrecord('GN',false,false,prodlrec,0);
  end;

 {convert descriptions}
 writeln('converting descriptions');
 fillchar(proddrec,sizeOf(proddrec),#0);
 proddrec.pd_productcode := oldprod;
 proddescfile^.readrecord('GE',false,false,proddrec,0);
 while (proddescfile^.btrverr = 0) and (proddrec.pd_productcode = oldprod) do
  begin
   writeln('converting description - ',proddrec.pd_description);
   proddrec.pd_productcode := newprod;
   filepos := proddescfile^.position;
   proddescfile^.addrecord(proddrec);
   proddescfile^.getrecorddirect(filepos,false,false,proddrec,0);
   proddescfile^.readrecord('GN',false,false,proddrec,0);
  end;

 prodheaderfile^.closefile;
 prodlinefile^.closefile;
 proddescfile^.closefile;

 dispose(prodheaderfile,done);
 dispose(prodlinefile,done);
 dispose(proddescfile,done);
end.