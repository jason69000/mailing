function Get-QR($r, $serialCode, $blockchainHash) {
    $verificationBaseUrl = "https://verify.yourfintech.com/invoice"
    $verificationQuery   = "inv=$([System.Uri]::EscapeDataString($r.InvoiceNumber))&em=$([System.Uri]::EscapeDataString($r.Email))&bn=$([System.Uri]::EscapeDataString($r.Bank))&ft=$([System.Uri]::EscapeDataString($r.Fintech))&pm=$([System.Uri]::EscapeDataString($r.PaymentMethod))&sc=$([System.Uri]::EscapeDataString($serialCode))&bh=$([System.Uri]::EscapeDataString($blockchainHash))"
    $verificationUrl     = "$verificationBaseUrl?$verificationQuery"
    switch ($r.Fintech) {
        "PayPal" { return @{ QrVerificationUrl = $verificationUrl; QrLabel = "PayPal Verification"; QrStyle = "border:2px solid #4A6FDC; padding:8px; border-radius:10px;" } }
        "Stripe" { return @{ QrVerificationUrl = $verificationUrl; QrLabel = "Stripe Verification"; QrStyle = "border:2px solid #635BFF; padding:8px; border-radius:10px;" } }
        "Square" { return @{ QrVerificationUrl = $verificationUrl; QrLabel = "Square Verification"; QrStyle = "border:2px solid #000000; padding:8px; border-radius:8px;" } }
        "Venmo"  { return @{ QrVerificationUrl = $verificationUrl; QrLabel = "Venmo Verification"; QrStyle = "border:2px solid #3D95CE; padding:8px; border-radius:12px;" } }
        "CashApp"{ return @{ QrVerificationUrl = $verificationUrl; QrLabel = "Cash App Verification"; QrStyle = "border:2px solid #00D632; padding:8px; border-radius:12px;" } }
        "Plaid"  { return @{ QrVerificationUrl = $verificationUrl; QrLabel = "Plaid Verification"; QrStyle = "border:2px solid #121212; padding:8px; border-radius:8px;" } }
        default   { return @{ QrVerificationUrl = $verificationUrl; QrLabel = "Invoice Verification"; QrStyle = "border:2px solid #333333; padding:8px; border-radius:10px;" } }
    }
}