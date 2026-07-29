page 659400002 "Cost Analysis Setup"
{
    PageType = Card;
    SourceTable = "Cost Analysis Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = true;
    Caption = 'Cost Analysis Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Analysis No. Series"; Rec."Analysis No. Series") { }
                field("Include Overhead by Default"; Rec."Include Overhead by Default")
                {
                    ToolTip = 'When suggesting lines, overhead lines will be included if this is checked.';
                }
                field("Auto-Register After Suggest"; Rec."Auto-Register After Suggest")
                {
                    ToolTip = 'If checked, lines will be automatically registered to Cost Analysis Entries right after they are suggested.';
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ToolTip = 'Precision used when rounding calculated amounts, for example 0.01.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
