////
////  leadonboarding.swift
////  ConnexusRe
////
////  Created by Ansh Srivastava on 3/20/26.
////
//
//import SwiftUI
//
//struct LeadOnboardingView: View {
//    
//    @AppStorage("hasSeenClubLeadOnboarding") private var hasSeenClubLeadOnboarding = false
//    @State private var currentPage = 0
//    
//    private let pages: [OnboardingPage] = [
//        OnboardingPage(
//            title: "Communicate seamlessly",
//            subtitle: "Keep conversations event-specific and organized in one space."
//        ),
//        OnboardingPage(
//            title: "Create club events",
//            subtitle: "Create events, submit them for approval, and track their status."
//        ),
//        OnboardingPage(
//            title: "Manage members",
//            subtitle: "Keep your club members organized from day one."
//        )
//    ]
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                
//                topBar
//                
//                TabView(selection: $currentPage) {
//                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
//                        onboardingPageView(page: page, isLastPage: index == pages.count - 1)
//                            .tag(index)
//                    }
//                }
//                .tabViewStyle(.page(indexDisplayMode: .never))
//                
//                pageIndicator
//                    .padding(.bottom, 28)
//            }
//            .background(Color(.systemBackground))
//            .toolbar(.hidden, for: .navigationBar)
//        }
//    }
//    
//    private var topBar: some View {
//        HStack {
//            Spacer()
//            
//            Button {
//                finishOnboarding()
//            } label: {
//                Text("Skip")
//                    .font(.subheadline)
//                    .fontWeight(.semibold)
//                    .foregroundStyle(.accentColor)
//                    .padding(.horizontal, 14)
//                    .padding(.vertical, 8)
//                    .background(
//                        Capsule()
//                            .fill(Color(.secondarySystemBackground))
//                    )
//            }
//        }
//        .padding(.horizontal, 18)
//        .padding(.top, 16)
//    }
//    
//    private func onboardingPageView(_ page: OnboardingPage, isLastPage: Bool) -> some View {
//        VStack(spacing: 0) {
//            
//            Spacer()
//                .frame(height: 70)
//            
//            Spacer()
//                .frame(height: 260)
//            
//            Text(page.title)
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundStyle(.primary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 24)
//            
//            Spacer()
//                .frame(height: 18)
//            
//            Text(page.subtitle)
//                .font(.body)
//                .foregroundStyle(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 28)
//            
//            Spacer()
//            
//            if isLastPage {
//                Button {
//                    finishOnboarding()
//                } label: {
//                    Text("Get Started")
//                        .font(.headline)
//                        .bold()
//                        .foregroundStyle(.white)
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 58)
//                        .background(.accentColor)
//                        .clipShape(RoundedRectangle(cornerRadius: 16))
//                }
//                .buttonStyle(.plain)
//                .padding(.horizontal, 18)
//                .padding(.bottom, 30)
//            } else {
//                Spacer()
//                    .frame(height: 88)
//            }
//        }
//    }
//    
//    private var pageIndicator: some View {
//        HStack(spacing: 8) {
//            ForEach(0..<pages.count, id: \.self) { index in
//                Circle()
//                    .fill(index == currentPage ? Color.accentColor : Color(.systemGray4))
//                    .frame(width: 8, height: 8)
//            }
//        }
//    }
//    
//    private func finishOnboarding() {
//        hasSeenClubLeadOnboarding = true
//    }
//}
//
//private struct OnboardingPage {
//    let title: String
//    let subtitle: String
//}
//
//#Preview {
//    LeadOnboardingView()
//}
