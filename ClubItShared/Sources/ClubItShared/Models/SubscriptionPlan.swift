//
//  SubscriptionPlan.swift
//  ClubIt
//
//  Created by shivam kumar singh on 3/17/26.
//

import Foundation

public enum BillingCycle: String, Codable {
    case halfYearly
    case yearly
}

public struct SubscriptionPlan: Identifiable, Codable {
    public var id = UUID()
    public var planName: String
    public var billingCycle: BillingCycle
    public var maxClubs: Int
    public var maxUsers: Int
    public var features: [String]
    public var price: Double
    public var createdAt: Date
    

    public init(
        id: UUID = UUID(),
        planName: String,
        billingCycle: BillingCycle,
        maxClubs: Int,
        maxUsers: Int,
        features: [String],
        price: Double,
        createdAt: Date
    ) {
        self.id = id
        self.planName = planName
        self.billingCycle = billingCycle
        self.maxClubs = maxClubs
        self.maxUsers = maxUsers
        self.features = features
        self.price = price
        self.createdAt = createdAt
    }

}

public enum SubscriptionStatus: String, Codable {
    case active
    case expired
    case cancelled
}

public enum PaymentStatus: String, Codable {
    case paid
    case pending
    case failed
}

public struct Subscription: Identifiable, Codable {
    public var id = UUID()
    public var instituteId: UUID
    public var subscriptionPlanId: UUID
    public var startDate: Date
    public var endDate: Date
    public var status: SubscriptionStatus
    public var paymentStatus: PaymentStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        instituteId: UUID,
        subscriptionPlanId: UUID,
        startDate: Date,
        endDate: Date,
        status: SubscriptionStatus,
        paymentStatus: PaymentStatus,
        createdAt: Date
    ) {
        self.id = id
        self.instituteId = instituteId
        self.subscriptionPlanId = subscriptionPlanId
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.paymentStatus = paymentStatus
        self.createdAt = createdAt
    }

}
