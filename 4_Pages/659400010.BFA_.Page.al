page 659400010 "Cost Analysis Worksheet"
{
    PageType = List;
    SourceTable = "CostAnalysis Worksheet Line";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Cost Analysis Worksheet';
    Editable = true;

    layout
    {
        area(Content)
        {
            field(ReportDate; ReportDate)
            {
                ApplicationArea = All;
                Caption = 'Report Date';
                trigger OnValidate()
                begin
                    if ItemCategoryCode <> '' then
                        LoadLines();
                end;
            }
            field(ItemCategoryCode; ItemCategoryCode)
            {
                ApplicationArea = All;
                Caption = 'Item Category Code';
                TableRelation = "Item Category".Code;
                trigger OnValidate()
                begin
                    LoadLines();
                end;
            }

            repeater(General)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        DrillDownItem: Record Item;
                    begin
                        if DrillDownItem.Get(Rec."Item No.") then
                            PAGE.Run(PAGE::"Item Card", DrillDownItem);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BOM Price"; Rec."BOM Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Rec."BOM Price Style";
                    ToolTip = 'BOM-rolled-up cost as of the report date. 0 / red = no BOM or a leaf with no valid price.';
                }
                field("Vendor Price"; Rec."Vendor Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Rec."Vendor Price Style";
                    ToolTip = 'Purchase Price for the selected vendor (or cheapest vendor) as of the report date. 0 / red = no valid price.';
                }
                field("Calculated Price"; Rec."Calculated Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = Rec."Calc Price Style";
                    ToolTip = 'Whichever of BOM Price / Vendor Price the active toggle selects.';
                }
                field("IMOS Price"; Rec."IMOS Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Calculated Price × Custom Margin (margin 0 means no markup).';
                }
                field("Use BOM Price"; Rec."Use BOM Price")
                {
                    ApplicationArea = All;
                    Enabled = Rec.HasBOM;
                    ToolTip = 'Roll up cost from the Production BOM. Disabled when the item has no BOM.';
                    trigger OnValidate()
                    begin
                        if Rec."Use BOM Price" then begin
                            Rec."Use Vendor Price" := false;
                            RecalcLine(Rec);
                        end else
                            Rec."Use BOM Price" := true;
                        CurrPage.Update(false);
                    end;
                }
                field("Use Vendor Price"; Rec."Use Vendor Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Use a vendor Purchase Price instead of the BOM rollup.';
                    trigger OnValidate()
                    begin
                        if Rec."Use Vendor Price" then begin
                            Rec."Use BOM Price" := false;
                            RecalcLine(Rec);
                        end else begin
                            Rec."Use Vendor Price" := true;
                            Rec."Use Last Receipt Price" := false;
                        end;
                        CurrPage.Update(false);
                    end;
                }
                field("Use Last Receipt Price"; Rec."Use Last Receipt Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'When on, Vendor Price is pulled from the last posted purchase receipt on or before the report date, instead of the Purchase Price list. Turning this on also switches the line to Vendor Price mode.';
                    trigger OnValidate()
                    begin
                        if Rec."Use Last Receipt Price" then begin
                            Rec."Use BOM Price" := false;
                            Rec."Use Vendor Price" := true;
                        end;
                        RecalcLine(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    TableRelation = Vendor;
                    ToolTip = 'Vendor used for Vendor Price. Auto-filled with the cheapest vendor on import.';
                    trigger OnValidate()
                    begin
                        if Rec."Vendor No." <> '' then
                            Rec."Use Vendor Price" := true;
                        Rec."Use BOM Price" := not Rec."Use Vendor Price";
                        RecalcLine(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field("Custom Margin"; Rec."Custom Margin")
                {
                    ApplicationArea = All;
                    MinValue = 0;
                    ToolTip = 'Multiplier applied to Calculated Price. Stored on the Item. 0 = no markup.';
                    trigger OnValidate()
                    begin
                        if Item.Get(Rec."Item No.") then begin
                            Item.Validate("Custom Margin", Rec."Custom Margin");
                            Item.Modify();
                        end;

                        RecalcLine(Rec);
                        CurrPage.Update(false);
                    end;
                }
                field("Price Found"; Rec."Price Found")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'No = the currently selected method has no valid price on the report date.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export to Excel';
                Image = ExportToExcel;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    ExportLinesToExcel();
                end;
            }
            action(RefreshLines)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                trigger OnAction()
                begin
                    if ItemCategoryCode <> '' then
                        LoadLines();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReportDate := WorkDate();
    end;

    var
        ReportDate: Date;
        ItemCategoryCode: Code[20];
        CostCalcMgmt: Codeunit "CostCalcMgmt";
        Item: Record Item;

    // ---------------------------------------------------------------
    // Load / recalc
    // ---------------------------------------------------------------

    local procedure LoadLines()
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if ItemCategoryCode = '' then begin
            CurrPage.Update(false);
            exit;
        end;

        Item.Reset();
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange("Item Category Code", ItemCategoryCode);
        if Item.FindSet() then
            repeat
                Rec.Init();
                Rec."Item No." := Item."No.";
                Rec.Description := Item.Description;
                Rec."Item Category Code" := Item."Item Category Code";
                Rec.HasBOM := Item."Production BOM No." <> '';
                Rec."Custom Margin" := Item."Custom Margin";
                // Default: BOM if we have one, otherwise Vendor.
                Rec."Use BOM Price" := Rec.HasBOM;
                Rec."Use Vendor Price" := not Rec.HasBOM;
                Rec.Insert();

                PrefillCheapestVendor(Rec);
                RecalcLine(Rec);
                Rec.Modify();
            until Item.Next() = 0;

        CurrPage.Update(false);
    end;

    local procedure PrefillCheapestVendor(var Line: Record "CostAnalysis Worksheet Line")
    var
        VendorNo: Code[20];
        UnitCost: Decimal;
        Found: Boolean;
    begin
        CostCalcMgmt.GetCheapestVendorForItem(Line."Item No.", ReportDate, VendorNo, UnitCost, Found);
        if Found then
            Line."Vendor No." := VendorNo;
    end;

    local procedure RecalcLine(var Line: Record "CostAnalysis Worksheet Line")
    var
        LocalItem: Record Item;
        BOMCost: Decimal;
        BOMFound: Boolean;
        VendorCost: Decimal;
        VendorFound: Boolean;
        CheapestVendor: Code[20];
        MarginToUse: Decimal;
    begin
        if not LocalItem.Get(Line."Item No.") then begin
            Line."BOM Price" := 0;
            Line."Vendor Price" := 0;
            Line."Calculated Price" := 0;
            Line."IMOS Price" := 0;
            Line."Price Found" := false;
            Line."BOM Price Style" := 'Unfavorable';
            Line."Vendor Price Style" := 'Unfavorable';
            Line."Calc Price Style" := 'Unfavorable';
            exit;
        end;

        // --- BOM side (always computed so the column is meaningful) ---
        BOMFound := false;
        BOMCost := 0;
        if LocalItem."Production BOM No." <> '' then
            CostCalcMgmt.TryGetBOMUnitCostLCY(LocalItem, ReportDate, BOMCost, BOMFound);

        if BOMFound then
            Line."BOM Price Style" := ''
        else begin
            BOMCost := 0;
            Line."BOM Price Style" := 'Unfavorable';
        end;
        Line."BOM Price" := BOMCost;

        // --- Vendor side (always computed) ---
        VendorFound := false;
        VendorCost := 0;

        if Line."Use Last Receipt Price" then begin
            VendorCost := CostCalcMgmt.GetLastPurchReceiptCostLCY(Line."Item No.", ReportDate, CheapestVendor, VendorFound);
            if VendorFound then
                Line."Vendor No." := CheapestVendor;
        end else begin
            if Line."Vendor No." = '' then begin
                CostCalcMgmt.GetCheapestVendorForItem(Line."Item No.", ReportDate, CheapestVendor, VendorCost, VendorFound);
                if VendorFound then
                    Line."Vendor No." := CheapestVendor;
            end else
                VendorCost := CostCalcMgmt.GetMarketUnitCostByVendorLCY(Line."Item No.", Line."Vendor No.", ReportDate, VendorFound);
        end;
        // --- Calculated Price = whichever toggle is active ---
        if Line."Use Vendor Price" then begin
            Line."Calculated Price" := VendorCost;
            Line."Price Found" := VendorFound;
            if VendorFound then
                Line."Calc Price Style" := ''
            else
                Line."Calc Price Style" := 'Unfavorable';
        end else begin
            Line."Calculated Price" := BOMCost;
            Line."Price Found" := BOMFound;
            if BOMFound then
                Line."Calc Price Style" := ''
            else
                Line."Calc Price Style" := 'Unfavorable';
        end;

        // Margin 0 = no markup (multiply by 1).
        if Line."Custom Margin" = 0 then
            MarginToUse := 1
        else
            MarginToUse := Line."Custom Margin";

        Line."IMOS Price" := Line."Calculated Price" * MarginToUse;
        Line.Modify();
    end;

    // ---------------------------------------------------------------
    // Excel export (currently visible/filtered lines only)
    // ---------------------------------------------------------------

    local procedure ExportLinesToExcel()
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        RowCount: Integer;
        SheetNameLbl: Label 'Cost Analysis';
        HeaderRowLbl: Label 'Cost Analysis';
    begin
        ExcelBuffer.Reset();
        ExcelBuffer.DeleteAll();
        ExcelBuffer.CreateNewBook(SheetNameLbl);

        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Item No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Description', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('BOM Price', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Vendor Price', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Calculated Price', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('IMOS Price', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Use BOM Price', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Use Vendor Price', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Vendor No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Custom Margin', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Price Found', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);

        RowCount := 0;
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                ExcelBuffer.NewRow();
                ExcelBuffer.AddColumn(Rec."Item No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Rec.Description, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Rec."BOM Price", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(Rec."Vendor Price", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(Rec."Calculated Price", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(Rec."IMOS Price", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(Format(Rec."Use BOM Price"), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Format(Rec."Use Vendor Price"), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Rec."Vendor No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Rec."Custom Margin", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(Format(Rec."Price Found"), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                RowCount += 1;
            until Rec.Next() = 0;

        if RowCount = 0 then
            exit;

        ExcelBuffer.WriteSheet(HeaderRowLbl, CompanyName(), UserId());
        ExcelBuffer.CloseBook();

        TempBlob.CreateOutStream(OutStr);
        ExcelBuffer.SaveToStream(OutStr, TRUE);
        TempBlob.CreateInStream(InStr);

        FileName := 'CostAnalysis_' + Format(ReportDate, 0, 0) + '.xlsx';
        DownloadFromStream(InStr, 'Download', '', 'Excel file', FileName);
    end;
}