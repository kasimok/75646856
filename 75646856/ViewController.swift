import UIKit
import PDFKit

class ViewController: UIViewController {
  
  let pdfView = PDFView()
  var page: PDFPage?
  var selection: PDFSelection?
  var selectedText: String?
  
  var editMenuInteraction: UIEditMenuInteraction!
  
  
  var _pdfScrollView: UIView? {
    pdfView.subviews.filter{ (NSStringFromClass(type(of: $0).self) == "PDFScrollView")}.first
  }
  
  var _pdfDocumentView: UIView? {
    _pdfScrollView?.subviews.filter{ (NSStringFromClass(type(of: $0).self) == "PDFDocumentView")}.first
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Add the edit menu interaction.
    editMenuInteraction = UIEditMenuInteraction(delegate: self)
    pdfView.addInteraction(editMenuInteraction!)
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
    tap.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
    tap.numberOfTapsRequired = 1
    pdfView.addGestureRecognizer(tap)
    debugPrint("gesture recognizer: \(ObjectIdentifier(tap)), has been added.")
    
    view.addSubview(pdfView)
    pdfView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
    ])
    
    loadPdf()
  }
  
  @objc private func didTap(_ recognizer: UIGestureRecognizer) {
    let location = recognizer.location(in: pdfView)
    
    page = pdfView.page(for: location, nearest: false)
    guard page != nil else { return }
    
    let convertedLocation = pdfView.convert(location, to: page!)
    if page!.annotation(at: convertedLocation) == nil {
      selection = page!.selectionForWord(at: convertedLocation)
      pdfView.setCurrentSelection(selection, animate: false)
      guard let word = selection?.string else {
        // no selection dismiss the menu
        editMenuInteraction.dismissMenu()
        return
      }
      selectedText = word
      if let interaction = editMenuInteraction {
        let config = UIEditMenuConfiguration(identifier: nil, sourcePoint: location)
        interaction.presentEditMenu(with: config)
      }
    }
  }
  
  
  func loadPdf() {
    if let url = Bundle.main.url(forResource: "75646856", withExtension: "pdf"){
      if let pdfDocument = PDFDocument(url: url) {
        pdfView.document = pdfDocument
        
        recursivelyDisableSelection(view: pdfView)
      }
    }
  }
  
  /// Upon loaded some internal view classes like `PDFDocumentView` are created along with some gestures, now recursively disable them
  /// - Parameter view: view to process.
  func recursivelyDisableSelection(view: UIView) {
    for subview in view.subviews {
      recursivelyDisableSelection(view: subview)
    }
      
    let gestureTypesToDisable: [String] = [
      "UILongPressGestureRecognizer",
      "UITapAndAHalfRecognizer",
      "UITextTapRecognizer"
    ]
      
    view.gestureRecognizers?
      .filter { gesture in gestureTypesToDisable.contains(type(of: gesture).description()) }
      .forEach { $0.isEnabled = false }
  }
}


// MAKR: UIEditMenuInteractionDelegate
extension ViewController:UIEditMenuInteractionDelegate{
  func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
    debugPrint("called: \(#function)")
    var additionalActions: [UIMenuElement] = []
    let heartAction = UIAction(title: "💡") { _ in
      // Get cursor position
      debugPrint("did press heart action")
    }
    additionalActions.append(heartAction)
    
    return UIMenu(children: additionalActions + suggestedActions)
  }
}
