//
//  SubscriptionPlan.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/17/26.
//

import Foundation

enum BillingCycle: String, Codable {
    case halfYearly
    case yearly
}

struct SubscriptionPlan: Identifiable, Codable {
    var id = UUID()
    var planName: String
    var billingCycle: BillingCycle
    var maxClubs: Int
    var maxUsers: Int
    var features: [String]
    var price: Double
    var createdAt: Date
    
}

enum SubscriptionStatus: String, Codable {
    case active
    case expired
    case cancelled
}

enum PaymentStatus: String, Codable {
    case paid
    case pending
    case failed
}

struct Subscription: Identifiable, Codable {
    var id = UUID()
    var instituteId: UUID
    var subscriptionPlanId: UUID
    var startDate: Date
    var endDate: Date
    var status: SubscriptionStatus
    var paymentStatus: PaymentStatus
    var createdAt: Date
}
