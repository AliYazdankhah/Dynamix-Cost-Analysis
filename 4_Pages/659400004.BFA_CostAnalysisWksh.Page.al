page 659400004 "Cost Analysis Wksh."
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Cost Analysis Worksheet';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Cost Analysis Wksh. Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Selection)
            {
                Caption = 'Selection';

                field(SalesOrderNoFilter; SalesOrderNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Order No.';
                    ToolTip = 'Specifies the sales order that Suggest Lines, Register, and Start Analysis work against.';
                    TableRelation = "Sales Header"."No." where("Document Type" = const(Order));

                    trigger OnValidate()
                    begin
                        if SalesOrderNoFilter = '' then
                            Rec.SetRange("Sales Order No.")
                        else
                            Rec.SetRange("Sales Order No.", SalesOrderNoFilter);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control1000)
            {
                ShowCaption = false;

                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    Editable = false;
                }
                field("Production Order Status"; Rec."Production Order Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the production order.';
                }
                field("Production Order No."; Rec."Production Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the production order.';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sales order number that this line is linked to.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the produced item.';
                }
                field("Cost Component"; Rec."Cost Component")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this line is for Material, Capacity, or Overhead costs.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source type that the cost line originates from.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number within the source document.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the source (item or work center/machine center).';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the cost line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity of the cost component.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure for the quantity.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the cost per unit.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount in local currency.';
                }
                field("Calculation Date"; Rec."Calculation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the line was calculated.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a dimension value for analysis.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a second dimension value for analysis.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Related)
            {
                Caption = 'Related';
                Image = Relationship;

                action(SalesOrder)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Order';
                    Image = Order;
                    RunObject = Page "Sales Order";
                    RunPageLink = "No." = field("Sales Order No.");
                    ToolTip = 'Open the sales order that this line is linked to.';
                }
                action(ProductionOrder)
                {
                    ApplicationArea = All;
                    Caption = 'Production Order';
                    Image = ProductionOrder;
                    ToolTip = 'Open the production order that this line is linked to.';

                    trigger OnAction()
                    begin
                        OpenProductionOrder(Rec."Production Order Status", Rec."Production Order No.");
                    end;
                }
            }
            group(Analysis)
            {
                Caption = 'Analysis';
                Image = AnalysisView;

                action(StartAnalysis)
                {
                    ApplicationArea = All;
                    Caption = 'Start Analysis';
                    Image = Start;
                    ToolTip = 'Run a cost analysis for the sales order entered above (this will calculate and register the results directly).';

                    trigger OnAction()
                    var
                        CostAnalysisStart: Page "Cost Analysis Start";
                    begin
                        CostAnalysisStart.SetSalesOrder(SalesOrderNoFilter);
                        CostAnalysisStart.SetAnalysisNo(AnalysisNoFilter); // new procedure, see below
                        CostAnalysisStart.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";

                action(SuggestLines)
                {
                    ApplicationArea = All;
                    Caption = 'Suggest Lines';
                    Image = Import;
                    ToolTip = 'Calculate and load cost worksheet lines from all production orders linked to the sales order entered above.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                        CostMgt: Codeunit "Cost Analysis Mgt.";
                    begin
                        VerifySalesOrderNoFilter();

                        ProdOrder.SetRange(IM_ORDERID, SalesOrderNoFilter);
                        if ProdOrder.IsEmpty() then
                            Error('No production orders found for sales order %1.', SalesOrderNoFilter);

                        ProdOrder.FindSet();
                        repeat
                            CostMgt.CalculateCostsForOrder(ProdOrder."No.", ProdOrder.Status);
                        until ProdOrder.Next() = 0;

                        CurrPage.Update(false);
                        Message('Worksheet lines generated for sales order %1.', SalesOrderNoFilter);
                    end;
                }
                action(Register)
                {
                    ApplicationArea = All;
                    Caption = 'Register';
                    Image = Approve;
                    ToolTip = 'Register the current worksheet lines for the sales order entered above into a cost analysis header and entries.';

                    trigger OnAction()
                    var
                        CostWkshLine: Record "Cost Analysis Wksh. Line";
                        CostMgt: Codeunit "Cost Analysis Mgt.";
                        CAHeader: Record "Cost Analysis Header";
                    begin
                        VerifySalesOrderNoFilter();

                        CostWkshLine.CopyFilters(Rec);
                        CostWkshLine.SetRange("Sales Order No.", SalesOrderNoFilter);
                        if CostWkshLine.IsEmpty() then
                            Message('No worksheet lines exist for sales order %1.', SalesOrderNoFilter)
                        else begin
                            CostMgt.RegisterWorksheetLines(SalesOrderNoFilter, CostWkshLine, AnalysisNoFilter);
                            CAHeader.SetRange("Sales Order No.", SalesOrderNoFilter);
                            if CAHeader.FindLast() then
                                Message('Lines registered under analysis %1.', CAHeader."Analysis No.");
                        end;

                        CurrPage.Update(false);
                    end;
                }
            }
            group(PageActions)
            {
                Caption = 'Page';
                Image = "Page";

                action(EditInExcel)
                {
                    ApplicationArea = All;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the worksheet to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                    begin
                        EditinExcel.EditPageInExcel('Cost Analysis Worksheet', CurrPage.ObjectId(false), Rec.GetView(false));
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(SuggestLines_Promoted; SuggestLines) { }
                actionref(Register_Promoted; Register) { }
            }
            group(Category_Analysis)
            {
                Caption = 'Analysis';
                actionref(StartAnalysis_Promoted; StartAnalysis) { }
            }
            group(Category_Related)
            {
                Caption = 'Related';
                actionref(SalesOrder_Promoted; SalesOrder) { }
                actionref(ProductionOrder_Promoted; ProductionOrder) { }
            }
            group(Category_Page)
            {
                Caption = 'Page';
                actionref(EditInExcel_Promoted; EditInExcel) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
        InboundFilter: Text;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();

        // If the page was opened with a Sales Order No. filter already applied
        // (e.g. RunPageLink from the Cost Analysis Header/List), pick it up so
        // the user doesn't have to re-enter it in the Selection field.
        InboundFilter := Rec.GetFilter("Sales Order No.");
        if InboundFilter <> '' then
            SalesOrderNoFilter := CopyStr(InboundFilter, 1, MaxStrLen(SalesOrderNoFilter));
    end;

    local procedure VerifySalesOrderNoFilter()
    begin
        if SalesOrderNoFilter = '' then
            Error('Enter a Sales Order No. in the Selection field above first.');
    end;

    local procedure OpenProductionOrder(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    var
        ProdOrder: Record "Production Order";
        PageId: Integer;
    begin
        if ProdOrderNo = '' then
            exit;
        if not ProdOrder.Get(ProdOrderStatus, ProdOrderNo) then
            exit;

        case ProdOrderStatus of
            ProdOrderStatus::Simulated:
                PageId := Page::"Simulated Production Order";
            ProdOrderStatus::Planned:
                PageId := Page::"Planned Production Order";
            ProdOrderStatus::"Firm Planned":
                PageId := Page::"Firm Planned Prod. Order";
            ProdOrderStatus::Released:
                PageId := Page::"Released Production Order";
            ProdOrderStatus::Finished:
                PageId := Page::"Finished Production Orders";
            else
                exit;
        end;

        Page.RunModal(PageId, ProdOrder);
    end;

    procedure SetContext(NewSalesOrderNo: Code[20]; NewAnalysisNo: Code[20])
    begin
        SalesOrderNoFilter := NewSalesOrderNo;
        AnalysisNoFilter := NewAnalysisNo;
        if SalesOrderNoFilter = '' then
            Rec.SetRange("Sales Order No.")
        else
            Rec.SetRange("Sales Order No.", SalesOrderNoFilter);
        CurrPage.Update(false);
    end;

    var
        SalesOrderNoFilter: Code[20];
        AnalysisNoFilter: Code[20];
        IsSaaSExcelAddinEnabled: Boolean;
}