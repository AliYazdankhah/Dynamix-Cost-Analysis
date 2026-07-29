report 659500001 "Cost Analysis by Order"
{
    Caption = 'Cost Analysis by Order';
    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    RDLCLayout = 'IM_CostAnalysisByOrder.rdlc';
    // NOTE: this file only fixes the dataset/logic. The actual .rdlc (or Word) layout still needs
    // to be designed in Report Designer / Word - it cannot be generated as plain text.

    dataset
    {
        dataitem(Order; "Production Order")
        {
            RequestFilterFields = "No.", Status;

            column(No_Order; "No.") { }
            column(Description_Order; Description) { }
            column(Status_Order; Status) { }
            column(TotalAmount_Order; TotalAmount) { }

            dataitem(Entry; "Cost Analysis Entry")
            {
                DataItemLink = "Production Order Status" = field(Status), "Production Order No." = field("No.");
                DataItemTableView = sorting("Production Order Status", "Production Order No.", "Cost Component");
                RequestFilterFields = "Posting Date";

                column(CostComponent_Entry; Format("Cost Component")) { }
                column(Description_Entry; Description) { }
                column(SourceNo_Entry; "Source No.") { }
                column(Quantity_Entry; Quantity) { }
                column(UnitCost_Entry; "Unit Cost") { }
                column(Amount_Entry; "Amount (LCY)") { }
                column(PostingDate_Entry; "Posting Date") { }

                trigger OnAfterGetRecord()
                begin
                    TotalAmount += "Amount (LCY)";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TotalAmount := 0;
            end;
        }
    }

    procedure SetOrderFilter(OrderNo: Code[20])
    begin
        Order.SetRange("No.", OrderNo);
    end;

    var
        TotalAmount: Decimal;
}
