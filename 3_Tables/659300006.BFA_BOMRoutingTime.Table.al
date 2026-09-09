table 659300006 "BOMRoutingTime"
{
    Caption = 'BOM Routing Time';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "BOM No."; Code[20])
        {
            Caption = 'BOM No.';
            TableRelation = "Production BOM Header";
        }
        field(2; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(3; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";
        }
        field(4; "Time Average"; Decimal)
        {
            Caption = 'Time Average';
            DecimalPlaces = 2 : 5;
        }
    }

    keys
    {
        key(PK; "BOM No.", "Routing No.", "Work Center No.")
        {
            Clustered = true;
        }
    }
}