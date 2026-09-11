#if os(iOS)
import MediaPlayer
import SwiftUI

// MARK: - SystemVolumeControl (#19)
//
// iOS provides no public API to set the device's system volume directly — the
// only sanctioned mechanism is embedding an MPVolumeView and driving its
// internal UISlider. This wraps that in a SwiftUI-friendly, effectively
// invisible view: `alpha` near-zero (not `isHidden`, which would break the
// slider) and non-interactive, so it never affects layout or touches.
struct SystemVolumeControl: UIViewRepresentable {
    /// Set to a new value to request a one-shot volume change; the view clears
    /// it back to nil after applying so re-renders don't keep re-driving the
    /// slider to a stale value.
    @Binding var pendingVolume: Float?

    final class Coordinator {
        weak var slider: UISlider?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsRouteButton = false
        view.alpha = 0.001
        view.isUserInteractionEnabled = false
        context.coordinator.slider = view.subviews.compactMap { $0 as? UISlider }.first
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // The slider subview isn't guaranteed to exist at makeUIView time on every
        // iOS version — MPVolumeView builds it lazily once it's in a window.
        if context.coordinator.slider == nil {
            context.coordinator.slider = uiView.subviews.compactMap { $0 as? UISlider }.first
        }
        guard let pendingVolume, let slider = context.coordinator.slider else { return }
        slider.setValue(pendingVolume, animated: false)
        DispatchQueue.main.async { self.pendingVolume = nil }
    }
}
#endif
