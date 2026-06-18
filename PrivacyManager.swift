import Foundation
import SwiftUI

/// PrivacyManager is responsible for detecting and redacting Personally Identifiable Information (PII)
/// and managing the blocked domain list to prevent execution on secure websites.
class PrivacyManager {
    static let shared = PrivacyManager()
    
    // Built-in list of common sensitive domains (banking, finance, etc.)
    private let predefinedBlockedDomains: [String] = [
        // US & Global Banks / Financial
        "paypal.com",
        "chase.com",
        "bankofamerica.com",
        "wellsfargo.com",
        "citi.com",
        "citibank.com",
        "capitalone.com",
        "americanexpress.com",
        "discover.com",
        "fidelity.com",
        "schwab.com",
        "vanguard.com",
        "stripe.com",
        "square.com",
        "hsbc.com",
        "barclays.com",
        "santander.com",
        "visa.com",
        "mastercard.com",
        "payoneer.com",
        "wise.com",
        "revolut.com",
        
        // Indian Banks
        "hdfcbank.com",
        "icicibank.com",
        "onlinesbi.sbi",
        "onlinesbi.com",
        "sbi.co.in",
        "axisbank.com",
        "kotak.com",
        "pnbindia.in",
        "bankofbaroda.in",
        "yesbank.in",
        "indusind.com",
        "idfcfirstbank.com",
        "unionbankofindia.co.in",
        "canarabank.com",
        "standardchartered.com",
        "sc.com",
        
        // Indian Wallets & Payment Gateways
        "paytm.com",
        "phonepe.com",
        "freecharge.in",
        "mobikwik.com",
        "razorpay.com",
        "cred.club",
        
        // Indian Government & Tax
        "incometax.gov.in",
        "uidai.gov.in",
        "epfindia.gov.in",
        "gst.gov.in",

        // Common Secure prefixes/keywords
        "secure.",
        "login.",
        "auth."
    ]
    
    // Access user-defined blocked domains from UserDefaults
    private var userBlockedDomains: [String] {
        let saved = UserDefaults.standard.string(forKey: "userBlockedDomains") ?? ""
        return saved.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    }
    
    private init() {}
    
    /// Redacts PII (Emails, Phones, Credit Cards, SSNs) from the input text.
    func redactPII(from text: String) -> String {
        var redactedText = text
        
        // 1. Redact Emails
        // Standard email regex
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        redactedText = replaceMatches(in: redactedText, pattern: emailPattern, replacement: "[REDACTED_EMAIL]")
        
        // 2. Redact Phone Numbers
        // Matches various formats: (123) 456-7890, 123-456-7890, 123.456.7890, +1 123 456 7890, or just straight 7-15 digits
        let phonePattern = "(?:\\+?\\d{1,3}[- .]?)?\\(?\\d{3}\\)?[- .]?\\d{3}[- .]?\\d{4}|\\b\\d{7,15}\\b"
        redactedText = replaceMatches(in: redactedText, pattern: phonePattern, replacement: "[REDACTED_PHONE]")
        
        // 3. Redact Credit Card Numbers
        // Basic match for 13-19 digit sequences, possibly separated by spaces or dashes
        let ccPattern = "(?:\\d[ -]*?){13,19}"
        // To avoid replacing regular numbers like "2023", we ensure it looks like a CC format.
        // A safer approach for a broad regex is to look for specific starting digits (Visa 4, Mastercard 5, Amex 3), 
        // but for general privacy, we'll redact long sequences of numbers.
        redactedText = replaceMatches(in: redactedText, pattern: ccPattern, replacement: "[REDACTED_CARD]")
        
        // 4. Redact SSNs
        // Standard US SSN format: XXX-XX-XXXX
        let ssnPattern = "\\d{3}-\\d{2}-\\d{4}"
        redactedText = replaceMatches(in: redactedText, pattern: ssnPattern, replacement: "[REDACTED_SSN]")
        
        return redactedText
    }
    
    private func replaceMatches(in text: String, pattern: String, replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
    
    /// Checks if the given URL belongs to a blocked secure domain.
    func isBlockedDomain(url: String) -> Bool {
        let lowercasedURL = url.lowercased()
        
        let allBlockedDomains = predefinedBlockedDomains + userBlockedDomains
        
        for domain in allBlockedDomains {
            if !domain.isEmpty && lowercasedURL.contains(domain) {
                return true
            }
        }
        return false
    }
}
