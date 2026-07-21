function Get-Serial($r) {
    $guid = ([System.Guid]::NewGuid().ToString().Replace("-", "").Substring(0,10).ToUpper())
    switch ($r.Fintech) {
        "PayPal" { return @{ SerialPrefix = "PP-SEC"; SerialCode = "PP-SEC-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#4A6FDC;" } }
        "Stripe" { return @{ SerialPrefix = "ST-PROTECT"; SerialCode = "ST-PROTECT-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#635BFF;" } }
        "Square" { return @{ SerialPrefix = "SQ-VERIFY"; SerialCode = "SQ-VERIFY-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#000000;" } }
        "Venmo"  { return @{ SerialPrefix = "VM-AUTH"; SerialCode = "VM-AUTH-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#3D95CE;" } }
        "CashApp"{ return @{ SerialPrefix = "CA-SHIELD"; SerialCode = "CA-SHIELD-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#00D632;" } }
        "Plaid"  { return @{ SerialPrefix = "PL-ENCRYPT"; SerialCode = "PL-ENCRYPT-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#121212;" } }
        default   { return @{ SerialPrefix = "GEN-AUTH"; SerialCode = "GEN-AUTH-$($r.InvoiceNumber)-$guid"; SerialStyle = "color:#333333;" } }
    }
}