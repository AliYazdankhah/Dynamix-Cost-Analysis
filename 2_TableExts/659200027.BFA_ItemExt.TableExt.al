tableextension 659200027 "ItemExt" extends Item
{
    fields
    {
        field(659700010; "Market Unit Cost"; Decimal)
        {
            Caption = 'Market Unit Cost (LCY)';
            DecimalPlaces = 2 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Error(FieldIsCalculatedErr, FieldCaption("Market Unit Cost"));
            end;
        }

        field(659700011; "BOM Unit Cost"; Decimal)
        {
            Caption = 'BOM Unit Cost (LCY)';
            DecimalPlaces = 2 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Error(FieldIsCalculatedErr, FieldCaption("BOM Unit Cost"));
            end;
        }

        field(659700012; "Custom Margin"; Decimal)
        {
            Caption = 'Custom Margin';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            ToolTip = 'Multiplier applied to Calculated Price to produce IMOS Price on the Cost Analysis Worksheet. Does not affect BOM Unit Cost. 0 is treated as 1 (no markup).';
        }
    }

    var
        FieldIsCalculatedErr: Label '%1 is calculated by the Cost Analysis engine and cannot be edited directly.', Comment = '%1 = field caption';
}
