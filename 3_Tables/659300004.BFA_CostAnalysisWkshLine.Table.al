table 659300004 "Cost Analysis Wksh. Line"
{
    Caption = 'Cost Analysis Worksheet Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Production Order Status"; Enum "Production Order Status")
        {
            Caption = 'Production Order Status';
        }
        field(11; "Production Order No."; Code[20])
        {
            Caption = 'Production Order No.';
            TableRelation = "Production Order"."No." where(Status = field("Production Order Status"));
        }
        field(12; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
            // Not derived automatically: standard Business Central production orders do not store a
            // link back to a sales order header, so this is left for the planner to fill in manually
            // if they want to tag the worksheet line to a sales order.
        }
        field(13; "Item No."; Code[20])
        {
            Caption = 'Item No. (Produced)';
            TableRelation = Item;
        }
        field(20; "Cost Component"; Enum "Cost Analysis Component")
        {
            Caption = 'Cost Component';
        }
        field(21; "Source Type"; Enum "Cost Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(22; "Source Line No."; Code[10])
        {
            Caption = 'Source Line No.';
            // Prod. Order Component "Line No." (as text) or Prod. Order Routing Line "Operation No."
        }
        field(30; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            // Component item no. for Material lines; Work/Machine Center no. for Capacity/Overhead lines.
            // Intentionally has no TableRelation since it is polymorphic across those two cases.
        }
        field(31; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                UpdateAmount();
            end;
        }
        field(41; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(50; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                UpdateAmount();
            end;
        }
        field(51; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatType = 1;
            // Editable independently too, so a planner can override a suggested line before registering it.
        }
        field(60; "Calculation Date"; Date)
        {
            Caption = 'Calculation Date';
        }
        field(70; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(71; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(80; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Production Order No.", "Line No.")
        {
            Clustered = true;
        }
        key(Order; "Production Order Status", "Production Order No.", "Cost Component")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(SalesOrder; "Sales Order No.")
        {
        }
    }

    trigger OnInsert()
    var
        CostAnalysisWkshLine: Record "Cost Analysis Wksh. Line";
    begin
        if "Line No." = 0 then begin
            CostAnalysisWkshLine.SetCurrentKey("Production Order No.", "Line No.");
            CostAnalysisWkshLine.SetRange("Production Order Status", "Production Order Status");
            CostAnalysisWkshLine.SetRange("Production Order No.", "Production Order No.");
            CostAnalysisWkshLine.SetAscending("Line No.", true);
            if CostAnalysisWkshLine.FindLast() then
                "Line No." := CostAnalysisWkshLine."Line No." + 10000
            else
                "Line No." := 10000;
        end;
        if "Calculation Date" = 0D then
            "Calculation Date" := WorkDate();
        if "User ID" = '' then
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        UpdateAmount();
    end;

    local procedure UpdateAmount()
    var
        Setup: Record "Cost Analysis Setup";
    begin
        Setup.GetSetup();
        "Amount (LCY)" := Round(Quantity * "Unit Cost", Setup."Rounding Precision");
    end;
}
