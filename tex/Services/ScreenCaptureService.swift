import Foundation

struct ScreenCaptureService {
    struct CapturedImage {
        let data: Data
        let mimeType: String
    }

    func captureSelection() async throws -> CapturedImage? {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quick-translate-\(UUID().uuidString)")
            .appendingPathExtension("png")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", destinationURL.path]

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }

                defer {
                    try? FileManager.default.removeItem(at: destinationURL)
                }

                do {
                    let data = try Data(contentsOf: destinationURL)
                    continuation.resume(
                        returning: CapturedImage(
                            data: data,
                            mimeType: "image/png"
                        )
                    )
                } catch {
                    continuation.resume(throwing: error)
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
