pageextension 659100829 "Firm Planned Prod. Order" extends "Firm Planned Prod. Order"
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
                Caption = 'Cost Analysis';
                Image = AnalysisView;
                ApplicationArea = All;

                trigger OnAction()
                var
                    StartPage: Page "Cost Analysis Start";
                begin
                    StartPage.SetSalesOrder(Rec."No.");
                    StartPage.RunModal();
                end;
            }
        }
    }
}