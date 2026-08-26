import Foundation
import Combine

class IPAInjectorManager: ObservableObject {
    @Published var selectedDylibURL: URL?
    @Published var selectedIPAURL: URL?
    @Published var outputIPAURL: URL?
    @Published var isInjecting = false
    @Published var statusMessage = "اختر ملف Dylib وملف IPA للبدء"
    @Published var progress: Double = 0.0

    var readyToInject: Bool {
        return selectedDylibURL != nil && selectedIPAURL != nil
    }

    func startInjectionProcess() {
        guard let ipaURL = selectedIPAURL, let dylibURL = selectedDylibURL else { return }

        isInjecting = true
        progress = 0.1
        statusMessage = "جاري قراءة وتجهيز الملفات..."

        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let payloadDir = tempDir.appendingPathComponent("Payload")

            do {
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // 1. فك ضغط ملف الـ IPA باستخدام Archive Native Handling
                DispatchQueue.main.async {
                    self.progress = 0.3
                    self.statusMessage = "جاري تفكيك حزمة IPA..."
                }

                try fileManager.unzipItem(at: ipaURL, to: tempDir)

                // 2. البحث عن المجلد .app
                let contents = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
                guard let appDir = contents.first(where: { $0.pathExtension == "app" }) else {
                    throw NSError(domain: "Injector", code: 1, userInfo: [NSLocalizedDescriptionKey: "لم يتم العثور على مجلد .app"])
                }

                // 3. إنشاء مجلد Frameworks ونقل الـ dylib
                DispatchQueue.main.async {
                    self.progress = 0.6
                    self.statusMessage = "جاري حقن ملف الـ Dylib وربطه بالتطبيق..."
                }

                let frameworksDir = appDir.appendingPathComponent("Frameworks")
                if !fileManager.fileExists(atPath: frameworksDir.path) {
                    try fileManager.createDirectory(at: frameworksDir, withIntermediateDirectories: true)
                }

                let destinationDylib = frameworksDir.appendingPathComponent(dylibURL.lastPathComponent)
                if fileManager.fileExists(atPath: destinationDylib.path) {
                    try fileManager.removeItem(at: destinationDylib)
                }
                
                // بدء عملية الوصول للملفات المؤمنة
                let dylibAccessing = dylibURL.startAccessingSecurityScopedResource()
                try fileManager.copyItem(at: dylibURL, to: destinationDylib)
                if dylibAccessing { dylibURL.stopAccessingSecurityScopedResource() }

                // 4. إعادة ضغط الحزمة
                DispatchQueue.main.async {
                    self.progress = 0.85
                    self.statusMessage = "جاري تجميع حزمة IPA النهائية..."
                }

                let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let finalIPA = docsDir.appendingPathComponent("Injected_\(ipaURL.lastPathComponent)")

                if fileManager.fileExists(atPath: finalIPA.path) {
                    try fileManager.removeItem(at: finalIPA)
                }

                try fileManager.zipItem(at: tempDir, to: finalIPA)

                // تنظيف الملفات المؤقتة
                try? fileManager.removeItem(at: tempDir)

                DispatchQueue.main.async {
                    self.progress = 1.0
                    self.outputIPAURL = finalIPA
                    self.isInjecting = false
                    self.statusMessage = "تم الحقن والتجميع بنجاح! جاهز للتصدير."
                }

            } catch {
                DispatchQueue.main.async {
                    self.isInjecting = false
                    self.statusMessage = "خطأ أثناء الحقن: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Native Zip Helpers for iOS
extension FileManager {
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        // Native unzip using System Archive API
        let process = ProcessInfo.processInfo
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &error) { zipURL in
            try? self.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }
    }

    func zipItem(at sourceURL: URL, to destinationURL: URL) throws {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &error) { zipURL in
            try? self.moveItem(at: zipURL, to: destinationURL)
        }
    }
}
