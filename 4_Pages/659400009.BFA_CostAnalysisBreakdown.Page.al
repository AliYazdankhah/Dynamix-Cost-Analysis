page 659400009 "CostAnalysisBreakdown"
{
    PageType = List;
    SourceTable = "CostAnalysisBuffer";
    SourceTableTemporary = true;
    Caption = 'Cost Analysis Breakdown';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Cost Component"; Rec."Cost Component")
                {
                }
                field("Source No."; Rec."Source No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Quantity; Rec.Quantity)
                {
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Select multiple lines to see a running total in the status bar.';
                }
            }
        }
    }
}