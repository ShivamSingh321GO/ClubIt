import SwiftUI
import ClubItShared

struct StudentHomeView: View {
    @Environment(AppSession.self) private var appSession
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Events Registered
                        if !isSearchActive {
                            eventsRegisteredSection
                        }
                        
                        // Subgroups Section
                        subgroupsSection
                    }
                    .padding(.vertical, 20)
                }
                .refreshable {
                    await appSession.refreshData()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle(isSearchActive ? "" : "Home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isSearchActive = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Notifications action
                    } label: {
                        Image(systemName: "bell")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StudentProfileView()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .navigationDestination(for: Subgroup.self) { subgroup in
                SubgroupDetailView(subgroup: subgroup)
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event, isMyEvent: false)
            }
            
            NavigationLink(destination: ClubItCalendarView(standalone: true)) {
                Image(systemName: "calendar")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .glassEffect(in: .circle)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding()
            } // Close ZStack
        }
        .fullScreenCover(isPresented: $isSearchActive) {
            SubgroupSearchView()
        }
        .task {
            await appSession.refreshData()
        }
    }
    
    private var eventsRegisteredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Events registered")
                    .font(.title2)
                    .bold()
                
                Spacer()
            }
            .padding(.horizontal)
            
            if appSession.studentDashboardStore.registeredEvents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No events registered yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .glassEffect(in: .rect(cornerRadius: 20))
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(appSession.studentDashboardStore.registeredEvents) { event in
                            NavigationLink(value: event) {
                                EventCardView(event: event)
                            }
                            .buttonStyle(.plain)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.98)
                                    .opacity(phase.isIdentity ? 1 : 0.9)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
    
    private var subgroupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subgroups")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            // Category Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    categoryChip("All", isSelected: appSession.studentDashboardStore.selectedCategory == nil) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appSession.studentDashboardStore.selectCategory(nil)
                        }
                    }
                    
                    ForEach(SubgroupCategory.allCases, id: \.self) { category in
                        categoryChip(category.rawValue.capitalized, isSelected: appSession.studentDashboardStore.selectedCategory == category) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                appSession.studentDashboardStore.selectCategory(category)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .scrollTransition(.animated) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0.8)
                }
            }
            
            // Subgroup List
            LazyVStack(spacing: 16) {
                ForEach(appSession.studentDashboardStore.filteredSubgroups) { subgroup in
                    NavigationLink(value: subgroup) {
                        SubgroupCard(subgroup: subgroup)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
//                .frame(minWidth: 65)
                .background(isSelected ? .accentColor.opacity(1.0) : Color(.tertiarySystemFill).opacity(0.5), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}




#Preview {
    StudentHomeView()
        .environment(AppSession())
}
