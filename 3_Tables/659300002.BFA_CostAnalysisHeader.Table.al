table 659300002 "Cost Analysis Header"
{
    Caption = 'Cost Analysis Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis No."; Code[20])
        {
            Caption = 'Analysis No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Calculation Date"; Date)
        {
            Caption = 'Calculation Date';
        }
        field(40; "Analysis Type"; Option)
        {
            Caption = 'Analysis Type';
            OptionMembers = Standard,"With Overhead","With Exchange Rate";
        }
        field(50; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(60; "Total Amount (LCY)"; Decimal)
        {
            Caption = 'Total Amount (LCY)';
            AutoFormatType = 1;
            FieldClass = FlowField;
            CalcFormula = sum("Cost Analysis Entry"."Amount (LCY)" where("Analysis No." = field("Analysis No.")));
            Editable = false;
        }
        field(61; "No. of Production Orders"; Integer)
        {
            Caption = 'No. of Production Orders';
            FieldClass = FlowField;
            CalcFormula = count("Cost Analysis Entry" where("Analysis No." = field("Analysis No."),
                                                                "Production Order No." = filter(<> '')));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Analysis No.")
        {
            Clustered = true;
        }
        key(SalesOrder; "Sales Order No.")
        {
        }
    }
    trigger OnInsert()
    var
        Setup: Record "Cost Analysis Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "Analysis No." = '' then begin
            Setup.GetSetup();
            if Setup."Analysis No. Series" <> '' then
                "Analysis No." := NoSeries.GetNextNo(Setup."Analysis No. Series");
        end;
        if "Calculation Date" = 0D then
            "Calculation Date" := WorkDate();
    end;
}