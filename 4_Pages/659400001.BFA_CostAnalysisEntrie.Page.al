page 659400001 "Cost Analysis Entries"
{
    PageType = List;
    SourceTable = "Cost Analysis Entry";
    UsageCategory = History;
    ApplicationArea = All;
    Caption = 'Cost Analysis Entries';

    layout
    {
        area(content)
        {
            repeater(Entries)
            {
                field("Analysis No."; Rec."Analysis No.")
                {
                }
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Production Order Status"; Rec."Production Order Status")
                {
                }
                field("Production Order No."; Rec."Production Order No.")
                {
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Cost Component"; Rec."Cost Component")
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
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Select multiple lines to see a running total in the status bar.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                }
                field("Calculation Date"; Rec."Calculation Date")
                {
                }
                field("Calculated Amount"; Rec."Calculated Amount")
                {
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Entry)
            {
                Caption = 'Entry';
                Image = Entries;

                action(ViewOrder)
                {
                    ApplicationArea = All;
                    Caption = 'Production Order';
                    Image = Find;
                    ToolTip = 'Open the production order that this cost entry originates from.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                        PageId: Integer;
                    begin
                        if Rec."Production Order No." = '' then
                            exit;
                        if not ProdOrder.Get(Rec."Production Order Status", Rec."Production Order No.") then
                            exit;

                        case Rec."Production Order Status" of
                            Rec."Production Order Status"::Simulated:
                                PageId := Page::"Simulated Production Order";
                            Rec."Production Order Status"::Planned:
                                PageId := Page::"Planned Production Order";
                            Rec."Production Order Status"::"Firm Planned":
                                PageId := Page::"Firm Planned Prod. Order";
                            Rec."Production Order Status"::Released:
                                PageId := Page::"Released Production Order";
                            Rec."Production Order Status"::Finished:
                                PageId := Page::"Finished Production Orders";
                            else
                                exit;
                        end;

                        Page.RunModal(PageId, ProdOrder);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Related Information';
                actionref(ViewOrder_Promoted; ViewOrder) { }
            }
        }
    }
}