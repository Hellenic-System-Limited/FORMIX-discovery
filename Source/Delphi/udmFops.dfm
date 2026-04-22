inherited dmFops: TdmFops
  OnCreate = DataModuleCreate
  inherited StartupTable: TPvTable
    SessionName = 'PvSession1_2'
  end
  inherited UserTable: TPvTable
    SessionName = 'PvSession1_2'
  end
  inherited FileSecurityTable: TPvTable
    SessionName = 'PvSession1_2'
  end
  inherited SecurityTokens: TPvTable
    SessionName = 'PvSession1_2'
  end
  inherited Folders: TPvTable
    SessionName = 'PvSession1_2'
  end
  inherited Items: TPvTable
    SessionName = 'PvSession1_2'
  end
  inherited Registry: TPvTable
    SessionName = 'PvSession1_2'
  end
  object pvtblTransactions: TPvTable
    DatabaseName = 'FOPS6DB'
    SessionName = 'PvDefault'
    TableName = 'TRANSACTIONS'
    Left = 144
    Top = 68
  end
  object pvtblProducts: TPvTable
    DatabaseName = 'FOPS6DB'
    SessionName = 'PvDefault'
    TableName = 'PRODUCTS'
    Left = 228
    Top = 68
  end
  object pvtblCommBuff: TPvTable
    DatabaseName = 'FOPS6DB'
    SessionName = 'PvDefault'
    TableName = 'Comm_Buffer'
    Left = 144
    Top = 124
  end
  object pvtblGroupLines: TPvTable
    DatabaseName = 'FOPS6DB'
    SessionName = 'PvDefault'
    TableName = 'GROUP_LINES'
    Left = 228
    Top = 124
    object pvtblGroupLinesgroup_code: TStringField
      FieldName = 'group_code'
      Size = 8
    end
    object pvtblGroupLinesproduct_code: TStringField
      FieldName = 'product_code'
      Size = 8
    end
  end
  object pvtblTransSource: TPvTable
    DatabaseName = 'FOPS6DB'
    SessionName = 'PvDefault'
    TableName = 'TRANSACTION_SOURCE'
    Left = 290
    Top = 70
  end
  object pvtblTraceCodes: TPvTable
    DatabaseName = 'FOPS6DB'
    SessionName = 'PvDefault'
    TableName = 'TRACE_CODES'
    Left = 356
    Top = 74
  end
  object pvtblLabelDetail: TPvTable
    TableName = 'LABEL_DETAIL'
    Left = 426
    Top = 76
  end
  object pvtblProductConcession: TPvTable
    TableName = 'PRODUCT_CONCESSION'
    Left = 312
    Top = 117
  end
end
