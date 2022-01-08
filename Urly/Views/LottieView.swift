//
//  LottieView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/7/22.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var animationName = ""
    var loopMode = LottieLoopMode.playOnce
    var animationSpeed = 1.0

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)

        if animationName.isEmpty {
            fatalError("animationName can not be empty")
        }

        let animatedView = AnimationView()
        let animation = Animation.named(animationName)
        animatedView.animation = animation
        animatedView.contentMode = .scaleAspectFit
        animatedView.animationSpeed = animationSpeed
        animatedView.loopMode = loopMode
        animatedView.play()

        animatedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animatedView)
        NSLayoutConstraint.activate([
            animatedView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animatedView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct LottieView_Previews: PreviewProvider {
    static var previews: some View {
        LottieView(animationName: "empty-box", loopMode: .loop, animationSpeed: 1.0)
    }
}
