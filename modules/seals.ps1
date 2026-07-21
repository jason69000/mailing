function Get-Seal($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ SecuritySealImage = "paypal_seal.png"; SecuritySealLabel = "PayPal Verified"; SecuritySealStyle = "opacity:0.95;" } }
        "Stripe" { return @{ SecuritySealImage = "stripe_seal.png"; SecuritySealLabel = "Stripe PCI Secure"; SecuritySealStyle = "opacity:0.95;" } }
        "Square" { return @{ SecuritySealImage = "square_seal.png"; SecuritySealLabel = "Square Trusted POS"; SecuritySealStyle = "opacity:0.95;" } }
        "Venmo"  { return @{ SecuritySealImage = "venmo_seal.png"; SecuritySealLabel = "Venmo Verified"; SecuritySealStyle = "opacity:0.95;" } }
        "CashApp"{ return @{ SecuritySealImage = "cashapp_seal.png"; SecuritySealLabel = "Cash App Secure"; SecuritySealStyle = "opacity:0.95;" } }
        "Plaid"  { return @{ SecuritySealImage = "plaid_seal.png"; SecuritySealLabel = "Plaid Encrypted"; SecuritySealStyle = "opacity:0.95;" } }
        default   { return @{ SecuritySealImage = "default_seal.png"; SecuritySealLabel = "Secure Payment"; SecuritySealStyle = "opacity:0.95;" } }
    }
}