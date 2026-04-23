import SwiftUI

struct ApprovalStatusTrack: View {
    let approval: Approval
    
    var body: some View {
        let steps = [
            ("Lead", true), // Always initiated by Lead
            ("VP", approval.status == .approved || approval.type == .budget), // Simplified logic for demo
            ("President", approval.status == .approved && approval.type == .budget)
        ]
        
        VStack(spacing: 8) {
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    StatusLabel(text: steps[index].0, color: steps[index].1 ? .green : .secondary)
                    if index < steps.count - 1 { Spacer() }
                }
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 2)
                
                HStack {
                    ForEach(steps.indices, id: \.self) { index in
                        StatusDot(color: steps[index].1 ? .green : Color.secondary.opacity(0.1))
                        if index < steps.count - 1 { Spacer() }
                    }
                }
                
                // Progress line
                HStack {
                    Rectangle()
                        .fill(.green)
                        .frame(width: progressWidth(for: steps), height: 2)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    StatusLabel(
                        text: steps[index].1 ? "Approved" : "Pending",
                        color: steps[index].1 ? .green : .secondary
                    )
                    if index < steps.count - 1 { Spacer() }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private func progressWidth(for steps: [(String, Bool)]) -> CGFloat {
        let approvedCount = steps.filter { $0.1 }.count
        if approvedCount <= 1 { return 10 }
        if approvedCount == 2 { return 150 } // Approx mid point
        return 300 // Approx end point
    }
}

struct StatusLabel: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(color)
            .frame(width: 60)
            .multilineTextAlignment(.center)
    }
}

struct StatusDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}

#Preview {
    ZStack {
        VStack {
            ApprovalStatusTrack(approval: MockData.sampleApprovals[0])
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding()
        }
    }
}
