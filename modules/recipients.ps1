function Get-RecipientBaseTokens($r) {
    $revoked = $false
    if ($r.Revoked -and $r.Revoked.ToString().ToLower() -eq "true") {
        $revoked = $true
    }

    return @{        
        Name               = $r.Name
        Email              = $r.Email
        Product            = $r.Product
        Total              = $r.Total
        InvoiceNumber      = $r.InvoiceNumber
        Bank               = $r.Bank
        Fintech            = $r.Fintech
        PaymentMethod      = $r.PaymentMethod
        Revoked            = $revoked
        RevocationReason   = if ($r.RevocationReason) { $r.RevocationReason } else { "" }
        RevokedBy          = if ($r.RevokedBy) { $r.RevokedBy } else { "" }
        ReplacementInvoice = if ($r.ReplacementInvoice) { $r.ReplacementInvoice } else { "" }
        ParentInvoice      = if ($r.ParentInvoice) { $r.ParentInvoice } else { "" }
    }
}