import Foundation

class AudioFetchService {
    static let shared = AudioFetchService()

    private let baseURL = "https://gurmatveechar.com"

    private init() {}

    func fetchFolderContents(path: String) async throws -> [AudioItem] {
        let urlString = "\(baseURL)/audio.php?q=f&f=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)"

        guard let url = URL(string: urlString) else {
            throw AudioFetchError.invalidURL
        }

        print("📂 Fetching folder: \(urlString)")

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw AudioFetchError.invalidResponse
        }

        let items = parseHTMLForItems(html: html, currentPath: path)
        print("✅ Found \(items.count) items in \(path)")

        return items
    }

    private func parseHTMLForItems(html: String, currentPath: String) -> [AudioItem] {
        var items: [AudioItem] = []

        // Match folder links (no quotes around href values, name inside <font> tag)
        // More specific: must have style="color:0069c6" to avoid matching other links
        let folderPattern = #"<a href=audio\.php\?q=f&f=([^>]+) style="color:0069c6"><font[^>]*>([^<]+)</font></a>"#
        // Match audio files - link contains image, not text, so just capture the URL
        // The file name will be extracted from the URL
        let audioPattern = #"<a href=\"(/audios/[^\"]+\.mp3)\">"#

        if let folderRegex = try? NSRegularExpression(pattern: folderPattern, options: []) {
            let matches = folderRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("📊 Found \(matches.count) folder matches")

            for match in matches {
                if let pathRange = Range(match.range(at: 1), in: html),
                   let nameRange = Range(match.range(at: 2), in: html) {
                    let encodedPath = String(html[pathRange])
                    var name = String(html[nameRange])
                        .replacingOccurrences(of: "_", with: " ")
                        .replacingOccurrences(of: "&nbsp;", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    let lowercaseName = name.lowercased()

                    // Skip metadata entries that show folder/file counts
                    // Patterns: "8folders,7 files", "11 folders", "125 files", "1file", etc.
                    if lowercaseName.range(of: "\\d+\\s*folder", options: .regularExpression) != nil ||
                       lowercaseName.range(of: "\\d+\\s*file", options: .regularExpression) != nil {
                        print("  ⏭️  Skipping metadata: '\(name)'")
                        continue
                    }

                    let decodedPath = encodedPath.removingPercentEncoding ?? encodedPath

                    print("  📁 Folder: '\(name)' -> \(decodedPath)")

                    items.append(AudioItem(
                        name: name,
                        type: .folder,
                        url: decodedPath,
                        children: nil
                    ))
                }
            }
        }

        if let audioRegex = try? NSRegularExpression(pattern: audioPattern, options: []) {
            let matches = audioRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            print("📊 Found \(matches.count) audio matches")

            // Debug: If no audio matches, show sample of HTML containing .mp3
            if matches.count == 0 && html.contains(".mp3") {
                if let range = html.range(of: ".mp3") {
                    let start = html.index(range.lowerBound, offsetBy: -200, limitedBy: html.startIndex) ?? html.startIndex
                    let end = html.index(range.upperBound, offsetBy: 400, limitedBy: html.endIndex) ?? html.endIndex
                    print("🔍 DEBUG: HTML contains .mp3 but no matches. Sample:")
                    print("\(html[start..<end])")
                    print("🔍 Audio pattern being used: \(audioPattern)")
                }
            }

            for match in matches {
                if let urlRange = Range(match.range(at: 1), in: html) {
                    let audioPath = String(html[urlRange])
                    let fullURL = "\(baseURL)\(audioPath)"

                    // Extract filename from URL path
                    let urlComponents = audioPath.components(separatedBy: "/")
                    let filename = urlComponents.last ?? ""

                    // Clean up the filename for display
                    var name = filename
                        .replacingOccurrences(of: ".mp3", with: "")
                        .replacingOccurrences(of: "%28", with: "(")
                        .replacingOccurrences(of: "%29", with: ")")
                        .replacingOccurrences(of: "%20", with: " ")
                        .removingPercentEncoding ?? filename

                    // Replace dots and dashes with spaces for readability
                    name = name
                        .replacingOccurrences(of: ".", with: " ")
                        .replacingOccurrences(of: "--", with: " - ")
                        .trimmingCharacters(in: .whitespaces)

                    print("  🎵 Audio: '\(name)' -> \(fullURL)")

                    items.append(AudioItem(
                        name: name,
                        type: .audio,
                        url: fullURL,
                        children: nil
                    ))
                }
            }
        }

        print("✅ Total items parsed: \(items.count) (returning to UI)")
        return items
    }
}

enum AudioFetchError: Error {
    case invalidURL
    case invalidResponse
    case parsingError
}
