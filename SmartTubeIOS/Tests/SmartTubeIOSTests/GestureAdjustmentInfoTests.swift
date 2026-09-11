import Testing

@testable import SmartTubeIOS

// MARK: - GestureAdjustmentInfoTests (#19)
//
// Unit coverage for the pure drag-to-value math behind the brightness/volume
// gesture — the part that's actually feasible to test without a live device,
// a real gesture recognizer, or UIScreen/AVAudioSession side effects.

@Suite("Gesture-driven brightness/volume adjustment math (#19)")
struct GestureAdjustmentInfoTests {

    @Test("dragging up (negative translationY) increases the value")
    func draggingUpIncreasesValue() {
        let result = GestureAdjustmentInfo.adjustedValue(start: 0.5, translationY: -100, viewHeight: 400)
        #expect(result == 0.75)
    }

    @Test("dragging down (positive translationY) decreases the value")
    func draggingDownDecreasesValue() {
        let result = GestureAdjustmentInfo.adjustedValue(start: 0.5, translationY: 100, viewHeight: 400)
        #expect(result == 0.25)
    }

    @Test("value clamps at 1.0 (dragging up further than a full swing)")
    func clampsAtMaximum() {
        let result = GestureAdjustmentInfo.adjustedValue(start: 0.9, translationY: -1000, viewHeight: 400)
        #expect(result == 1.0)
    }

    @Test("value clamps at 0.0 (dragging down further than a full swing)")
    func clampsAtMinimum() {
        let result = GestureAdjustmentInfo.adjustedValue(start: 0.1, translationY: 1000, viewHeight: 400)
        #expect(result == 0.0)
    }

    @Test("zero translation leaves the value unchanged")
    func zeroTranslationIsNoOp() {
        let result = GestureAdjustmentInfo.adjustedValue(start: 0.42, translationY: 0, viewHeight: 400)
        #expect(result == 0.42)
    }

    @Test("a zero view height doesn't divide-by-zero — returns start unchanged")
    func zeroHeightGuardsAgainstDivideByZero() {
        let result = GestureAdjustmentInfo.adjustedValue(start: 0.3, translationY: -50, viewHeight: 0)
        #expect(result == 0.3)
    }
}
