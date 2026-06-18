import SwiftUI

struct AttendanceQRDisplayView: View {
    let event: Event
    @State private var qrImage: UIImage?
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Event Attendance QR")
                .font(.title2.bold())
            
            Text(event.title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                ProgressView()
                    .frame(width: 250, height: 250)
            }
            
            Text("Ask attendees to scan this QR code using the ClubIt app to mark their attendance. The QR code changes every 15 seconds for security.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.top, 40)
        .onAppear {
            generateQR()
        }
        .onReceive(timer) { _ in
            generateQR()
        }
    }
    
    private func generateQR() {
        // Create JSON string
        let dict: [String: String] = [
            "action": "attendance",
            "eventId": event.id.uuidString,
            "timestamp": String(Date().timeIntervalSince1970)
        ]
        
        if let data = try? JSONEncoder().encode(dict),
           let string = String(data: data, encoding: .utf8) {
            let generator = QRCodeGenerator()
            self.qrImage = generator.generateQRCode(from: string)
        }
    }
}
