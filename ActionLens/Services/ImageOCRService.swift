import Foundation
import Vision

protocol OCRServicing {
    func extractText(from imageData: Data) async -> String?
}

struct ImageOCRService: OCRServicing {
    func extractText(from imageData: Data) async -> String? {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: text.isEmpty ? nil : text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(data: imageData, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
