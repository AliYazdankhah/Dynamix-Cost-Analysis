tableextension 659200027 "ItemExt" extends Item
{
    fields
    {
        field(50110; "Analysis Unit Cost"; Decimal)
        {
            Caption = 'Analysis Unit Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}