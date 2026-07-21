function Get-Depth($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ DepthLayer1 = "box-shadow:0 4px 12px rgba(74,111,220,0.25);"; DepthLayer2 = "box-shadow:0 2px 8px rgba(74,111,220,0.20);"; DepthLayer3 = "box-shadow:0 1px 4px rgba(74,111,220,0.15);" } }
        "Stripe" { return @{ DepthLayer1 = "box-shadow:0 6px 18px rgba(99,91,255,0.30);"; DepthLayer2 = "box-shadow:0 4px 12px rgba(99,91,255,0.25);"; DepthLayer3 = "box-shadow:0 2px 6px rgba(99,91,255,0.20);" } }
        "Square" { return @{ DepthLayer1 = "box-shadow:0 4px 14px rgba(0,0,0,0.25);"; DepthLayer2 = "box-shadow:0 3px 10px rgba(0,0,0,0.20);"; DepthLayer3 = "box-shadow:0 2px 6px rgba(0,0,0,0.15);" } }
        "Venmo"  { return @{ DepthLayer1 = "box-shadow:0 5px 16px rgba(91,184,255,0.30);"; DepthLayer2 = "box-shadow:0 3px 10px rgba(91,184,255,0.25);"; DepthLayer3 = "box-shadow:0 2px 6px rgba(91,184,255,0.20);" } }
        "CashApp"{ return @{ DepthLayer1 = "box-shadow:0 6px 20px rgba(0,255,85,0.40);"; DepthLayer2 = "box-shadow:0 4px 14px rgba(0,255,85,0.30);"; DepthLayer3 = "box-shadow:0 2px 8px rgba(0,255,85,0.25);" } }
        "Plaid"  { return @{ DepthLayer1 = "box-shadow:0 6px 18px rgba(0,0,0,0.35);"; DepthLayer2 = "box-shadow:0 4px 12px rgba(0,0,0,0.30);"; DepthLayer3 = "box-shadow:0 2px 6px rgba(0,0,0,0.25);" } }
        default   { return @{ DepthLayer1 = "box-shadow:0 4px 12px rgba(0,0,0,0.20);"; DepthLayer2 = "box-shadow:0 2px 8px rgba(0,0,0,0.15);"; DepthLayer3 = "box-shadow:0 1px 4px rgba(0,0,0,0.10);" } }
    }
}