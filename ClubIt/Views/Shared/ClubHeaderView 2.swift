//import SwiftUI
//
//struct ClubHeaderView: View {
//    @Environment(AppSession.self) var appSession
//    let club: Club
//    let event: Event
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            ZStack {
//                Circle()
//                    .fill(Color.orange.opacity(0.1))
//                    .frame(width: 60, height: 60)
//                
//                Text(String(club.name.prefix(1)))
//                    .font(.system(size: 24, weight: .bold))
//                    .foregroundColor(.orange)
//            }
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(event.name)
//                    .font(.title3.bold())
//                    .foregroundColor(.primary)
//                
//                Text(club.name)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 24)
//                .fill(.ultraThinMaterial)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 24)
//                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
//                )
//        )
//        .padding(.horizontal)
//    }
//}
