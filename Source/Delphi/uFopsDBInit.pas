unit uFopsDBInit;

interface

uses
  udmDatabaseModule, uFopsDBDetails;

var
  MainDatabaseModule : TdmDatabaseModule;
  FopsDatabaseModule : TdmDatabaseModule;
  DBDetails: TFopsDBDetails = nil;
  FopsDBDetails: TFopsDBDetails = nil;

implementation

uses
  Forms;

initialization

  DBDetails := TFopsDBDetails.Create;
  //set the details how you want
  DBDetails.Init;
  //create Database module
  MainDatabaseModule := TdmDatabaseModule.Create(Application,DBDetails);
  //don't connect database module
  // Now create the fops dm
  FopsDBDetails := TFopsDBDetails.Create;
  FopsDBDetails.InitForFops;
  FopsDatabaseModule := TdmDatabaseModule.Create(Application,FopsDBDetails);


finalization
  DBDetails.Free;
  FopsDBDetails.Free;
  //owned and so freed by the application
  //CarcaseDatabaseModule.Free;

end.
