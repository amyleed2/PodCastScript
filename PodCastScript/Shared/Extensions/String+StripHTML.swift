import Foundation

extension String {
    /// Returns a plain-text version of the string with HTML tags removed
    /// and whitespace normalized.
    ///
    /// Replaces each tag with a space before stripping so that adjacent
    /// tags (e.g. `</p><p>`) don't merge words together.
    var strippedHTML: String {
        let withSpaces = replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return withSpaces
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
