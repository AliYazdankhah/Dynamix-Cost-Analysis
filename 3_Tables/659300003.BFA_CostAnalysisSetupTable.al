table 659300003 "Cost Analysis Setup"
{
    Caption = 'Cost Analysis Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Include Overhead by Default"; Boolean)
        {
            Caption = 'Include Overhead by Default';
            InitValue = true;
            // Suggest Lines will skip the overhead line entirely when this is off,
            // even if a Work/Machine Center has an overhead % set up.
        }
        field(11; "Auto-Register After Suggest"; Boolean)
        {
            Caption = 'Auto-Register After Suggest';
            // If checked, the lines that "Suggest Lines" generates are immediately registered
            // to Cost Analysis Entries instead of being left on the worksheet for review.
        }
        field(12; "Rounding Precision"; Decimal)
        {
            Caption = 'Rounding Precision';
            MinValue = 0.00001;
            InitValue = 0.01;
        }
        field(13; "Analysis No. Series"; Code[20])
        {
            Caption = 'Analysis No. Series';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
