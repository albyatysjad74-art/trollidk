import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var injector = IPAInjectorManager()
    @State private var showDylibPicker = false
    @State private var showIPAPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    // Header Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Addons Injector")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text(injector.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Main Action Buttons (Like TrollFools Layout)
                    HStack(spacing: 20) {
                        
                        // Select Dylib Button
                        Button(action: { showDylibPicker = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "syringe.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                Text(injector.selectedDylibURL == nil ? "Select Dylib" : "Dylib Loaded")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color(red: 0.05, green: 0.15, blue: 0.05))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Select IPA Button
                        Button(action: { showIPAPicker = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                Text(injector.selectedIPAURL == nil ? "Select IPA" : "IPA Loaded")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color(red: 0.05, green: 0.1, blue: 0.2))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Inject & Export Button
                    if injector.isInjecting {
                        ProgressView("Injecting Dylib into IPA...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    } else {
                        Button(action: { injector.startInjectionProcess() }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Inject & Generate IPA")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(injector.readyToInject ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(!injector.readyToInject)
                        .padding(.horizontal)
                    }
                    
                    if let outputURL = injector.outputIPAURL {
                        ShareLink(item: outputURL) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Injected IPA to E-Sign")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDylibPicker) {
                DocumentPicker(allowedTypes: [UTType(filenameExtension: "dylib")!]) { url in
                    injector.selectedDylibURL = url
                }
            }
            .sheet(isPresented: $showIPAPicker) {
                DocumentPicker(allowedTypes: [UTType(filenameExtension: "ipa")!]) { url in
                    injector.selectedIPAURL = url
                }
            }
        }
    }
}
