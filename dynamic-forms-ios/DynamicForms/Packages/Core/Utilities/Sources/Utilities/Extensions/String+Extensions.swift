import Foundation

/// String extensions providing common utility functions
/// Following clean code principles with focused responsibilities
public extension String {
    
    // MARK: - Validation Helpers
    
    /// Check if string is empty or contains only whitespace
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Check if string is not empty and contains non-whitespace characters
    var isNotBlank: Bool {
        return !isBlank
    }
    
    /// Safely trim whitespace and newlines
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Email Validation
    
    /// Validate email format using regex
    var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    // MARK: - Number Validation
    
    /// Check if string represents a valid integer
    var isValidInteger: Bool {
        return Int(self) != nil
    }
    
    /// Check if string represents a valid double
    var isValidDouble: Bool {
        return Double(self) != nil
    }
    
    /// Check if string contains only numeric characters
    var isNumeric: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    // MARK: - Safe Conversions
    
    /// Safely convert to Int with default value
    func toInt(defaultValue: Int = 0) -> Int {
        return Int(self) ?? defaultValue
    }
    
    /// Safely convert to Double with default value
    func toDouble(defaultValue: Double = 0.0) -> Double {
        return Double(self) ?? defaultValue
    }
    
    // MARK: - Formatting
    
    /// Capitalize first letter only
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst().lowercased()
    }
    
    /// Convert to title case (first letter of each word capitalized)
    var titleCased: String {
        return self.split(separator: " ")
            .map { String($0).capitalizedFirst }
            .joined(separator: " ")
    }
    
    // MARK: - UUID Generation
    
    /// Generate a UUID string
    static func generateUUID() -> String {
        return UUID().uuidString
    }
    
    /// Generate a short UUID (first 8 characters)
    static func generateShortUUID() -> String {
        return String(UUID().uuidString.prefix(8))
    }
    
    // MARK: - HTML Handling
    
    /// Remove HTML tags from string (for description fields)
    var strippingHTMLTags: String {
        return self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression,
            range: nil
        )
    }
    
    /// Check if string contains HTML tags
    var containsHTML: Bool {
        let htmlRegex = "<[^>]+>"
        return self.range(of: htmlRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Date Formatting
    
    /// Convert to Date using common formats
    var toDate: Date? {
        let formatters = [
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "dd/MM/yyyy"),
            createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: self) {
                return date
            }
        }
        
        // Try ISO8601
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: self)
    }
    
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    // MARK: - Substring Safety
    
    /// Safely get substring with bounds checking
    func substring(from index: Int, length: Int? = nil) -> String {
        guard index >= 0 && index < count else { return "" }
        
        let startIndex = self.index(self.startIndex, offsetBy: index)
        
        if let length = length {
            let endOffset = min(index + length, count)
            let endIndex = self.index(self.startIndex, offsetBy: endOffset)
            return String(self[startIndex..<endIndex])
        } else {
            return String(self[startIndex...])
        }
    }
    
    /// Safely truncate string to maximum length
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        let truncated = substring(from: 0, length: length - trailing.count)
        return truncated + trailing
    }
}

// MARK: - Localization Extensions
public extension String {
    
    /// Localized string lookup with fallback to key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}