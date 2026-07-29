page 659400003 "Cost Analysis Start"
{
    PageType = ConfirmationDialog;
    ApplicationArea = All;
    Caption = 'Start Cost Analysis';
    Editable = true;

    layout
    {
        area(content)
        {
            group(OrderSelection)
            {
                field("Sales Order No."; SalesOrderNo)
                {
                    Caption = 'Sales Order No.';
                    ApplicationArea = All;
                    TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
                    trigger OnValidate()
                    begin
                        UpdateProdOrderInfo();
                    end;
                }
                field("No. of Production Orders"; ProdOrderCount)
                {
                    Caption = 'No. of Production Orders';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(AnalysisOptions)
            {
                field("Currency Code"; CurrencyCode)
                {
                    Caption = 'Currency Code';
                    ApplicationArea = All;
                    TableRelation = Currency;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CostMgt: Codeunit "Cost Analysis Mgt.";
    begin
        if CloseAction = CloseAction::Yes then begin
            if SalesOrderNo = '' then
                Error('Please select a sales order number.');

            // Re-validate to make sure we still have at least one linked production order
            UpdateProdOrderInfo();
            if ProdOrderCount = 0 then
                Error('No production order found for sales order %1.', SalesOrderNo);

            CostMgt.RunAnalysisForOrder(SalesOrderNo, AnalysisType, CurrencyCode, ExistingAnalysisNo);
            Message('Analysis completed. A new analysis header has been created with number %1, covering %2 production order(s).',
                GetLastAnalysisNo(SalesOrderNo), ProdOrderCount);
        end
    end;

    trigger OnOpenPage()
    begin
        if SalesOrderNo <> '' then
            UpdateProdOrderInfo();
    end;

    procedure SetSalesOrder(NewSalesOrderNo: Code[20])
    begin
        SalesOrderNo := NewSalesOrderNo;
        UpdateProdOrderInfo();
    end;

    local procedure UpdateProdOrderInfo()
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrderCount := 0;

        if SalesOrderNo <> '' then begin
            ProdOrder.SetRange(IM_ORDERID, SalesOrderNo);
            ProdOrderCount := ProdOrder.Count();
            if ProdOrderCount = 0 then
                Error('No production order found for sales order %1.', SalesOrderNo);
        end;
        CurrPage.Update(false);
    end;

    local procedure GetLastAnalysisNo(SalesOrderNo: Code[20]): Code[20]
    var
        CAHeader: Record "Cost Analysis Header";
    begin
        CAHeader.SetRange("Sales Order No.", SalesOrderNo);
        if CAHeader.FindLast() then
            exit(CAHeader."Analysis No.")
        else
            exit('');
    end;

    var
        ExistingAnalysisNo: Code[20];

    procedure SetAnalysisNo(NewAnalysisNo: Code[20])
    begin
        ExistingAnalysisNo := NewAnalysisNo;
    end;

    var
        SalesOrderNo: Code[20];
        ProdOrderCount: Integer;
        AnalysisType: Option Standard,"With Overhead","With Exchange Rate";
        CurrencyCode: Code[10];
}