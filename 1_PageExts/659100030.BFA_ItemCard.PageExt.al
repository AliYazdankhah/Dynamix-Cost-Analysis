pageextension 659100030 "ItemCardExt" extends "Item Card"
{
    layout
    {
        addafter("Unit Cost")
        {
            field("Market Unit Cost"; Rec."Market Unit Cost")
            {
                ApplicationArea = All;
                ToolTip = 'Cheapest currently valid Purchase Price List cost for this item, converted to LCY.';
            }
            field("BOM Unit Cost"; Rec."BOM Unit Cost")
            {
                ApplicationArea = All;
                ToolTip = 'BOM-rolled-up cost for this item as of today, in LCY. Drill down for a component/routing breakdown.';
                Editable = false;

                trigger OnDrillDown()
                var
                    CostCalcMgmt: Codeunit "CostCalcMgmt";
                    Buffer: Record "CostAnalysisBuffer" temporary;
                begin
                    if Rec."Production BOM No." = '' then
                        exit;

                    CostCalcMgmt.BuildCostBreakdown(Rec, WorkDate(), Buffer);
                    Page.Run(Page::"CostAnalysisBreakdown", Buffer);
                end;
            }
            field("Custom Margin"; Rec."Custom Margin")
            {
                ApplicationArea = All;
                ToolTip = 'Multiplier applied to Calculated Price on the Cost Analysis Worksheet to produce IMOS Price. Does not affect BOM Unit Cost. 0 is treated as 1 (no markup).';
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
