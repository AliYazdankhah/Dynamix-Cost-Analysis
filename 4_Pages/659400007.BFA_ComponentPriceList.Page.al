page 659400007 "ComponentPriceList"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "ComponentPrice";
    Caption = 'Component Prices';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Import from Excel")
            {
                ApplicationArea = All;
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CostImportMgmt.ImportComponentPrices();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CostImportMgmt: Codeunit "CostImportMgmt";
}