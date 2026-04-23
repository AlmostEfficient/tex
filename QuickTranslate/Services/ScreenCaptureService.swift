import Foundation

struct ScreenCaptureService {
    func captureSelection() async throws -> URL? {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quick-translate-\(UUID().uuidString)")
            .appendingPathExtension("png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", destinationURL.path]

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    continuation.resume(returning: destinationURL)
                } else {
                    continuation.resume(returning: nil)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
