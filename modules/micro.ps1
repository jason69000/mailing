function Get-Micro($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ MicroHover = "box-shadow:0 0 12px rgba(74,111,220,0.35);"; MicroPress = "transform:scale(0.98);"; MicroRipple = "background:radial-gradient(circle,#4A6FDC33,transparent);" } }
        "Stripe" { return @{ MicroHover = "background:linear-gradient(120deg,#635BFF55,transparent);"; MicroPress = "border-left:4px solid #635BFF;"; MicroRipple = "background:linear-gradient(90deg,#635BFF22,transparent);" } }
        "Square" { return @{ MicroHover = "box-shadow:0 0 10px rgba(0,0,0,0.25);"; MicroPress = "transform:scale(0.97);"; MicroRipple = "background:rgba(0,0,0,0.08);" } }
        "Venmo"  { return @{ MicroHover = "box-shadow:0 0 14px rgba(91,184,255,0.35);"; MicroPress = "transform:scale(0.96);"; MicroRipple = "background:radial-gradient(circle,#5bb8ff33,transparent);" } }
        "CashApp"{ return @{ MicroHover = "box-shadow:0 0 18px rgba(0,255,85,0.45);"; MicroPress = "transform:scale(0.95);"; MicroRipple = "background:radial-gradient(circle,#00ff5533,transparent);" } }
        "Plaid"  { return @{ MicroHover = "box-shadow:0 0 16px rgba(0,0,0,0.35);"; MicroPress = "transform:scale(0.97);"; MicroRipple = "background:linear-gradient(135deg,#12121233,transparent);" } }
        default   { return @{ MicroHover = "box-shadow:0 0 10px rgba(0,0,0,0.2);"; MicroPress = "transform:scale(0.97);"; MicroRipple = "background:rgba(0,0,0,0.1);" } }
    }
}