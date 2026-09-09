page 659400008 "BOMRoutingTimeList"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BOMRoutingTime";
    Caption = 'BOM Routing Times';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("BOM No."; Rec."BOM No.")
                {
                    ApplicationArea = All;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = All;
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = All;
                }
                field("Time Average"; Rec."Time Average")
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
                    CostImportMgmt.ImportRoutingTimes();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CostImportMgmt: Codeunit "CostImportMgmt";
}