function Get-Watermark($r) {
    switch ($r.Fintech) {
        "PayPal" { return @{ WatermarkImage = "paypal_watermark.png"; WatermarkStyle = "opacity:0.08; background-size:60%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#4A6FDC11,#8AB4F811)" } }
        "Stripe" { return @{ WatermarkImage = "stripe_watermark.png"; WatermarkStyle = "opacity:0.07; background-size:65%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#635BFF11,#8A7BFF11)" } }
        "Square" { return @{ WatermarkImage = "square_watermark.png"; WatermarkStyle = "opacity:0.06; background-size:55%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#00000011,#44444411)" } }
        "Venmo"  { return @{ WatermarkImage = "venmo_watermark.png"; WatermarkStyle = "opacity:0.08; background-size:70%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#3D95CE11,#5BB8FF11)" } }
        "CashApp"{ return @{ WatermarkImage = "cashapp_watermark.png"; WatermarkStyle = "opacity:0.10; background-size:65%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#00D63211,#00FF5511)" } }
        "Plaid"  { return @{ WatermarkImage = "plaid_watermark.png"; WatermarkStyle = "opacity:0.07; background-size:60%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#12121211,#2A2A2A11)" } }
        default   { return @{ WatermarkImage = "default_watermark.png"; WatermarkStyle = "opacity:0.06; background-size:60%; background-position:center; background-repeat:no-repeat;"; WatermarkOverlay = "linear-gradient(135deg,#33333311,#55555511)" } }
    }
}