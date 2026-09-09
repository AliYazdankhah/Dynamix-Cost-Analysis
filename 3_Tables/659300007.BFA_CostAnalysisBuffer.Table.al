table 659300007 "CostAnalysisBuffer"
{
    Caption = 'Cost Analysis Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Cost Component"; Option)
        {
            Caption = 'Cost Component';
            OptionMembers = Component,Routing,Import;
            OptionCaption = 'Component,Routing,Import';
        }
        field(11; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 0;
        }
        field(21; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 0 : 0;
        }
        field(22; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 0 : 0;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}