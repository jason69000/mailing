function Get-Holographic($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ HoloGradient = "background:linear-gradient(135deg,#4A6FDC,#8AB4F8,#C3D9FF);"; HoloSheen = "background:linear-gradient(45deg,#ffffff33,#4A6FDC22);"; HoloFoil = "background:linear-gradient(90deg,#4A6FDC33,#8AB4F855,#C3D9FF33);" } }
        "Stripe" { return @{ HoloGradient = "background:linear-gradient(135deg,#635BFF,#8A7BFF,#B5A8FF);"; HoloSheen = "background:linear-gradient(45deg,#ffffff22,#635BFF33);"; HoloFoil = "background:linear-gradient(90deg,#635BFF33,#8A7BFF55,#B5A8FF33);" } }
        "Square" { return @{ HoloGradient = "background:linear-gradient(135deg,#000000,#444444,#888888);"; HoloSheen = "background:linear-gradient(45deg,#ffffff22,#00000033);"; HoloFoil = "background:linear-gradient(90deg,#00000033,#44444455,#88888833);" } }
        "Venmo"  { return @{ HoloGradient = "background:linear-gradient(135deg,#3D95CE,#5BB8FF,#A3D9FF);"; HoloSheen = "background:linear-gradient(45deg,#ffffff33,#5BB8FF22);"; HoloFoil = "background:linear-gradient(90deg,#3D95CE33,#5BB8FF55,#A3D9FF33);" } }
        "CashApp"{ return @{ HoloGradient = "background:linear-gradient(135deg,#00D632,#00FF55,#66FF99);"; HoloSheen = "background:linear-gradient(45deg,#ffffff33,#00FF5522);"; HoloFoil = "background:linear-gradient(90deg,#00D63233,#00FF5555,#66FF9933);" } }
        "Plaid"  { return @{ HoloGradient = "background:linear-gradient(135deg,#121212,#2A2A2A,#444444);"; HoloSheen = "background:linear-gradient(45deg,#ffffff22,#12121233);"; HoloFoil = "background:linear-gradient(90deg,#12121233,#2A2A2A55,#44444433);" } }
        default   { return @{ HoloGradient = "background:linear-gradient(135deg,#333333,#555555,#777777);"; HoloSheen = "background:linear-gradient(45deg,#ffffff22,#33333333);"; HoloFoil = "background:linear-gradient(90deg,#33333333,#55555555,#77777733);" } }
    }
}