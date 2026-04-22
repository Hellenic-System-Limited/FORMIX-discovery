inherited dmFormixBase: TdmFormixBase
  OnDestroy = nil
  Left = 359
  Top = 189
  Height = 378
  Width = 827
  object pvtblOrderHeader: TPvTable
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    AfterOpen = pvtblOrderHeaderAfterOpen
    IndexFieldNames = 'Schedule_Date;Order_No;Order_No_Suffix'
    TableName = 'Order_Header'
    Left = 32
    Top = 63
  end
  object pvtblOrderLine: TPvTable
    DatabaseName = 'FORMIX'
    SessionName = 'PvDefault'
    TableName = 'Order_Line'
    Left = 32
    Top = 107
  end
  object pvtblRecipeHeader: TPvTable
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    AfterOpen = pvtblRecipeHeaderAfterOpen
    IndexName = 'ByCode'
    TableName = 'Recipe_Header'
    Left = 136
    Top = 68
  end
  object pvtblRecipeLines: TPvTable
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    IndexName = 'ByHeadRefLine'
    TableName = 'Recipe_Line'
    Left = 136
    Top = 116
  end
  object pvtblIngredients: TPvTable
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    IndexName = 'ByIngredient'
    TableName = 'Ingredients'
    Left = 136
    Top = 164
  end
  object pvtblMixTotal: TPvTable
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    AfterOpen = pvtblMixTotalAfterOpen
    IndexName = 'ByOrderMix'
    TableName = 'Mix_Total'
    Left = 32
    Top = 151
  end
  object pvtblTransactions: TPvTable
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    AfterOpen = pvtblTransactionsAfterOpen
    TableName = 'Transactions'
    Left = 32
    Top = 191
  end
  object pvtblIngredientUsage: TPvTable
    DatabaseName = 'FORMIX'
    SessionName = 'PvDefault'
    IndexName = 'ByDateBatLotIngred'
    TableName = 'Ingred_Usage'
    Left = 238
    Top = 116
  end
  object pvtblCost: TPvTable
    DatabaseName = 'FORMIX'
    SessionName = 'PvDefault'
    IndexName = 'ByIngredientLot'
    TableName = 'LotCost'
    Left = 238
    Top = 68
  end
  object pvtblUserName: TPvTable
    DatabaseName = 'FORMIX'
    SessionName = 'PvDefault'
    IndexName = 'ByUser'
    TableName = 'UserTable'
    Left = 538
    Top = 68
  end
  object pvtblStock: TPvTable
    DatabaseName = 'FORMIX'
    IndexName = 'ByProduct'
    TableName = 'StockTable'
    Left = 238
    Top = 162
  end
  object pvtblLotIRef: TPvTable
    DatabaseName = 'FORMIX'
    SessionName = 'PvDefault'
    IndexName = 'ByIngredientMID'
    TableName = 'LotIRef'
    Left = 238
    Top = 204
  end
  object pvtblRORejectedOffering: TPvTable
    TableName = 'RO_REJECTED_OFFERING'
    Left = 344
    Top = 110
  end
  object pvtblRejections: TPvTable
    TableName = 'REJECTIONS'
    Left = 344
    Top = 198
  end
  object pvvtblRejectReasons: TPvTable
    TableName = 'REJECT_REASONS'
    Left = 344
    Top = 154
  end
  object pvtblROOverrides: TPvTable
    TableName = 'RO_OVERRIDES'
    Left = 344
    Top = 70
  end
  object pvtblSourceCodes: TPvTable
    AutoRefresh = True
    DatabaseName = 'FormixDB'
    SessionName = 'PvDefault'
    TableName = 'SOURCE_CODES'
    Left = 32
    Top = 233
  end
  object pvtblTransactionsForMixCalcs: TPvTable
    SessionName = 'PvDefault'
    AfterOpen = pvtblTransactionsAfterOpen
    TableName = 'Transactions'
    Left = 32
    Top = 280
  end
  object rxmIngredientsCache: TRxMemoryData
    FieldDefs = <>
    Left = 136
    Top = 224
    object rxmIngredientsCacheIngredient: TStringField
      FieldName = 'Ingredient'
      Size = 8
    end
    object rxmIngredientsCacheDescription: TStringField
      FieldName = 'Description'
      Size = 30
    end
    object rxmIngredientsCachePrep_Area: TStringField
      FieldName = 'Prep_Area'
      Size = 8
    end
    object rxmIngredientsCacheNo_Tare: TBooleanField
      FieldName = 'No_Tare'
    end
  end
  object rxmRecipeCache: TRxMemoryData
    FieldDefs = <>
    Left = 152
    Top = 212
    object rxmRecipeCacheRecipe_Code: TStringField
      FieldName = 'Recipe_Code'
      Size = 8
    end
    object rxmRecipeCacheDescription: TStringField
      FieldName = 'Description'
      Size = 30
    end
  end
  object pvtblTransWarnings: TPvTable
    TableName = 'Trans_Warnings'
    Left = 440
    Top = 72
  end
  object rxmTermRegSettings: TRxMemoryData
    FieldDefs = <>
    Left = 480
    Top = 184
    object rxmTermRegSettingsSettingNo: TIntegerField
      FieldName = 'SettingNo'
    end
    object rxmTermRegSettingsTag: TStringField
      DisplayWidth = 40
      FieldName = 'Tag'
      Size = 64
    end
    object rxmTermRegSettingsSystemWide: TBooleanField
      FieldName = 'SystemWide'
    end
    object rxmTermRegSettingsTermScaleNo: TWordField
      FieldName = 'TermScaleNo'
    end
    object rxmTermRegSettingsValue: TStringField
      DisplayWidth = 40
      FieldName = 'Value'
      Size = 100
    end
    object rxmTermRegSettingsDefaultValue: TStringField
      DisplayWidth = 40
      FieldName = 'DefaultValue'
      Size = 100
    end
    object rxmTermRegSettingsDescription: TStringField
      FieldName = 'Description'
      Size = 128
    end
  end
end
