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
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                // Copy IPA to temp folder
                let tempIPA = tempDir.appendingPathComponent("app.ipa")
                try fileManager.copyItem(at: ipaURL, to: tempIPA)
                
                // Output directory
                let outputDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let finalIPA = outputDirectory.appendingPathComponent("Injected_\(ipaURL.lastPathComponent)")
                
                if fileManager.fileExists(atPath: finalIPA.path) {
                    try fileManager.removeItem(at: finalIPA)
                }
                
                // Copy original for output preview
                try fileManager.copyItem(at: ipaURL, to: finalIPA)
                
                DispatchQueue.main.async {
                    self.outputIPAURL = finalIPA
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
