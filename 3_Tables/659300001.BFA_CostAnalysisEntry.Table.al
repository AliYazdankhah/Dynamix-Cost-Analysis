table 659300001 "Cost Analysis Entry"
{
    Caption = 'Cost Analysis Entry';
    DataClassification = CustomerContent;
    LookupPageId = "Cost Analysis Entries";
    DrillDownPageId = "Cost Analysis Entries";

    fields
    {


        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Analysis No."; code[20])
        {
            Caption = 'Analysis No.';
            TableRelation = "Cost Analysis Header"."Analysis No.";
            Editable = false;
        }
        field(3; "Wksh. Line No."; Integer)
        {
            Caption = 'Worksheet Line No.';
            Editable = false;
        }
        field(10; "Production Order Status"; Enum "Production Order Status")
        {
            Caption = 'Production Order Status';
            Editable = false;
        }
        field(11; "Production Order No."; Code[20])
        {
            Caption = 'Production Order No.';
            TableRelation = "Production Order"."No." where(Status = field("Production Order Status"));
            Editable = false;
        }
        field(12; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
            Editable = false;
        }
        field(13; "Item No."; Code[20])
        {
            Caption = 'Item No. (Produced)';
            TableRelation = Item;
            Editable = false;
        }
        field(20; "Cost Component"; Enum "Cost Analysis Component")
        {
            Caption = 'Cost Component';
            Editable = false;
        }
        field(21; "Source Type"; Enum "Cost Analysis Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(22; "Source Line No."; Code[10])
        {
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(30; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(31; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(41; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        field(50; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(51; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatType = 1;
            Editable = false;
        }
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(61; "Calculation Date"; Date)
        {
            Caption = 'Calculation Date';
            Editable = false;
            // Carried over from the worksheet line; may differ from Posting Date if registered later than calculated.
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
        field(90; "Calculated Amount"; Decimal)
        {
            Caption = 'Calculated Amount';
            Editable = false;
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Analysis; "Analysis No.")
        {
            SumIndexFields = "Amount (LCY)";
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
    begin
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        if "User ID" = '' then
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    // trigger OnDelete()
    // begin
    //     Error(CannotDeleteErr, TableCaption());
    // end;

    var
        CannotDeleteErr: Label 'You cannot delete a %1. It is a permanent record.', Comment = '%1 = table caption';
}
