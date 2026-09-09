pageextension 659100030 "ItemCardExt" extends "Item Card"
{
    layout
    {
        addafter("Unit Cost")
        {
            field("Analysis Unit Cost"; Rec."Analysis Unit Cost")
            {
                ApplicationArea = All;

                trigger OnDrillDown()
                var
                    CostCalcMgmt: Codeunit "CostCalcMgmt";
                    Buffer: Record "CostAnalysisBuffer" temporary;
                begin
                    CostCalcMgmt.BuildCostBreakdown(Rec, Buffer);
                    Page.Run(Page::"CostAnalysisBreakdown", Buffer);
                end;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("Calculate Analysis Cost")
            {
                ApplicationArea = All;
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CostCalcMgmt.CalculateItemCost(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CostCalcMgmt: Codeunit "CostCalcMgmt";
}