function Get-Revocation($r) {
    if ($r.Revoked -and $r.Revoked.ToString().ToLower() -eq "true") {
        return @{
            RevocationStatus = "REVOKED"
            RevocationNotice = "This invoice has been revoked. Reason: $($r.RevocationReason)"
            RevocationStyle  = "color:#b22222;font-weight:bold;"
            RevocationLabel  = "Revoked by $($r.RevokedBy)"
        }
    }

    return @{
        RevocationStatus = "ACTIVE"
        RevocationNotice = "This invoice is valid and in good standing."
        RevocationStyle  = "color:#2d6a4f;font-weight:600;"
        RevocationLabel  = "Valid Invoice"
    }
}
