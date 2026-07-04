import SwiftUI
import ClubItShared

struct SubgroupSearchView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    @State private var isAnimating = false
    @State private var showCloseButton = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    if appSession.studentDashboardStore.searchText.isEmpty && appSession.studentDashboardStore.filteredSubgroups.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary.opacity(0.3))
                                .padding(.top, 80)
                            
                            Text("No Suggestions")
                                .font(.title3.bold())
                            
                            Text("Suggestions will be available after you\ncomplete searches.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else if appSession.studentDashboardStore.filteredSubgroups.isEmpty {
                        // No Results State
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.2))
                                .padding(.top, 100)
                            
                            Text("No results found for \"\(appSession.studentDashboardStore.searchText)\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        // Results List
                        LazyVStack(spacing: 12) {
                            ForEach(appSession.studentDashboardStore.filteredSubgroups) { subgroup in
                                NavigationLink(value: subgroup) {
                                    SubgroupCard(subgroup: subgroup)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 100)
                        } // Correctly aligned bottom space
                    }
                }
                
                // Floating Bottom Search Bar & Close Button
                HStack(spacing: 12) {
                    // Search Capsule
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search subgroups...", text: Bindable(appSession.studentDashboardStore).searchText)
                            .focused($isSearchFocused)
                            .textFieldStyle(.plain)
                        
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    
                    // Separate Close Button
                    if showCloseButton {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.scale(scale: 0.1, anchor: .leading).combined(with: .offset(x: -30)).combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("All Subgroups")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Subgroup.self) { subgroup in
                SubgroupDetailView(subgroup: subgroup)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showCloseButton = true
                }
            }
            
            isSearchFocused = true
        }
        .onDisappear {
            appSession.studentDashboardStore.searchText = ""
        }
    }
}

#Preview {
    SubgroupSearchView()
        .environment(AppSession())
}
