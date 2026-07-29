pageextension 659100831 "Released Prod. Order" extends "Released Production Order"
{
    layout
    {
        addlast(General)
        {
            field("Total Cost (Analysis)"; Rec."Total Cost (Analysis)")
            {
                ApplicationArea = All;
                ToolTip = 'Total cost from the Cost Analysis module: material + capacity + overhead, once registered.';
            }
        }
    }

    actions
    {
        addafter("&Print")
        {
            action("Cost Analysis")
            {
                Caption = 'Start Cost Analysis';
                Image = AnalysisView;
                ApplicationArea = All;

                trigger OnAction()
                var
                    StartPage: Page "Cost Analysis Start";
                begin
                    StartPage.SetSalesOrder(Rec.IM_ORDERID);
                    StartPage.RunModal();
                end;
            }
        }
    }
}