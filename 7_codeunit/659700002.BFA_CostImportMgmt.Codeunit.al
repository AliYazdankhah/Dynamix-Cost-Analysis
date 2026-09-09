codeunit 659700002 "CostImportMgmt"
{
    procedure ImportComponentPrices()
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        ComponentPrice: Record "ComponentPrice";
        FileInStream: InStream;
        FileName: Text;
        LastRowNo: Integer;
        RowNo: Integer;
        ItemNoText: Text;
        PriceValue: Decimal;
        CostCalcMgmt: Codeunit "CostCalcMgmt";
    begin
        if not UploadIntoStream('Select File', 'C:\Temp', ' All Files (*.*)|*.*', FileName, FileInStream) then
            exit;

        ExcelBuffer.OpenBookStream(FileInStream, 'Sheet1');
        ExcelBuffer.ReadSheet();

        if ExcelBuffer.FindLast() then
            LastRowNo := ExcelBuffer."Row No.";

        for RowNo := 2 to LastRowNo do begin
            if ExcelBuffer.Get(RowNo, 1) then begin
                ItemNoText := ExcelBuffer."Cell Value as Text";
                if ItemNoText <> '' then begin
                    PriceValue := 0;
                    if ExcelBuffer.Get(RowNo, 2) then
                        Evaluate(PriceValue, ExcelBuffer."Cell Value as Text");

                    if ComponentPrice.Get(ItemNoText) then begin
                        ComponentPrice."Unit Price" := PriceValue;
                        ComponentPrice.Modify();
                    end else begin
                        ComponentPrice.Init();
                        ComponentPrice."Item No." := ItemNoText;
                        ComponentPrice."Unit Price" := PriceValue;
                        ComponentPrice.Insert();
                    end;
                end;
            end;
        end;

        CostCalcMgmt.CalculateAll();
    end;

    procedure ImportRoutingTimes()
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        RoutingTime: Record "BOMRoutingTime";
        FileInStream: InStream;
        FileName: Text;
        LastRowNo: Integer;
        RowNo: Integer;
        BomNoText: Text;
        RoutingNoText: Text;
        WorkCenterNoText: Text;
        TimeValue: Decimal;
        CostCalcMgmt: Codeunit "CostCalcMgmt";
    begin
        if not UploadIntoStream('Select File', 'C:\Temp', ' All Files (*.*)|*.*', FileName, FileInStream) then
            exit;

        if not TryOpenSheet(ExcelBuffer, FileInStream) then begin
            Error('Could not read the Excel file. Check that the file is a valid .xlsx and that the sheet is named "Sheet1".');
        end;

        if ExcelBuffer.FindLast() then
            LastRowNo := ExcelBuffer."Row No."
        else
            Error('The sheet appears to be empty.');

        for RowNo := 2 to LastRowNo do begin
            if ExcelBuffer.Get(RowNo, 1) then begin
                BomNoText := ExcelBuffer."Cell Value as Text";
                if BomNoText <> '' then begin
                    RoutingNoText := '';
                    if ExcelBuffer.Get(RowNo, 2) then
                        RoutingNoText := ExcelBuffer."Cell Value as Text";

                    WorkCenterNoText := '';
                    if ExcelBuffer.Get(RowNo, 3) then
                        WorkCenterNoText := ExcelBuffer."Cell Value as Text";

                    TimeValue := 0;
                    if ExcelBuffer.Get(RowNo, 4) then
                        Evaluate(TimeValue, ExcelBuffer."Cell Value as Text");

                    if RoutingTime.Get(BomNoText, RoutingNoText, WorkCenterNoText) then begin
                        RoutingTime."Time Average" := TimeValue;
                        RoutingTime.Modify();
                    end else begin
                        RoutingTime.Init();
                        RoutingTime."BOM No." := BomNoText;
                        RoutingTime."Routing No." := RoutingNoText;
                        RoutingTime."Work Center No." := WorkCenterNoText;
                        RoutingTime."Time Average" := TimeValue;
                        RoutingTime.Insert();
                    end;
                end;
            end;
        end;

        CostCalcMgmt.CalculateAll();
    end;

    [TryFunction]
    local procedure TryOpenSheet(var ExcelBuffer: Record "Excel Buffer" temporary; var FileInStream: InStream)
    begin
        ExcelBuffer.OpenBookStream(FileInStream, 'Sheet1');
        ExcelBuffer.ReadSheet();
    end;
}