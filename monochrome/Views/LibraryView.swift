import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.down.right.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Theme.mutedForeground)
                    
                    Text("Bibliothèque")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.foreground)
                    
                    Text("En cours de développement...")
                        .foregroundColor(Theme.mutedForeground)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LibraryView()
}
