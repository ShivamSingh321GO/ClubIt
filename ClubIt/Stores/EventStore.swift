//
//  EventStore.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/20/26.
//


import Foundation
import Observation

@Observable
final class EventStore {
    
    var events: [Event] = MockData.sampleEvents
    
    init() {}
    
    func addEvent(_ event: Event) {
        events.insert(event, at: 0)
    }
}
