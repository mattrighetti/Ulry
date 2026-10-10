import SwiftUI

// Hosted by the Ulry app; share extensions cannot host Xcode previews.
#if DEBUG
#Preview("Light") {
    ShareCardView(preview: true).preferredColorScheme(.light)
}

#Preview("Dark") {
    ShareCardView(preview: true).preferredColorScheme(.dark)
}
#endif
