codeunit 659700003 "CostCalcMgmt"
{
    procedure CalculateAll()
    var
        Item: Record Item;
    begin
        Item.SetCurrentKey("Low-Level Code");
        Item.Ascending(false);
        Item.SetRange(Type, Item.Type::Inventory);
        if Item.FindSet(true) then
            repeat
                CalculateItemCost(Item);
            until Item.Next() = 0;
    end;

    procedure CalculateItemCost(var Item: Record Item)
    var
        ComponentPrice: Record "ComponentPrice";
    begin
        if Item."Production BOM No." <> '' then begin
            Item."Analysis Unit Cost" := CalculateBOMCost(Item) + CalculateRoutingCost(Item);
            Item.Modify();
            exit;
        end;

        if ComponentPrice.Get(Item."No.") then begin
            Item."Analysis Unit Cost" := ComponentPrice."Unit Price";
            Item.Modify();
        end;
    end;

    local procedure CalculateBOMCost(Item: Record Item): Decimal
    var
        ProdBOMLine: Record "Production BOM Line";
        CompItem: Record Item;
        VersionCode: Code[20];
        Total: Decimal;
    begin
        VersionCode := GetCertifiedVersion(Item."Production BOM No.");

        ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProdBOMLine.SetRange("Version Code", VersionCode);
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        if ProdBOMLine.FindSet() then
            repeat
                if CompItem.Get(ProdBOMLine."No.") then
                    Total += ProdBOMLine."Quantity per" * CompItem."Analysis Unit Cost";
            until ProdBOMLine.Next() = 0;

        exit(Total);
    end;

    local procedure CalculateRoutingCost(Item: Record Item): Decimal
    var
        RoutingTime: Record "BOMRoutingTime";
        WorkCenter: Record "Work Center";
        Total: Decimal;
    begin
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

    procedure BuildCostBreakdown(Item: Record Item; var Buffer: Record "CostAnalysisBuffer" temporary)
    var
        ProdBOMLine: Record "Production BOM Line";
        CompItem: Record Item;
        ComponentPrice: Record "ComponentPrice";
        RoutingTime: Record "BOMRoutingTime";
        WorkCenter: Record "Work Center";
        VersionCode: Code[20];
        LineNo: Integer;
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
                    Buffer."Unit Cost" := CompItem."Analysis Unit Cost";
                    Buffer.Amount := ProdBOMLine."Quantity per" * CompItem."Analysis Unit Cost";
                    Buffer.Insert();

                    if CompItem."Production BOM No." = '' then
                        if ComponentPrice.Get(CompItem."No.") then begin
                            LineNo += 1;
                            Buffer.Init();
                            Buffer."Line No." := LineNo;
                            Buffer."Cost Component" := Buffer."Cost Component"::Import;
                            Buffer."Source No." := CompItem."No.";
                            Buffer.Description := 'From Excel Import';
                            Buffer.Quantity := 1;
                            Buffer."Unit Cost" := ComponentPrice."Unit Price";
                            Buffer.Amount := ComponentPrice."Unit Price";
                            Buffer.Insert();
                        end;
                end;
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
}