table 659300008 "CostAnalysis Worksheet Line"
{
    Caption = 'Cost Analysis Worksheet Line';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20]) { Caption = 'Item No.'; }
        field(2; Description; Text[100]) { Caption = 'Description'; }
        field(3; "Item Category Code"; Code[20]) { Caption = 'Item Category Code'; }
        field(4; HasBOM; Boolean) { Caption = 'Has BOM'; }
        field(5; "Use BOM Price"; Boolean) { Caption = 'Use BOM Price'; }
        field(6; "Use Vendor Price"; Boolean) { Caption = 'Use Vendor Price'; }
        field(7; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; }
        field(8; "Calculated Price"; Decimal) { Caption = 'Calculated Price'; DecimalPlaces = 2 : 5; }
        field(9; "IMOS Price"; Decimal) { Caption = 'IMOS Price'; DecimalPlaces = 2 : 5; }
        field(10; "Custom Margin"; Decimal) { Caption = 'Custom Margin'; DecimalPlaces = 2 : 5; }
        field(11; "Price Found"; Boolean) { Caption = 'Price Found'; }
        field(12; "Calc Price Style"; Text[20]) { Caption = 'Calc Price Style'; }
        field(13; "BOM Price"; Decimal) { Caption = 'BOM Price'; DecimalPlaces = 2 : 5; }
        field(14; "Vendor Price"; Decimal) { Caption = 'Vendor Price'; DecimalPlaces = 2 : 5; }
        field(15; "BOM Price Style"; Text[20]) { Caption = 'BOM Price Style'; }
        field(16; "Vendor Price Style"; Text[20]) { Caption = 'Vendor Price Style'; }
        field(17; "Use Last Receipt Price"; Boolean)
        {
            Caption = 'Use Last Receipt Price';
        }
    }

    keys
    {
        key(PK; "Item No.") { Clustered = true; }
    }
}