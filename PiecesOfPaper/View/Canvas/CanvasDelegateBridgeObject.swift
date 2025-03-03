//
//  CanvasDelegateBridgeObject.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit
import LinkPresentation

protocol CanvasDelegateBridgeObjectDelegate: AnyObject {
    var hideExceptPaper: Bool { get set }
    var canvasView: PKCanvasView { get }
    func save(drawing: PKDrawing)
}

// MARK: - PKToolPickerObserver
///  This class conform some protocol, because SwiftUI Views cannot conform PencilKit delegates
final class CanvasDelegateBridgeObject: NSObject, PKToolPickerObserver {
    let toolPicker = PKToolPicker()
    private let defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool!
    private var currentTool: PKTool!
    weak var delegate: CanvasDelegateBridgeObjectDelegate?

    override init() {
        super.init()

        toolPicker.addObserver(self)
        toolPicker.selectedTool = defaultTool
        previousTool = defaultTool
        currentTool = defaultTool
        toolPicker.showsDrawingPolicyControls = false
    }

    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        previousTool = currentTool
        currentTool = toolPicker.selectedTool
    }
}

// MARK: - UIPencilInteractionDelegate
extension CanvasDelegateBridgeObject: UIPencilInteractionDelegate {
    /// Double tap action on Appel Pencil when PKToolPicker is invisible(When it's visible, iOS handles its action)
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard !toolPicker.isVisible else { return }
        let action = UIPencilInteraction.preferredTapAction
        switch action {
        case .switchPrevious:   switchPreviousTool()
        case .switchEraser:     switchEraser()
        case .showColorPalette: delegate?.hideExceptPaper.toggle()
        case .ignore:           return
        default:                return
        }
    }

    private func switchPreviousTool() {
        toolPicker.selectedTool = previousTool
    }

    private func switchEraser() {
        if currentTool is PKEraserTool {
            toolPicker.selectedTool = previousTool
        } else {
            toolPicker.selectedTool = PKEraserTool(.vector)
        }
    }
}

// MARK: - PKCanvasViewDelegate
extension CanvasDelegateBridgeObject: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeIfNeeded(canvasView)

        guard UserPreference().enabledAutoSave else { return }
        delegate?.save(drawing: canvasView.drawing)
    }

    private func updateContentSizeIfNeeded(_ canvasView: PKCanvasView) {
        guard !canvasView.drawing.bounds.isNull,
              UserPreference().enabledInfiniteScroll else { return }
        let drawingWidth = canvasView.drawing.bounds.maxX
        if canvasView.contentSize.width * 9 / 10 < drawingWidth {
            canvasView.contentSize.width += canvasView.frame.width
        }

        let drawingHeight = canvasView.drawing.bounds.maxY
        if canvasView.contentSize.height * 9 / 10 < drawingHeight {
            canvasView.contentSize.height += canvasView.frame.height
        }

    }
}

// MARK: - UIActivityItemSource
extension CanvasDelegateBridgeObject: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        nil
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Share your note"
        return metadata
    }
}

// MARK: - UIScrollViewDelegate
extension CanvasDelegateBridgeObject: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        delegate?.canvasView
    }
}
