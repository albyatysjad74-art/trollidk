import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var injector = IPAInjectorManager()
    @State private var showDylibPicker = false
    @State private var showIPAPicker = false
    @State private var selectedTab = 0
    
    // عداد الوقت المتبقي للجلسة (24 ساعة)
    @State private var timeRemaining = 86400
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $selectedTab) {
            injectorView
                .tabItem {
                    Label("الحاقن", systemImage: "syringe")
                }
                .tag(0)

            tutorialsView
                .tabItem {
                    Label("الشروحات", systemImage: "book.fill")
                }
                .tag(1)
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
    }

    // MARK: - Injector Interface
    @ViewBuilder
    var injectorView: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                Text("Addons Injector Pro")
                    .font(.largeTitle.bold())
                
                Text(injector.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Timer Banner (الوقت المتبقي)
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("الوقت المتبقي للجلسة: \(timeString(timeRemaining))")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12)
                .onReceive(timer) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    }
                }
            }
            .padding(.top)

            Spacer()

            // File Pickers Grid
            HStack(spacing: 16) {
                // Dylib Button
                Button(action: { showDylibPicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: injector.selectedDylibURL == nil ? "syringe" : "checkmark.seal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(injector.selectedDylibURL == nil ? .green : .white)
                        
                        Text(injector.selectedDylibURL == nil ? "اختيار Dylib" : injector.selectedDylibURL!.lastPathComponent)
                            .font(.caption.bold())
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(injector.selectedDylibURL == nil ? Color.green.opacity(0.15) : Color.green)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green, lineWidth: 2)
                    )
                }

                // IPA Button
                Button(action: { showIPAPicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: injector.selectedIPAURL == nil ? "doc.badge.gearshape" : "checkmark.seal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(injector.selectedIPAURL == nil ? .blue : .white)
                        
                        Text(injector.selectedIPAURL == nil ? "اختيار IPA" : injector.selectedIPAURL!.lastPathComponent)
                            .font(.caption.bold())
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(injector.selectedIPAURL == nil ? Color.blue.opacity(0.15) : Color.blue)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal)

            if injector.isInjecting {
                ProgressView(value: injector.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button(action: { injector.startInjectionProcess() }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("بدء الحقن وتوليد IPA")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(injector.readyToInject && !injector.isInjecting ? Color.blue : Color.gray)
                    .cornerRadius(14)
                }
                .disabled(!injector.readyToInject || injector.isInjecting)

                if let outputURL = injector.outputIPAURL {
                    ShareLink(item: outputURL) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("تصدير الـ IPA المحقون إلى E-Sign / TrollStore")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $showDylibPicker) {
            DocumentPicker(allowedTypes: [.item]) { url in
                injector.selectedDylibURL = url
            }
        }
        .sheet(isPresented: $showIPAPicker) {
            DocumentPicker(allowedTypes: [.item]) { url in
                injector.selectedIPAURL = url
            }
        }
    }

    // MARK: - Tutorials View (قسم الشروحات)
    @ViewBuilder
    var tutorialsView: some View {
        NavigationView {
            List {
                Section(header: Text("خطوات الحقن الصحيحة")) {
                    TutorialRow(step: "1", title: "اختر ملف الأدوات (.dylib)", detail: "قم باختيار ملف الديلب المصمم لتطبيقك.")
                    TutorialRow(step: "2", title: "اختر ملف التطبيق (.ipa)", detail: "حدد التطبيق المراد دمجه وتعديله.")
                    TutorialRow(step: "3", title: "اضغط بدء الحقن", detail: "انتظر حتى يكتمل شريط التقدم 100%.")
                    TutorialRow(step: "4", title: "التوقيع والتثبيت", detail: "صدر الملف لـ E-Sign أو TrollStore وقم بالتثبيت المباشر.")
                }

                Section(header: Text("حلول المشاكل الشائعة")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("التطبيق يقفل بعد التثبيت؟")
                            .font(.headline)
                        Text("تأكد من تفعيل خيار Force Signature / Ad-Hoc أثناء التوقيع في تطبيق E-Sign أو K-Sign.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("شروحات وتعليمات")
        }
    }

    func timeString(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

struct TutorialRow: View {
    let step: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Text(step)
                .font(.title3.bold())
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
