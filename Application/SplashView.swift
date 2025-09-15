import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                Image("home")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Power")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .padding()
                    }
                    .padding(.top, 175)
                    Spacer()
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    Text("© Developed by Diego Anguita. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 0, y: 0)
                        .padding()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    SplashView()
}
