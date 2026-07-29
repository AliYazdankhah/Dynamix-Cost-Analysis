tableextension 659205405 "Production Order" extends "Production Order"
{
    fields
    {
        field(659400001; "Total Material Cost"; Decimal)
        {
            Caption = 'Total Material Cost';
            FieldClass = FlowField;
            Editable = false;
            AutoFormatType = 1;
            CalcFormula = sum("Cost Analysis Entry"."Amount (LCY)"
                where("Production Order Status" = field(Status),
                      "Production Order No." = field("No."),
                      "Cost Component" = const(Material)));
        }
        field(659400002; "Total Capacity Cost"; Decimal)
        {
            Caption = 'Total Capacity Cost';
            FieldClass = FlowField;
            Editable = false;
            AutoFormatType = 1;
            CalcFormula = sum("Cost Analysis Entry"."Amount (LCY)"
                where("Production Order Status" = field(Status),
                      "Production Order No." = field("No."),
                      "Cost Component" = const(Capacity)));
        }
        field(659400003; "Total Overhead Cost"; Decimal)
        {
            Caption = 'Total Overhead Cost';
            FieldClass = FlowField;
            Editable = false;
            AutoFormatType = 1;
            CalcFormula = sum("Cost Analysis Entry"."Amount (LCY)"
                where("Production Order Status" = field(Status),
                      "Production Order No." = field("No."),
                      "Cost Component" = const(Overhead)));
        }
        field(659400004; "Total Cost (Analysis)"; Decimal)
        {
            Caption = 'Total Cost (Cost Analysis)';
            FieldClass = FlowField;
            Editable = false;
            AutoFormatType = 1;
            CalcFormula = sum("Cost Analysis Entry"."Amount (LCY)"
                where("Production Order Status" = field(Status),
                      "Production Order No." = field("No.")));
            // Material + Capacity + Overhead - the "how much will/did this order cost" answer,
            // populated once worksheet lines for this order have been registered.
        }
    }
}
