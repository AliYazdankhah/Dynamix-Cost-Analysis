page 659400005 "Cost Analysis List"
{
    ApplicationArea = All;
    Caption = 'Cost Analyses';
    CardPageID = "Cost Analysis Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Cost Analysis Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;

                field("Analysis No."; Rec."Analysis No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique number of the cost analysis.';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales order that was analysed.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
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
                    ToolTip = 'Specifies the type of cost analysis.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code used in the analysis.';
                }
                field("Total Amount (LCY)"; Rec."Total Amount (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the total amount of all cost entries in local currency.';
                }
                field("No. of Production Orders"; Rec."No. of Production Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the number of production orders included in this analysis.';
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
                RunObject = Page "Cost Analysis Wksh.";
                RunPageLink = "Sales Order No." = field("Sales Order No.");
                ToolTip = 'Open the cost analysis worksheet to prepare and register analysis data for the selected sales order.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CostAnalysisWorksheet_Promoted; CostAnalysisWorksheet)
                {
                }
                actionref(Entries_Promoted; Entries)
                {
                }
            }
        }
    }

    // Optional helper: sets a filter on a linked table if you ever need
    // to pass the selected header records to another page.
    procedure SetSelection(var CostAnalysisEntry: Record "Cost Analysis Entry")
    begin
        CurrPage.SetSelectionFilter(CostAnalysisEntry);
    end;
}