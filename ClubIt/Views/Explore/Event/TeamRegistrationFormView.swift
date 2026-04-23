import SwiftUI

struct TeamRegistrationFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.blue)
            
            Text("Team Registration Form")
                .font(.title2)
                .bold()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Team Registration")
        .navigationBarTitleDisplayMode(.inline)
    }
}
