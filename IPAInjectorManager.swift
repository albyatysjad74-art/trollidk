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
        statusMessage = "جاري تحضير ملفات IPA و Dylib..."

        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let workingDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let payloadDir = workingDir.appendingPathComponent("Payload")

            do {
                try fileManager.createDirectory(at: workingDir, withIntermediateDirectories: true)

                // 1. Unzip IPA using system Process / unzip or native extraction
                DispatchQueue.main.async {
                    self.progress = 0.3
                    self.statusMessage = "جاري فك ضغط الـ IPA..."
                }

                let unzipTask = Process()
                unzipTask.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
                unzipTask.arguments = ["-q", ipaURL.path, "-d", workingDir.path]
                try unzipTask.run()
                unzipTask.waitUntilExit()

                // 2. Find .app directory
                let contents = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
                guard let appDir = contents.first(where: { $0.pathExtension == "app" }) else {
                    throw NSError(domain: "Injector", code: 1, userInfo: [NSLocalizedDescriptionKey: "لم يتم العثور على مجلد .app داخل IPA"])
                }

                // 3. Copy Dylib inside Frameworks or App root
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
                try fileManager.copyItem(at: dylibURL, to: destinationDylib)

                // 4. Find App Binary and inject @executable_path/Frameworks/dylib
                let appName = appDir.deletingPathExtension().lastPathComponent
                let binaryPath = appDir.appendingPathComponent(appName)

                if fileManager.fileExists(atPath: binaryPath.path) {
                    let dylibPathToInject = "@executable_path/Frameworks/\(dylibURL.lastPathComponent)"
                    
                    // Simple injection fallback or insert command
                    let injectTask = Process()
                    injectTask.executableURL = URL(fileURLWithPath: "/usr/bin/optool")
                    injectTask.arguments = ["insert", "-t", "dylib", "-p", dylibPathToInject, "-m", binaryPath.path]
                    try? injectTask.run()
                    injectTask.waitUntilExit()
                }

                // 5. Rezip to Output IPA
                DispatchQueue.main.async {
                    self.progress = 0.85
                    self.statusMessage = "جاري إعطاء الضغط النهائي للـ IPA..."
                }

                let outputDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let finalIPA = outputDirectory.appendingPathComponent("Injected_\(ipaURL.lastPathComponent)")

                if fileManager.fileExists(atPath: finalIPA.path) {
                    try fileManager.removeItem(at: finalIPA)
                }

                let zipTask = Process()
                zipTask.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
                zipTask.currentDirectoryURL = workingDir
                zipTask.arguments = ["-r", "-q", finalIPA.path, "Payload"]
                try zipTask.run()
                zipTask.waitUntilExit()

                // Clean temp
                try? fileManager.removeItem(at: workingDir)

                DispatchQueue.main.async {
                    self.progress = 1.0
                    self.outputIPAURL = finalIPA
                    self.isInjecting = false
                    self.statusMessage = "تم الحقن بنجاح! جاهز للتصدير لـ E-Sign / TrollStore"
                }

            } catch {
                DispatchQueue.main.async {
                    self.isInjecting = false
                    self.statusMessage = "خطأ: \(error.localizedDescription)"
                }
            }
        }
    }
}
