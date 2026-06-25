import SwiftUI
import ClubItShared

struct AttachmentMenu: View {
    let onSelect: (AttachmentType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    enum AttachmentType {
        case camera, photo, document, location, contact
        
        var title: String {
            switch self {
            case .camera: return "Camera"
            case .photo: return "Photo & Video Library"
            case .document: return "Document"
            case .location: return "Location"
            case .contact: return "Contact"
            }
        }
        
        var icon: String {
            switch self {
            case .camera: return "camera.fill"
            case .photo: return "photo.on.rectangle.angled"
            case .document: return "doc.fill"
            case .location: return "mappin.and.ellipse"
            case .contact: return "person.crop.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .camera: return .blue
            case .photo: return .purple
            case .document: return .accentColor
            case .location: return .green
            case .contact: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 0) {
                attachmentButton(type: .camera)
                Divider().padding(.leading, 56)
                attachmentButton(type: .photo)
                Divider().padding(.leading, 56)
                attachmentButton(type: .document)
                Divider().padding(.leading, 56)
                attachmentButton(type: .location)
                Divider().padding(.leading, 56)
                attachmentButton(type: .contact)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.hidden)
    }
    
    private func attachmentButton(type: AttachmentType) -> some View {
        Button {
            onSelect(type)
            dismiss()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                        .font(.system(size: 18))
                }
                
                Text(type.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            AttachmentMenu { _ in }
        }
}
