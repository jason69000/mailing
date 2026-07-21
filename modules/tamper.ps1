function Get-Tamper($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ TamperPatternImage = "paypal_tamper.png"; TamperPatternStyle = "opacity:0.12; background-size:180px; background-repeat:repeat;"; TamperPatternLabel = "PayPal Anti-Tamper Microprint" } }
        "Stripe" { return @{ TamperPatternImage = "stripe_tamper.png"; TamperPatternStyle = "opacity:0.10; background-size:160px; background-repeat:repeat;"; TamperPatternLabel = "Stripe Micro-Line Security Pattern" } }
        "Square" { return @{ TamperPatternImage = "square_tamper.png"; TamperPatternStyle = "opacity:0.14; background-size:140px; background-repeat:repeat;"; TamperPatternLabel = "Square Cross-Hatch Anti-Tamper Grid" } }
        "Venmo"  { return @{ TamperPatternImage = "venmo_tamper.png"; TamperPatternStyle = "opacity:0.12; background-size:200px; background-repeat:repeat;"; TamperPatternLabel = "Venmo Micro-Dot Tamper Shield" } }
        "CashApp"{ return @{ TamperPatternImage = "cashapp_tamper.png"; TamperPatternStyle = "opacity:0.10; background-size:170px; background-repeat:repeat;"; TamperPatternLabel = "Cash App Wave-Grid Anti-Tamper Layer" } }
        "Plaid"  { return @{ TamperPatternImage = "plaid_tamper.png"; TamperPatternStyle = "opacity:0.15; background-size:150px; background-repeat:repeat;"; TamperPatternLabel = "Plaid Encrypted Grid Tamper Pattern" } }
        default   { return @{ TamperPatternImage = "default_tamper.png"; TamperPatternStyle = "opacity:0.10; background-size:160px; background-repeat:repeat;"; TamperPatternLabel = "Standard Anti‑Tamper Microprint" } }
    }
}