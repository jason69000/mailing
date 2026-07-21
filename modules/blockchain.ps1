function Get-Blockchain($r) {
    $rand = (Get-Random -Maximum 99999999).ToString("X8")
    $guid = ([System.Guid]::NewGuid().ToString().Replace("-", "").Substring(0,16).ToUpper())
    switch ($r.Fintech) {
        "PayPal" { return @{ BlockchainHashPrefix = "PP-BLOCK"; BlockchainHashValue = "PP-BLOCK-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#4A6FDC;" } }
        "Stripe" { return @{ BlockchainHashPrefix = "ST-CHAIN"; BlockchainHashValue = "ST-CHAIN-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#635BFF;" } }
        "Square" { return @{ BlockchainHashPrefix = "SQ-LEDGER"; BlockchainHashValue = "SQ-LEDGER-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#000000;" } }
        "Venmo"  { return @{ BlockchainHashPrefix = "VM-BLOCK"; BlockchainHashValue = "VM-BLOCK-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#3D95CE;" } }
        "CashApp"{ return @{ BlockchainHashPrefix = "CA-CHAIN"; BlockchainHashValue = "CA-CHAIN-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#00D632;" } }
        "Plaid"  { return @{ BlockchainHashPrefix = "PL-ENCRYPT"; BlockchainHashValue = "PL-ENCRYPT-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#121212;" } }
        default   { return @{ BlockchainHashPrefix = "GEN-HASH"; BlockchainHashValue = "GEN-HASH-$($r.InvoiceNumber)-$rand-$guid"; BlockchainHashStyle = "color:#333333;" } }
    }
}