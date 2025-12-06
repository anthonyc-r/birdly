//
//  BirdImageView.swift
//  birdly
//
//  Created by tony on 27/11/2025.
//

import SwiftUI

struct BirdImageView: View {
    let imageSource: ImageSource
    var contentMode: ContentMode = .fit
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    var body: some View {
        Group {
            switch imageSource {
            case .asset(let name):
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .url(let urlString):
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BirdImageView(imageSource: .asset(name: "bird"))
            .frame(width: 200, height: 200)
        
        BirdImageView(imageSource: .url("https://example.com/bird.jpg"))
            .frame(width: 200, height: 200)
    }
    .padding()
}



