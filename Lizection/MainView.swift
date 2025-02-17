// this is the main list view for shows all the image type item in list
//
//  MainView.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/16/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        HStack {
                            Text(item.timestamp, format: .dateTime)
                                .font(.headline)
                            Spacer()
                            Text("→")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        VStack {
            Text("Item Details")
                .font(.title)
                .padding()
            
            Text("Created at:")
                .font(.headline)
            
            Text(item.timestamp, format: .dateTime)
                .font(.body)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainView()
        .modelContainer(for: Item.self, inMemory: true)
}
