function Get-RevocationChain($r) {
    $viewerBaseUrl = "https://chainviewer.yourfintech.com/verify"
    $viewerQuery   = "invoice=$([System.Uri]::EscapeDataString($r.InvoiceNumber))&bank=$([System.Uri]::EscapeDataString($r.Bank))&fintech=$([System.Uri]::EscapeDataString($r.Fintech))"
    $viewerUrl     = "$viewerBaseUrl?$viewerQuery"
    return @{ 
        ChainViewerLink  = $viewerUrl
        ChainViewerLabel = "View ledger proof"
        ChainViewerStyle = "color:#1f4e79;text-decoration:none;font-weight:600;"
    }
}
