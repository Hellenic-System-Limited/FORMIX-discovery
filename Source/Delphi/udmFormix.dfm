inherited dmFormix: TdmFormix
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  object rxmMixContents: TRxMemoryData
    Active = True
    FieldDefs = <
      item
        Name = 'RecNo'
        DataType = ftInteger
      end
      item
        Name = 'OrderNo'
        DataType = ftInteger
      end
      item
        Name = 'Revision'
        DataType = ftInteger
      end
      item
        Name = 'Ingredient'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'WeightDone'
        DataType = ftFloat
      end
      item
        Name = 'WeightReq'
        DataType = ftFloat
      end
      item
        Name = 'ContsDone'
        DataType = ftInteger
      end
      item
        Name = 'ContsReq'
        DataType = ftInteger
      end
      item
        Name = 'UseBy'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'PurchOrder'
        DataType = ftString
        Size = 6
      end
      item
        Name = 'IngredientDesc'
        DataType = ftString
        Size = 30
      end
      item
        Name = 'UseByInternal'
        DataType = ftString
        Size = 6
      end>
    Left = 692
    Top = 212
    object rxmMixContentsRecNo: TIntegerField
      FieldName = 'RecNo'
    end
    object rxmMixContentsOrderNo: TIntegerField
      FieldName = 'OrderNo'
    end
    object rxmMixContentsRevision: TIntegerField
      FieldName = 'Revision'
    end
    object rxmMixContentsIngredient: TStringField
      FieldName = 'Ingredient'
      Size = 8
    end
    object rxmMixContentsWeightDone: TFloatField
      FieldName = 'WeightDone'
    end
    object rxmMixContentsWeightReq: TFloatField
      FieldName = 'WeightReq'
    end
    object rxmMixContentsContsDone: TIntegerField
      FieldName = 'ContsDone'
    end
    object rxmMixContentsContsReq: TIntegerField
      FieldName = 'ContsReq'
    end
    object rxmMixContentsUseBy: TStringField
      FieldName = 'UseBy'
      Size = 10
    end
    object rxmMixContentsPurchOrder: TStringField
      FieldName = 'PurchOrder'
      Size = 6
    end
    object rxmMixContentsIngredientDesc: TStringField
      FieldName = 'IngredientDesc'
      Size = 30
    end
    object rxmMixContentsUseByInternal: TStringField
      FieldName = 'UseByInternal'
      Size = 6
    end
  end
  object dsOrderHeader: TDataSource
    DataSet = pvtblOrderHeader
    Left = 128
    Top = 108
  end
  object memtabWarningsOverriden: TRxMemoryData
    FieldDefs = <>
    Left = 440
    Top = 168
    object memtabWarningsOverridenOverrideType: TIntegerField
      FieldName = 'OverrideType'
    end
    object memtabWarningsOverridenOverrideUser: TStringField
      FieldName = 'OverrideUser'
      Size = 8
    end
    object memtabWarningsOverridenSrcConcessionNo: TIntegerField
      FieldName = 'SrcConcessionNo'
    end
  end
  object rxmPossibleProducts: TRxMemoryData
    FieldDefs = <>
    Left = 504
    Top = 248
    object rxmPossibleProductsCode: TStringField
      FieldName = 'Code'
      Size = 8
    end
    object rxmPossibleProductsDescription: TStringField
      FieldName = 'Description'
      Size = 40
    end
  end
  object rxmPossibleGroups: TRxMemoryData
    FieldDefs = <>
    Left = 544
    Top = 232
    object rxmPossibleGroupsCode: TStringField
      FieldName = 'Code'
      Size = 8
    end
  end
end
