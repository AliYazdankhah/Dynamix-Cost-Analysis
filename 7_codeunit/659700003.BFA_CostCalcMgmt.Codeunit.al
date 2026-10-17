codeunit 659700003 "CostCalcMgmt"
{
    // ---------------------------------------------------------------------
    // Entry points
    // ---------------------------------------------------------------------

    /// <summary>
    /// Recalculates "Market Unit Cost" and "BOM Unit Cost" for all inventory
    /// items, as of today (WorkDate()). No processing-order dependency:
    /// BOM Unit Cost is computed recursively per item, so it does not matter
    /// which order items are visited in.
    /// </summary>
    procedure CalculateAll()
    var
        Item: Record Item;
    begin
        Item.SetRange(Type, Item.Type::Inventory);
        if Item.FindSet(true) then
            repeat
                CalculateItemCost(Item);
            until Item.Next() = 0;
    end;

    /// <summary>
    /// Recalculates both cost fields for a single item, as of today.
    /// Does not error if the item itself has no valid market price -
    /// that is only enforced when the item is consumed as a leaf
    /// component inside a BOM rollup (see GetBOMUnitCostLCY).
    /// </summary>
    procedure CalculateItemCost(var Item: Record Item)
    var
        Found: Boolean;
    begin
        Item."Market Unit Cost" := GetMarketUnitCostLCY(Item."No.", WorkDate(), Found);
        if not Found then
            Item."Market Unit Cost" := 0;

        if Item."Production BOM No." <> '' then
            Item."BOM Unit Cost" := GetBOMUnitCostLCY(Item, WorkDate())
        else
            Item."BOM Unit Cost" := 0;

        Item.Modify();
    end;

    // ---------------------------------------------------------------------
    // BOM rollup (recursive - safe to call for "today" or for a past date)
    // ---------------------------------------------------------------------

    /// <summary>
    /// Computes the BOM-rolled-up unit cost of Item as of AsOfDate, in LCY.
    /// Recurses into sub-assemblies rather than reading their stored
    /// "BOM Unit Cost" field, so this is correct both for live/current-date
    /// calculation and for historical report calculation. Throws an error
    /// if any true-leaf component has no valid price list line for AsOfDate.
    /// </summary>
    procedure GetBOMUnitCostLCY(Item: Record Item; AsOfDate: Date): Decimal
    var
        ProdBOMLine: Record "Production BOM Line";
        CompItem: Record Item;
        VersionCode: Code[20];
        Total: Decimal;
        LeafCost: Decimal;
        Found: Boolean;
    begin
        if Item."Production BOM No." = '' then
            Error(NotABOMItemErr, Item."No.");

        VersionCode := GetCertifiedVersion(Item."Production BOM No.");

        ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        if ProdBOMLine.FindSet() then
            repeat
                if CompItem.Get(ProdBOMLine."No.") then begin
                    if CompItem."Production BOM No." <> '' then
                        // Sub-assembly: recurse instead of trusting a stored value.
                        Total += ProdBOMLine."Quantity per" * GetBOMUnitCostLCY(CompItem, AsOfDate)
                    else begin
                        // True leaf: price is mandatory here.
                        LeafCost := GetMarketUnitCostLCY(CompItem."No.", AsOfDate, Found);
                        if not Found then
                            Error(NoValidPriceErr, CompItem."No.", AsOfDate);
                        Total += ProdBOMLine."Quantity per" * LeafCost;
                    end;
                end else
                    Error(MissingComponentItemErr, ProdBOMLine."No.", Item."Production BOM No.");
            until ProdBOMLine.Next() = 0;

        Total += CalculateRoutingCost(Item);
        exit(Total);
    end;

    local procedure CalculateRoutingCost(Item: Record Item): Decimal
    var
        RoutingTime: Record "BOMRoutingTime";
        WorkCenter: Record "Work Center";
        Total: Decimal;
    begin
        // Work center costs are always LCY - no currency conversion needed here.
        if Item."Routing No." = '' then
            exit(0);

        RoutingTime.SetRange("BOM No.", Item."Production BOM No.");
        RoutingTime.SetRange("Routing No.", Item."Routing No.");
        if RoutingTime.FindSet() then
            repeat
                if WorkCenter.Get(RoutingTime."Work Center No.") then
                    Total += RoutingTime."Time Average" * WorkCenter."Direct Unit Cost";
            until RoutingTime.Next() = 0;

        exit(Total);
    end;

    local procedure GetCertifiedVersion(ProdBOMNo: Code[20]): Code[20]
    var
        ProdBOMVersion: Record "Production BOM Version";
    begin
        ProdBOMVersion.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMVersion.SetRange(Status, ProdBOMVersion.Status::Certified);
        if ProdBOMVersion.FindFirst() then
            exit(ProdBOMVersion."Version Code");

        exit('');
    end;

    // ---------------------------------------------------------------------
    // Market price lookup (legacy Purchase Price table, date-ranged)
    // ---------------------------------------------------------------------

    /// <summary>
    /// Returns the cheapest valid Purchase Price unit cost for ItemNo as of
    /// AsOfDate, converted to LCY (IRR). Looks across all vendors (i.e. this
    /// is the vendor-agnostic "best" price used for BOM costing; a
    /// vendor-specific breakdown for reporting is a separate lookup - see
    /// GetMarketUnitCostByVendorLCY). Only considers base-rate lines
    /// (Minimum Quantity = 0) - quantity-break pricing is not applied here.
    /// Sets Found = false if no price line covers ItemNo on AsOfDate.
    /// </summary>
    /// <remarks>
    /// Sources from the legacy "Purchase Price" table (obsolete, pending
    /// removal at CLEAN23/BC26 in favor of "Price List Line") since that is
    /// what this environment currently uses for purchase pricing.
    /// Thin wrapper over GetCheapestVendorLCY - kept as its own procedure
    /// since callers here don't care which vendor won.
    /// </remarks>
    procedure GetMarketUnitCostLCY(ItemNo: Code[20]; AsOfDate: Date; var Found: Boolean): Decimal
    var
        VendorNo: Code[20];
    begin
        exit(GetCheapestVendorLCY(ItemNo, AsOfDate, VendorNo, Found));
    end;

    /// <summary>
    /// Same lookup as GetMarketUnitCostLCY, but also returns the Vendor No.
    /// of the winning (cheapest) price line. Used by the Cost Analysis
    /// Worksheet to auto-select a vendor when a line is generated.
    /// </summary>
    procedure GetCheapestVendorLCY(ItemNo: Code[20]; AsOfDate: Date; var VendorNo: Code[20]; var Found: Boolean): Decimal
    var
        PurchasePrice: Record "Purchase Price";
        LineCostLCY: Decimal;
        BestCostLCY: Decimal;
    begin
        Found := false;
        BestCostLCY := 0;
        VendorNo := '';

        PurchasePrice.SetRange("Item No.", ItemNo);
        PurchasePrice.SetRange("Minimum Quantity", 0);
        PurchasePrice.SetFilter("Starting Date", '<=%1', AsOfDate);
        PurchasePrice.SetFilter("Ending Date", '%1|>=%2', 0D, AsOfDate);

        if PurchasePrice.FindSet() then
            repeat
                LineCostLCY := ConvertToLCY(PurchasePrice."Direct Unit Cost", PurchasePrice."Currency Code", AsOfDate);
                if (not Found) or (LineCostLCY < BestCostLCY) then begin
                    BestCostLCY := LineCostLCY;
                    VendorNo := PurchasePrice."Vendor No.";
                    Found := true;
                end;
            until PurchasePrice.Next() = 0;

        exit(BestCostLCY);
    end;

    /// <summary>
    /// Same lookup as GetMarketUnitCostLCY, but restricted to a single
    /// vendor's price line(s) - for vendor-specific report drill-down and
    /// for the Cost Analysis Worksheet's "Vendor Price" toggle.
    /// </summary>
    procedure GetMarketUnitCostByVendorLCY(ItemNo: Code[20]; VendorNo: Code[20]; AsOfDate: Date; var Found: Boolean): Decimal
    var
        PurchasePrice: Record "Purchase Price";
        LineCostLCY: Decimal;
        BestCostLCY: Decimal;
    begin
        Found := false;
        BestCostLCY := 0;

        PurchasePrice.SetRange("Item No.", ItemNo);
        PurchasePrice.SetRange("Vendor No.", VendorNo);
        PurchasePrice.SetRange("Minimum Quantity", 0);
        PurchasePrice.SetFilter("Starting Date", '<=%1', AsOfDate);
        PurchasePrice.SetFilter("Ending Date", '%1|>=%2', 0D, AsOfDate);

        if PurchasePrice.FindSet() then
            repeat
                LineCostLCY := ConvertToLCY(PurchasePrice."Direct Unit Cost", PurchasePrice."Currency Code", AsOfDate);
                if (not Found) or (LineCostLCY < BestCostLCY) then begin
                    BestCostLCY := LineCostLCY;
                    Found := true;
                end;
            until PurchasePrice.Next() = 0;

        exit(BestCostLCY);
    end;

    local procedure ConvertToLCY(Amount: Decimal; CurrencyCode: Code[10]; AsOfDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode = '' then
            exit(Amount);

        exit(CurrExchRate.ExchangeAmtFCYToLCY(
            AsOfDate, CurrencyCode, Amount, CurrExchRate.ExchangeRate(AsOfDate, CurrencyCode)));
    end;

    // ---------------------------------------------------------------------
    // Cost breakdown (for the Cost Analysis Breakdown page)
    // ---------------------------------------------------------------------

    /// <summary>
    /// Builds a line-by-line cost breakdown for Item's BOM as of AsOfDate.
    /// A sub-assembly component is shown as a single rolled-up line (its
    /// own BOM is not exploded further) - consistent with how
    /// GetBOMUnitCostLCY treats it. Throws the same "no valid price" error
    /// as the rollup itself if a leaf component has no valid price list
    /// line for AsOfDate.
    /// </summary>
    procedure BuildCostBreakdown(Item: Record Item; AsOfDate: Date; var Buffer: Record "CostAnalysisBuffer" temporary)
    var
        ProdBOMLine: Record "Production BOM Line";
        CompItem: Record Item;
        RoutingTime: Record "BOMRoutingTime";
        WorkCenter: Record "Work Center";
        VersionCode: Code[20];
        LineNo: Integer;
        LeafCost: Decimal;
        Found: Boolean;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        if Item."Production BOM No." = '' then
            exit;

        VersionCode := GetCertifiedVersion(Item."Production BOM No.");

        ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        if ProdBOMLine.FindSet() then
            repeat
                if CompItem.Get(ProdBOMLine."No.") then begin
                    LineNo += 1;
                    Buffer.Init();
                    Buffer."Line No." := LineNo;
                    Buffer."Cost Component" := Buffer."Cost Component"::Component;
                    Buffer."Source No." := CompItem."No.";
                    Buffer.Description := CompItem.Description;
                    Buffer.Quantity := ProdBOMLine."Quantity per";

                    if CompItem."Production BOM No." <> '' then
                        Buffer."Unit Cost" := GetBOMUnitCostLCY(CompItem, AsOfDate)
                    else begin
                        LeafCost := GetMarketUnitCostLCY(CompItem."No.", AsOfDate, Found);
                        if not Found then
                            Error(NoValidPriceErr, CompItem."No.", AsOfDate);
                        Buffer."Unit Cost" := LeafCost;
                    end;

                    Buffer.Amount := Buffer.Quantity * Buffer."Unit Cost";
                    Buffer.Insert();
                end else
                    Error(MissingComponentItemErr, ProdBOMLine."No.", Item."Production BOM No.");
            until ProdBOMLine.Next() = 0;

        if Item."Routing No." <> '' then begin
            RoutingTime.SetRange("BOM No.", Item."Production BOM No.");
            RoutingTime.SetRange("Routing No.", Item."Routing No.");
            if RoutingTime.FindSet() then
                repeat
                    if WorkCenter.Get(RoutingTime."Work Center No.") then begin
                        LineNo += 1;
                        Buffer.Init();
                        Buffer."Line No." := LineNo;
                        Buffer."Cost Component" := Buffer."Cost Component"::Routing;
                        Buffer."Source No." := WorkCenter."No.";
                        Buffer.Description := WorkCenter.Name;
                        Buffer.Quantity := RoutingTime."Time Average";
                        Buffer."Unit Cost" := WorkCenter."Direct Unit Cost";
                        Buffer.Amount := RoutingTime."Time Average" * WorkCenter."Direct Unit Cost";
                        Buffer.Insert();
                    end;
                until RoutingTime.Next() = 0;
        end;
    end;

    var
        NoValidPriceErr: Label 'Item %1 has no valid Purchase Price line covering %2. A valid price must be entered for this item before BOM costs can be calculated.', Comment = '%1 = Item No., %2 = Date';
        NotABOMItemErr: Label 'Item %1 has no Production BOM and cannot have a BOM Unit Cost calculated.', Comment = '%1 = Item No.';
        MissingComponentItemErr: Label 'Component item %1 referenced in Production BOM %2 does not exist.', Comment = '%1 = Item No., %2 = Production BOM No.';

    /// <summary>
    /// Returns the cheapest valid Purchase Price line for ItemNo on AsOfDate,
    /// along with the vendor that provides it. Found = false if none exists.
    /// </summary>
    procedure GetCheapestVendorForItem(ItemNo: Code[20]; AsOfDate: Date; var VendorNo: Code[20]; var UnitCostLCY: Decimal; var Found: Boolean)
    var
        PurchasePrice: Record "Purchase Price";
        LineCostLCY: Decimal;
        BestCostLCY: Decimal;
    begin
        Found := false;
        VendorNo := '';
        UnitCostLCY := 0;
        BestCostLCY := 0;

        PurchasePrice.SetRange("Item No.", ItemNo);
        PurchasePrice.SetRange("Minimum Quantity", 0);
        PurchasePrice.SetFilter("Starting Date", '<=%1', AsOfDate);
        PurchasePrice.SetFilter("Ending Date", '%1|>=%2', 0D, AsOfDate);

        if PurchasePrice.FindSet() then
            repeat
                LineCostLCY := ConvertToLCY(PurchasePrice."Direct Unit Cost", PurchasePrice."Currency Code", AsOfDate);
                if (not Found) or (LineCostLCY < BestCostLCY) then begin
                    BestCostLCY := LineCostLCY;
                    VendorNo := PurchasePrice."Vendor No.";
                    Found := true;
                end;
            until PurchasePrice.Next() = 0;

        if Found then
            UnitCostLCY := BestCostLCY;
    end;

    /// <summary>
    /// Non-throwing variant of GetBOMUnitCostLCY. Returns Found = false instead
    /// of erroring when a leaf component has no valid price on AsOfDate. Used by
    /// the worksheet page so a live review never blows up mid-line.
    /// </summary>
    procedure TryGetBOMUnitCostLCY(Item: Record Item; AsOfDate: Date; var UnitCost: Decimal; var Found: Boolean)
    var
        ProdBOMLine: Record "Production BOM Line";
        CompItem: Record Item;
        VersionCode: Code[20];
        Total: Decimal;
        LeafCost: Decimal;
        LeafFound: Boolean;
        SubCost: Decimal;
        SubFound: Boolean;
        AllFound: Boolean;
    begin
        UnitCost := 0;
        Found := false;

        if Item."Production BOM No." = '' then
            exit;

        VersionCode := GetCertifiedVersion(Item."Production BOM No.");

        ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);

        AllFound := true;
        if ProdBOMLine.FindSet() then
            repeat
                if not CompItem.Get(ProdBOMLine."No.") then
                    AllFound := false
                else if CompItem."Production BOM No." <> '' then begin
                    TryGetBOMUnitCostLCY(CompItem, AsOfDate, SubCost, SubFound);
                    if not SubFound then
                        AllFound := false
                    else
                        Total += ProdBOMLine."Quantity per" * SubCost;
                end else begin
                    LeafCost := GetMarketUnitCostLCY(CompItem."No.", AsOfDate, LeafFound);
                    if not LeafFound then
                        AllFound := false
                    else
                        Total += ProdBOMLine."Quantity per" * LeafCost;
                end;
            until ProdBOMLine.Next() = 0;

        Total += CalculateRoutingCost(Item);

        UnitCost := Total;
        Found := AllFound;
    end;

    /// <summary>
    /// Returns the unit cost (LCY) from the most recent posted purchase
    /// receipt line for ItemNo on or before AsOfDate. This is the actual
    /// cost as recorded at time of receipt, not any later cost adjustment.
    /// Skips lines with a zero Unit Cost (LCY) so a reversed/corrected line
    /// can't silently zero out the result. Also returns the vendor from
    /// that receipt's header, for display purposes.
    /// </summary>
    procedure GetLastPurchReceiptCostLCY(ItemNo: Code[20]; AsOfDate: Date; var VendorNo: Code[20]; var Found: Boolean): Decimal
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        Found := false;
        VendorNo := '';

        PurchRcptLine.SetCurrentKey("No.", "Posting Date");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.SetFilter("Posting Date", '<=%1', AsOfDate);
        PurchRcptLine.SetFilter("Unit Cost (LCY)", '<>%1', 0);
        PurchRcptLine.Ascending(false);

        if PurchRcptLine.FindFirst() then begin
            Found := true;
            if PurchRcptHeader.Get(PurchRcptLine."Document No.") then
                VendorNo := PurchRcptHeader."Buy-from Vendor No.";
            exit(PurchRcptLine."Unit Cost (LCY)");
        end;

        exit(0);
    end;
}
