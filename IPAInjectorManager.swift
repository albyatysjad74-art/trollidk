import Foundation
import Combine

class IPAInjectorManager: ObservableObject {
    @Published var selectedDylibURL: URL?
    @Published var selectedIPAURL: URL?
    @Published var outputIPAURL: URL?
    @Published var isInjecting = false
    @Published var statusMessage = "Choose Dylib and IPA files to begin"
    
    var readyToInject: Bool {
        return selectedDylibURL != nil && selectedIPAURL != nil
    }
    
    func startInjectionProcess() {
        guard let ipaURL = selectedIPAURL, let dylibURL = selectedDylibURL else { return }
        
        isInjecting = true
        statusMessage = "Processing binary injection..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                // 1. Create Work Environment
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                // 2. Unzip IPA to Temporary Directory
                let payloadDir = tempDir.appendingPathComponent("Payload")
                try fileManager.unzipItem(at: ipaURL, to: tempDir) // Requires Zip/Archive framework in Xcode
                
                // 3. Locate .app directory
                let items = try fileManager.contentsOfDirectory(atPath: tempDir.appendingPathComponent("Payload").path)
                guard let appFolder = items.first(where: { $0.hasSuffix(".app") }) else {
                    throw NSError(domain: "Injector", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid IPA Structure"])
                }
                
                let appPath = payloadDir.appendingPathComponent(appFolder)
                let frameworksPath = appPath.appendingPathComponent("Frameworks")
                
                // 4. Create Frameworks Folder if not exists
                if !fileManager.fileExists(atPath: frameworksPath.path) {
                    try fileManager.createDirectory(at: frameworksPath, withIntermediateDirectories: true)
                }
                
                // 5. Copy Dylib into Frameworks
                let destinationDylib = frameworksPath.appendingPathComponent(dylibURL.lastPathComponent)
                if fileManager.fileExists(atPath: destinationDylib.path) {
                    try fileManager.removeItem(at: destinationDylib)
                }
                try fileManager.copyItem(at: dylibURL, to: destinationDylib)
                
                // 6. Repackage Payload into New IPA
                let outputIPA = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("Injected_\(ipaURL.lastPathComponent)")
                
                if fileManager.fileExists(atPath: outputIPA.path) {
                    try fileManager.removeItem(at: outputIPA)
                }
                
                try fileManager.zipItem(at: payloadDir, to: outputIPA)
                
                DispatchQueue.main.async {
                    self.outputIPAURL = outputIPA
                    self.isInjecting = false
                    self.statusMessage = "Injection Complete! Ready for E-Sign / K-Sign"
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isInjecting = false
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
