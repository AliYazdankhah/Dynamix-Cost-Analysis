page 659400011 "Purchase Price - Admin"
{
    PageType = List;
    SourceTable = "Purchase Price";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Dynamix_Purchase Prices';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Item No."; Rec."Item No.") { }
                field("Vendor No."; Rec."Vendor No.") { }
                field("Currency Code"; Rec."Currency Code") { }
                field("Starting Date"; Rec."Starting Date") { }
                field("Ending Date"; Rec."Ending Date") { }
                field("Direct Unit Cost"; Rec."Direct Unit Cost") { }
                field("Minimum Quantity"; Rec."Minimum Quantity") { }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { }
                field("Variant Code"; Rec."Variant Code") { }
            }
        }
    }

    trigger OnOpenPage()
    var
        WarningText: Label 'This page contains confidential information and are intended solely for the use of %1. Any contents of/to this page should not be modified, deleted or inserted by unintended user. If you have reached this page by mistake, please immediately Close it';
        OnlyAdminAccessErr: Label 'only %1 can access to this page current user is :%2';
    begin
        if not (UserId = 'ADMIN') then
            Error(OnlyAdminAccessErr, 'ADMIN', UserId);
        Message(WarningText, 'ADMIN');
    end;
}