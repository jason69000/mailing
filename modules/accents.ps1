function Get-Accents($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ AccentLight = "#4A6FDC33"; AccentMedium = "#4A6FDC66"; AccentBorder = "#4A6FDC" } }
        "Stripe" { return @{ AccentLight = "#635BFF22"; AccentMedium = "#635BFF55"; AccentBorder = "#635BFF" } }
        "Square" { return @{ AccentLight = "#00000010"; AccentMedium = "#00000025"; AccentBorder = "#333333" } }
        "Venmo"  { return @{ AccentLight = "#3D95CE22"; AccentMedium = "#3D95CE55"; AccentBorder = "#3D95CE" } }
        "CashApp"{ return @{ AccentLight = "#00D63222"; AccentMedium = "#00D63255"; AccentBorder = "#00D632" } }
        "Plaid"  { return @{ AccentLight = "#12121222"; AccentMedium = "#12121255"; AccentBorder = "#121212" } }
        default   { return @{ AccentLight = "#33333322"; AccentMedium = "#33333355"; AccentBorder = "#333333" } }
    }
}