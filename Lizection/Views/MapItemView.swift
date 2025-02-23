//
//  MapItemView.swift
//  Lizection
//
//  Created by Rongwei Ji on 2/18/25.
//
// This is the row item view in the mainlist

import SwiftUI

struct MapItemView: View {
    private static let exampleBackgroundImageName: String = "example"
    
    
    let showMap:Bool = false // load the image or the map, depend it have cache in local, default is the false shows the image
    
    var body: some View {
        ZStack {
            if showMap{
//                Mapview as background

            }else{
                // Image  as background
                Image(Self.exampleBackgroundImageName) // Replace with your image name
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
            }
            
            

            // Content overlay
            VStack(alignment: .leading) {
                Text("Location Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Description or address")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.5), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .frame(height: 120)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

#Preview {
    MapItemView()
}
