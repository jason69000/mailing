function Get-AuditTrail($r) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $createdBy = if ($r.CreatedBy) { $r.CreatedBy } else { "Billing System" }
    $auditEntries = @(
        "Invoice created on $timestamp",
        "Generated for $($r.Name) via $($r.PaymentMethod) using $($r.Bank)",
        "Invoice ID: $($r.InvoiceNumber)"
    ) -join "<br/>"

    return @{ 
        AuditTrailSummary = "Audit trail generated on $timestamp"
        AuditTrailDetails = $auditEntries
        AuditTrailStyle   = "font-size:0.85rem;color:#555;margin-top:18px;"
    }
}
