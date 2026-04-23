//
//  CalendarEventCard.swift
//  ClubIt
//
//  Created by Ansh Srivastava on 3/24/26.
//

import SwiftUI

struct CalendarEventCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 20) {
            // Date Section
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 24))
                    .bold()
                Text(monthName)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                        
            }
            .foregroundColor(.accent)
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(event.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
        .contentShape(Rectangle())
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: event.startDate)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.startDate).uppercased()
    }
}

#Preview {
    CalendarEventCard(event: MockData.sampleEvents[0])
        .padding()
}
