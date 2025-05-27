//
//  DragHandle.swift
//  Lizection
//
//  Created by Rongwei Ji on 5/27/25.
//

import SwiftUI
// MARK: - Drag Handle Component

struct DragHandle: View {
    let locationsCount: Int
    let isSyncing: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Visual drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Header with title and controls
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Today")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Text("\(locationsCount) upcoming locations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

#Preview("Syncing") {
    DragHandle(locationsCount: 0, isSyncing: true)
}


#Preview("Not Syncing") {
    DragHandle(locationsCount: 10, isSyncing: false)
}


#Preview("Not Syncing Dark") {
    DragHandle(locationsCount: 10, isSyncing: false)
        .preferredColorScheme(.dark)
}
