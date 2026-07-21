function Get-PaymentMethod($r) {
    switch ($r.PaymentMethod) {
        "ACH" {
            return @{
                PaymentMethodName       = "ACH Bank Transfer"
                PaymentMethodIcon       = "ach_icon.png"
                PaymentMethodMessage    = "This payment was completed using a secure ACH bank transfer."
                PaymentMethodDetails    = "ACH payments may take 1-3 business days to settle."
                PaymentMethodCompliance = "Processed under NACHA ACH network rules."
            }
        }
        "Card" {
            return @{
                PaymentMethodName       = "Credit/Debit Card"
                PaymentMethodIcon       = "card_icon.png"
                PaymentMethodMessage    = "This payment was completed using a secure card transaction."
                PaymentMethodDetails    = "Card payments are processed instantly."
                PaymentMethodCompliance = "Processed under PCI DSS standards."
            }
        }
        "Wallet" {
            return @{
                PaymentMethodName       = "Digital Wallet"
                PaymentMethodIcon       = "wallet_icon.png"
                PaymentMethodMessage    = "This payment was completed using a secure digital wallet."
                PaymentMethodDetails    = "Wallet payments support encrypted tokenized transactions."
                PaymentMethodCompliance = "Processed under digital wallet regulations."
            }
        }
        "Fintech" {
            return @{
                PaymentMethodName       = "Fintech Gateway"
                PaymentMethodIcon       = "fintech_icon.png"
                PaymentMethodMessage    = "This payment was completed using a fintech gateway."
                PaymentMethodDetails    = "Fintech gateways provide encrypted API-driven processing."
                PaymentMethodCompliance = "Processed under fintech regulatory frameworks."
            }
        }
        default {
            return @{
                PaymentMethodName       = "Unknown Payment Method"
                PaymentMethodIcon       = "default_method.png"
                PaymentMethodMessage    = "Payment method could not be determined."
                PaymentMethodDetails    = "Check your provider for details."
                PaymentMethodCompliance = "Processed under standard U.S. financial regulations."
            }
        }
    }
}