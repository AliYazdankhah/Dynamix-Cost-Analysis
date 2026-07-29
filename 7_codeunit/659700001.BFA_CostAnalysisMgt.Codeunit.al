codeunit 659700001 "Cost Analysis Mgt."
{
    procedure CalculateCostsForOrder(ProdOrderNo: Code[20]; ProdOrderStatus: Enum "Production Order Status")
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRt: Record "Prod. Order Routing Line";
        CostWkshLine: Record "Cost Analysis Wksh. Line";
        Setup: Record "Cost Analysis Setup";
        NextLineNo: Integer;
        CapacityNo: Code[20];
        OverheadRate: Decimal;
        DirectAmount: Decimal;
    begin
        if not ProdOrder.Get(ProdOrderStatus, ProdOrderNo) then
            Error(ProdOrderNotFoundErr, ProdOrderNo);

        Setup.GetSetup();

        CostWkshLine.SetRange("Production Order Status", ProdOrderStatus);
        CostWkshLine.SetRange("Production Order No.", ProdOrderNo);
        CostWkshLine.DeleteAll();
        CostWkshLine.Reset();

        NextLineNo := 10000;

        // ---- Material Components ----
        ProdOrderComp.SetRange(Status, ProdOrderStatus);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
        if ProdOrderComp.FindSet() then
            repeat
                CostWkshLine.Init();
                CostWkshLine."Line No." := NextLineNo;
                CostWkshLine."Sales Order No." := ProdOrder.IM_ORDERID;
                CostWkshLine."Production Order Status" := ProdOrderStatus;
                CostWkshLine."Production Order No." := ProdOrderNo;
                CostWkshLine."Item No." := ProdOrder."Source No.";
                CostWkshLine."Cost Component" := CostWkshLine."Cost Component"::Material;
                CostWkshLine."Source Type" := CostWkshLine."Source Type"::"Prod. Order Component";
                CostWkshLine."Source Line No." := Format(ProdOrderComp."Line No.");
                CostWkshLine."Source No." := ProdOrderComp."Item No.";
                CostWkshLine.Description := ProdOrderComp.Description;
                CostWkshLine.Quantity := ProdOrderComp."Expected Quantity";
                CostWkshLine."Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
                CostWkshLine."Unit Cost" := ProdOrderComp."Unit Cost";
                CostWkshLine."Calculation Date" := Today();
                CostWkshLine.Insert(true);
                NextLineNo += 10000;
            until ProdOrderComp.Next() = 0;

        // ---- Capacity (Routing) ----
        ProdOrderRt.SetRange(Status, ProdOrderStatus);
        ProdOrderRt.SetRange("Prod. Order No.", ProdOrderNo);
        if ProdOrderRt.FindSet() then
            repeat
                CapacityNo := ProdOrderRt."Work Center No.";
                // Direct Capacity Line
                CostWkshLine.Init();
                CostWkshLine."Line No." := NextLineNo;
                CostWkshLine."Production Order Status" := ProdOrderStatus;
                CostWkshLine."Production Order No." := ProdOrderNo;
                CostWkshLine."Sales Order No." := ProdOrder.IM_ORDERID;
                CostWkshLine."Item No." := ProdOrder."Source No.";
                CostWkshLine."Cost Component" := CostWkshLine."Cost Component"::Capacity;
                CostWkshLine."Source Type" := CostWkshLine."Source Type"::"Prod. Order Routing Line";
                CostWkshLine."Source Line No." := ProdOrderRt."Operation No.";
                CostWkshLine."Source No." := CapacityNo;
                CostWkshLine.Description := ProdOrderRt.Description;
                CostWkshLine."Unit of Measure Code" := 'MIN';
                CostWkshLine."Unit Cost" := ProdOrderRt."Direct Unit Cost";
                CostWkshLine."Calculation Date" := Today();

                ProdOrderLine.Reset();
                ProdOrderLine.SetRange(Status, ProdOrderRt.Status);
                ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRt."Prod. Order No.");
                ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRt."Routing Reference No.");
                if ProdOrderLine.FindFirst() then
                    CostWkshLine.Quantity := ProdOrderLine.Quantity;

                CostWkshLine.Insert(true);
                NextLineNo += 10000;
                DirectAmount := CostWkshLine."Amount (LCY)";

                // Overhead Line
                if Setup."Include Overhead by Default" and (CapacityNo <> '') then begin
                    OverheadRate := GetOverheadRate(ProdOrderRt);
                    if OverheadRate > 0 then begin
                        CostWkshLine.Init();
                        CostWkshLine."Line No." := NextLineNo;
                        CostWkshLine."Production Order Status" := ProdOrderStatus;
                        CostWkshLine."Production Order No." := ProdOrderNo;
                        CostWkshLine."Sales Order No." := ProdOrder.IM_ORDERID;
                        CostWkshLine."Item No." := ProdOrder."Source No.";
                        CostWkshLine."Cost Component" := CostWkshLine."Cost Component"::Overhead;
                        CostWkshLine."Source Type" := CostWkshLine."Source Type"::"Prod. Order Routing Line";
                        CostWkshLine."Source Line No." := ProdOrderRt."Operation No.";
                        CostWkshLine."Source No." := CapacityNo;
                        CostWkshLine.Description := StrSubstNo(OverheadDescTxt, ProdOrderRt.Description);

                        ProdOrderLine.Reset();
                        ProdOrderLine.SetRange(Status, ProdOrderRt.Status);
                        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRt."Prod. Order No.");
                        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRt."Routing Reference No.");
                        if ProdOrderLine.FindFirst() then
                            CostWkshLine.Quantity := ProdOrderLine.Quantity;

                        CostWkshLine."Unit of Measure Code" := '';
                        CostWkshLine."Unit Cost" := Round(OverheadRate, Setup."Rounding Precision");
                        CostWkshLine."Calculation Date" := Today();
                        CostWkshLine.Insert(true);
                        NextLineNo += 10000;
                    end;
                end;
            until ProdOrderRt.Next() = 0;
    end;

    local procedure GetOverheadRate(ProdOrderRt: Record "Prod. Order Routing Line"): Decimal
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case ProdOrderRt.Type of
            ProdOrderRt.Type::"Work Center":
                if WorkCenter.Get(ProdOrderRt."Work Center No.") then
                    exit(WorkCenter."Overhead Rate");
            ProdOrderRt.Type::"Machine Center":
                if MachineCenter.Get(ProdOrderRt."Work Center No.") then
                    exit(MachineCenter."Overhead Rate");
        end;
        exit(0);
    end;

    /// <summary>
    /// Registers every currently-staged worksheet line for SalesOrderNo under a
    /// Cost Analysis Header. If ExistingAnalysisNo is blank, a new header is created
    /// (via No. Series). If ExistingAnalysisNo is supplied, that header is reused:
    /// the user is asked to confirm, then its previously registered entries are
    /// deleted and replaced with the current worksheet lines.
    /// </summary>
    procedure RegisterWorksheetLines(SalesOrderNo: Code[20]; var CostWkshLine: Record "Cost Analysis Wksh. Line"; ExistingAnalysisNo: Code[20]): Code[20]
    var
        CAHeader: Record "Cost Analysis Header";
        CostAnalysisEntry: Record "Cost Analysis Entry";
        Setup: Record "Cost Analysis Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if not CostWkshLine.FindSet() then
            exit('');

        Setup.GetSetup();

        if (ExistingAnalysisNo <> '') and CAHeader.Get(ExistingAnalysisNo) then begin
            if not Confirm(ReRegisterConfirmQst, false, CAHeader."Analysis No.") then
                exit('');

            CostAnalysisEntry.SetRange("Analysis No.", CAHeader."Analysis No.");
            CostAnalysisEntry.DeleteAll();
        end else begin
            CAHeader.Init();
            CAHeader."Analysis No." := NoSeries.GetNextNo(Setup."Analysis No. Series");
            CAHeader."Sales Order No." := SalesOrderNo;
            CAHeader.Description := StrSubstNo(AnalysisDescTxt, SalesOrderNo, Today());
            CAHeader.Insert(true);
        end;

        CAHeader."Calculation Date" := Today();
        CAHeader.Modify();

        repeat
            CostAnalysisEntry.Init();
            CostAnalysisEntry."Entry No." := GetNextEntryNo();
            CostAnalysisEntry."Analysis No." := CAHeader."Analysis No.";
            CostAnalysisEntry."Wksh. Line No." := CostWkshLine."Line No.";
            CostAnalysisEntry."Production Order Status" := CostWkshLine."Production Order Status";
            CostAnalysisEntry."Production Order No." := CostWkshLine."Production Order No.";
            CostAnalysisEntry."Sales Order No." := CostWkshLine."Sales Order No.";
            CostAnalysisEntry."Item No." := CostWkshLine."Item No.";
            CostAnalysisEntry."Cost Component" := CostWkshLine."Cost Component";
            CostAnalysisEntry."Source Type" := CostWkshLine."Source Type";
            CostAnalysisEntry."Source Line No." := CostWkshLine."Source Line No.";
            CostAnalysisEntry."Source No." := CostWkshLine."Source No.";
            CostAnalysisEntry.Description := CostWkshLine.Description;
            CostAnalysisEntry.Quantity := CostWkshLine.Quantity;
            CostAnalysisEntry."Unit of Measure Code" := CostWkshLine."Unit of Measure Code";
            CostAnalysisEntry."Unit Cost" := CostWkshLine."Unit Cost";
            CostAnalysisEntry."Amount (LCY)" := CostWkshLine."Amount (LCY)";
            CostAnalysisEntry."Posting Date" := WorkDate();
            CostAnalysisEntry."Calculation Date" := CostWkshLine."Calculation Date";
            CostAnalysisEntry."Shortcut Dimension 1 Code" := CostWkshLine."Shortcut Dimension 1 Code";
            CostAnalysisEntry."Shortcut Dimension 2 Code" := CostWkshLine."Shortcut Dimension 2 Code";
            CostAnalysisEntry."Calculated Amount" := CostWkshLine.Quantity * CostWkshLine."Unit Cost";
            CostAnalysisEntry.Insert(true);
        until CostWkshLine.Next() = 0;

        CostWkshLine.DeleteAll();
        exit(CAHeader."Analysis No.");
    end;

    /// <summary>
    /// Entry point from the page. Finds every production order linked to this sales
    /// order (IM_ORDERID), recalculates each one's worksheet lines, then registers
    /// them all under a single analysis header. If ExistingAnalysisNo is supplied,
    /// that same header is reused/updated (with confirmation) instead of creating a new one.
    /// </summary>
    procedure RunAnalysisForOrder(SalesOrderNo: Code[20]; AnalysisType: Option; CurrencyCode: Code[10]; ExistingAnalysisNo: Code[20]): Code[20]
    var
        ProdOrder: Record "Production Order";
        CostWkshLine: Record "Cost Analysis Wksh. Line";
        CAHeader: Record "Cost Analysis Header";
        AnalysisNo: Code[20];
    begin
        CostWkshLine.SetRange("Sales Order No.", SalesOrderNo);
        CostWkshLine.DeleteAll();

        ProdOrder.SetRange(IM_ORDERID, SalesOrderNo);
        if not ProdOrder.FindSet() then
            Error(NoProdOrdersFoundErr, SalesOrderNo);

        repeat
            CalculateCostsForOrder(ProdOrder."No.", ProdOrder.Status);
        until ProdOrder.Next() = 0;

        CostWkshLine.SetRange("Sales Order No.", SalesOrderNo);
        AnalysisNo := RegisterWorksheetLines(SalesOrderNo, CostWkshLine, ExistingAnalysisNo);
        if AnalysisNo = '' then
            exit('');

        CAHeader.Get(AnalysisNo);
        CAHeader."Analysis Type" := AnalysisType;
        CAHeader."Currency Code" := CurrencyCode;
        CAHeader.Modify();
        exit(AnalysisNo);
    end;

    local procedure GetNextEntryNo() EntryNo: Integer
    var
        CAEntry: Record "Cost Analysis Entry";
    begin
        if CAEntry.FindLast() then EntryNo := CAEntry."Entry No." + 1 else EntryNo := 0;
    end;

    var
        ProdOrderNotFoundErr: Label 'Production order %1 was not found.', Comment = '%1 = production order no.';
        NoProdOrdersFoundErr: Label 'No production order found for sales order %1.', Comment = '%1 = sales order no.';
        OverheadDescTxt: Label 'Overhead on %1', Comment = '%1 = routing line description';
        AnalysisDescTxt: Label 'Cost analysis for sales order %1 on %2', Comment = '%1 = sales order no., %2 = date';
        ReRegisterConfirmQst: Label 'This will delete the previously registered entries for analysis %1 and replace them with the current worksheet lines. Continue?', Comment = '%1 = analysis no.';
}