page 659400006 "Cost Analysis Card"
{
    Caption = 'Cost Analysis Card';
    PageType = Card;
    SourceTable = "Cost Analysis Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Analysis No."; Rec."Analysis No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the unique number of the analysis.';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales order that was analysed.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies a description of the analysis.';
                }
                field("Calculation Date"; Rec."Calculation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the analysis was calculated.';
                }
                field("Analysis Type"; Rec."Analysis Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the analysis.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code used for the analysis.';
                }
                field("Total Amount (LCY)"; Rec."Total Amount (LCY)")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the sum of all cost entries in local currency.';
                }
                field("No. of Production Orders"; Rec."No. of Production Orders")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows how many production orders are covered by this analysis.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Entries)
            {
                ApplicationArea = All;
                Caption = 'Entries';
                Image = Entries;
                RunObject = Page "Cost Analysis Entries";
                RunPageLink = "Analysis No." = field("Analysis No.");
                ShortCutKey = 'Ctrl+F7';
                ToolTip = 'View the detailed cost entries that make up this analysis.';
            }
        }
        area(processing)
        {
            action(CostAnalysisWorksheet)
            {
                ApplicationArea = All;
                Caption = 'Cost Analysis Worksheet';
                Image = Worksheet2;
                ToolTip = 'Open the cost analysis worksheet for this analysis'' sales order.';
                trigger OnAction()
                var
                    CostWksh: Page "Cost Analysis Wksh.";
                begin
                    CostWksh.SetContext(Rec."Sales Order No.", Rec."Analysis No.");
                    CostWksh.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            actionref(CostAnalysisWorksheet_Promoted; CostAnalysisWorksheet) { }
            actionref(Entries_Promoted; Entries) { }
        }
    }
}