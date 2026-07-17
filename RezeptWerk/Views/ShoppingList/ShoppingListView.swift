import SwiftUI
import SwiftData

/// Die Einkaufsliste: offene Einträge oben, abgehakte unten. Zutaten lassen
/// sich aus dem Wochenplan übernehmen oder von Hand hinzufügen.
///
/// Wie `WeekPlannerView` bringt diese View **keinen** eigenen
/// `NavigationStack` mit — sie lebt im Stack des Dashboards (iPhone) bzw.
/// des iPad-Tabs (`RootView`).
struct ShoppingListView: View {

    @Query(sort: \ShoppingItem.sortIndex)
    private var items: [ShoppingItem]

    @Environment(\.modelContext) private var modelContext

    @State private var newItemText = ""
    @State private var confirmationMessage: String?
    @State private var showClearAllConfirmation = false
    @State private var saveFailed = false

    private var openItems: [ShoppingItem] {
        items.filter { !$0.isChecked }
    }

    private var checkedItems: [ShoppingItem] {
        items.filter(\.isChecked)
    }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(AppColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Einkaufsliste")
        .navigationBarTitleDisplayMode(.inline)
        .saveErrorAlert($saveFailed)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            addRow
        }
        .alert(
            "Erledigt",
            isPresented: Binding(
                get: { confirmationMessage != nil },
                set: { if !$0 { confirmationMessage = nil } }
            )
        ) {
            Button("Prima", role: .cancel) {}
        } message: {
            Text(confirmationMessage ?? "")
        }
        .confirmationDialog(
            "Ganze Liste löschen?",
            isPresented: $showClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Alles löschen", role: .destructive) {
                ShoppingListService.clearAll(in: modelContext)
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    // MARK: Liste

    private var list: some View {
        List {
            if !openItems.isEmpty {
                Section("Noch zu kaufen (\(openItems.count))") {
                    ForEach(openItems) { item in
                        row(item)
                    }
                    .onDelete { offsets in delete(openItems, at: offsets) }
                }
                .listRowBackground(AppColors.backgroundElevated)
            }

            if !checkedItems.isEmpty {
                Section("Erledigt (\(checkedItems.count))") {
                    ForEach(checkedItems) { item in
                        row(item)
                    }
                    .onDelete { offsets in delete(checkedItems, at: offsets) }
                }
                .listRowBackground(AppColors.backgroundElevated)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func row(_ item: ShoppingItem) -> some View {
        Button {
            item.isChecked.toggle()
            try? modelContext.save()
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isChecked ? AppColors.copper : AppColors.textSecondary)

                Text(item.displayText)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .strikethrough(item.isChecked)
                    .opacity(item.isChecked ? 0.55 : 1)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Eingabezeile

    private var addRow: some View {
        HStack(spacing: AppSpacing.s) {
            TextField("Eintrag hinzufügen, z. B. „2 Zwiebeln“", text: $newItemText)
                .textFieldStyle(.plain)
                .padding(AppSpacing.m)
                .sunken()
                .onSubmit(addManualItem)

            Button(action: addManualItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppColors.copper)
            }
            .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.s)
        .background(.bar)
    }

    // MARK: Leerzustand

    private var emptyState: some View {
        EmptyStateView(
            icon: "cart",
            title: "Einkaufsliste ist leer",
            message: "Übernimm die Zutaten deines Wochenplans oder füge unten eigene Einträge hinzu.",
            actionTitle: "Aus Wochenplan übernehmen",
            action: addFromWeek
        )
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    addFromWeek()
                } label: {
                    Label("Aus Wochenplan (diese Woche)", systemImage: "calendar")
                }

                if !checkedItems.isEmpty {
                    Button {
                        ShoppingListService.clearChecked(in: modelContext)
                    } label: {
                        Label("Erledigte löschen", systemImage: "checkmark.circle")
                    }
                }

                if !items.isEmpty {
                    Button(role: .destructive) {
                        showClearAllConfirmation = true
                    } label: {
                        Label("Alles löschen", systemImage: "trash")
                    }
                }
            } label: {
                Label("Mehr", systemImage: "ellipsis.circle")
            }
        }
    }

    // MARK: Aktionen

    private func addManualItem() {
        let text = newItemText
        newItemText = ""
        ShoppingListService.addManual(text: text, to: modelContext)
    }

    private func addFromWeek() {
        let count = ShoppingListService.addCurrentWeek(to: modelContext)
        confirmationMessage = count == 0
            ? "In dieser Woche sind keine Gerichte mit Zutaten geplant."
            : "\(count) Zutaten aus dem Wochenplan übernommen."
    }

    private func delete(_ source: [ShoppingItem], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(source[index])
        }
        do {
            try modelContext.save()
        } catch {
            // Nicht gespeichert: Löschen zurücknehmen und Bescheid geben.
            modelContext.rollback()
            saveFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
    .modelContainer(PreviewSupport.container)
}
