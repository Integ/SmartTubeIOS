import SwiftUI

/// A vertical feed whose TV Back action returns to the beginning of the list.
struct FeedScrollView<Content: View>: View {
    @ViewBuilder var content: () -> Content
    #if os(tvOS)
    @Namespace private var top
    @Namespace private var focusScope
    @Environment(\.resetFocus) private var resetFocus
    #endif

    var body: some View {
        #if os(tvOS)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 0).id(top)
                    content()
                }
            }
            .focusScope(focusScope)
            .onExitCommand {
                // Scroll without animation so focus is resolved in the top viewport.
                // Reset the list's focus as well, otherwise tvOS can scroll back to
                // the previously focused card further down the feed.
                proxy.scrollTo(top, anchor: .top)
                resetFocus(in: focusScope)
            }
        }
        #else
        ScrollView { content() }
        #endif
    }
}
