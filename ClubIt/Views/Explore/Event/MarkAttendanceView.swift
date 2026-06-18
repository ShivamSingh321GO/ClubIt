import SwiftUI

struct MarkAttendanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var appSession
    
    let expectedEventId: UUID
    @State private var isProcessing = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isProcessing {
                    VStack {
                        ProgressView("Marking Attendance...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                    .zIndex(1)
                }
                
                QRScannerView { result in
                    handleScanResult(result)
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    Text("Scan the Event QR Code")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK") {
                    if isSuccess { dismiss() }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleScanResult(_ result: Result<String, Error>) {
        guard !isProcessing else { return }
        
        switch result {
        case .success(let code):
            processQRData(code)
        case .failure(let error):
            alertMessage = "Scanning failed: \(error.localizedDescription)"
            isSuccess = false
            showAlert = true
        }
    }
    
    private func processQRData(_ code: String) {
        guard let data = code.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data),
              let action = dict["action"], action == "attendance",
              let eventIdStr = dict["eventId"],
              let scannedEventId = UUID(uuidString: eventIdStr) else {
            alertMessage = "Invalid QR Code format."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard scannedEventId == expectedEventId else {
            alertMessage = "This QR code is for a different event."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard let userId = appSession.currentUser?.id else {
            alertMessage = "You must be logged in to mark attendance."
            isSuccess = false
            showAlert = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let isEntry = try await appSession.attendanceStore.markAttendance(eventId: expectedEventId, userId: userId)
                
                await MainActor.run {
                    self.alertMessage = isEntry ? "Entry marked successfully!" : "Exit marked successfully!"
                    self.isSuccess = true
                    self.isProcessing = false
                    self.showAlert = true
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to mark attendance: \(error.localizedDescription)"
                    self.isSuccess = false
                    self.isProcessing = false
                    self.showAlert = true
                }
            }
        }
    }
}
