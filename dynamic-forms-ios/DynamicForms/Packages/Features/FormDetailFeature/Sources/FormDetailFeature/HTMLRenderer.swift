import Foundation
import SwiftUI
import WebKit
import UIKit
import Utilities

/// HTML rendering component for description fields with performance optimization
/// Following Single Responsibility Principle with clean separation of concerns
@MainActor
public struct HTMLRenderer: View {
    
    // MARK: - Properties
    private let htmlContent: String
    private let baseFont: UIFont
    private let baseColor: UIColor
    private let contentHash: String
    
    // MARK: - State
    @State private var renderedHeight: CGFloat = 0
    @State private var isLoading: Bool = true
    
    // MARK: - Cache Manager
    @StateObject private var cacheManager = HTMLCacheManager.shared
    
    // MARK: - Initialization
    public init(
        htmlContent: String,
        baseFont: UIFont = UIFont.systemFont(ofSize: 16),
        baseColor: UIColor = UIColor.label
    ) {
        self.htmlContent = htmlContent
        self.baseFont = baseFont
        self.baseColor = baseColor
        self.contentHash = htmlContent.sha256Hash
    }
    
    // MARK: - Body
    public var body: some View {
        Group {
            if htmlContent.containsHTML {
                htmlWebView
            } else {
                plainTextView
            }
        }
        .onAppear {
            loadCachedHeight()
        }
    }
    
    // MARK: - HTML Web View (High Performance)
    private var htmlWebView: some View {
        HTMLWebView(
            htmlContent: processedHTMLContent,
            contentHash: contentHash,
            height: $renderedHeight,
            isLoading: $isLoading,
            onHeightCalculated: saveHeightToCache
        )
        .frame(height: renderedHeight > 0 ? renderedHeight : nil)
        .opacity(isLoading ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
    
    // MARK: - Plain Text View (Fallback)
    private var plainTextView: some View {
        Text(htmlContent)
            .font(Font(baseFont))
            .foregroundColor(Color(baseColor))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Processed HTML Content
    private var processedHTMLContent: String {
        // Check cache first
        if let cachedContent = cacheManager.getCachedHTMLContent(for: contentHash) {
            return cachedContent
        }
        
        let processedContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: \(baseFont.pointSize)px;
                    line-height: 1.4;
                    color: \(baseColor.hexString);
                    padding: 8px;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                    -webkit-text-size-adjust: none;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin: 8px 0 4px 0;
                    font-weight: 600;
                }
                h1 { font-size: 1.5em; }
                h2 { font-size: 1.3em; }
                h3 { font-size: 1.1em; }
                p {
                    margin: 4px 0;
                }
                ul, ol {
                    margin: 4px 0;
                    padding-left: 20px;
                }
                li {
                    margin: 2px 0;
                }
                strong, b {
                    font-weight: 600;
                }
                em, i {
                    font-style: italic;
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                code {
                    background-color: #f5f5f5;
                    padding: 2px 4px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Monaco, monospace;
                    font-size: 0.9em;
                }
                pre {
                    background-color: #f5f5f5;
                    padding: 8px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 8px 0;
                }
                blockquote {
                    border-left: 4px solid #ddd;
                    padding-left: 12px;
                    margin: 8px 0;
                    font-style: italic;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    display: block;
                    margin: 4px auto;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 8px 0;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 8px;
                    text-align: left;
                }
                th {
                    background-color: #f5f5f5;
                    font-weight: 600;
                }
            </style>
            <script>
                function updateHeight() {
                    const height = document.body.scrollHeight;
                    window.webkit.messageHandlers.heightUpdate.postMessage(height);
                }
                
                document.addEventListener('DOMContentLoaded', function() {
                    updateHeight();
                    
                    // Update height when images load
                    const images = document.querySelectorAll('img');
                    images.forEach(img => {
                        img.addEventListener('load', updateHeight);
                    });
                    
                    // Disable selection for better UX
                    document.body.style.webkitUserSelect = 'none';
                    document.body.style.webkitTouchCallout = 'none';
                });
                
                // Update height when content changes
                const observer = new MutationObserver(updateHeight);
                observer.observe(document.body, { 
                    childList: true, 
                    subtree: true, 
                    attributes: true, 
                    characterData: true 
                });
            </script>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        // Cache the processed content
        cacheManager.cacheHTMLContent(processedContent, for: contentHash)
        
        return processedContent
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedHeight() {
        if let cachedHeight = cacheManager.getCachedHeight(for: contentHash) {
            renderedHeight = cachedHeight
            isLoading = false
        }
    }
    
    private func saveHeightToCache(_ height: CGFloat) {
        cacheManager.cacheHeight(height, for: contentHash)
        cacheManager.markAsRendered(contentHash)
    }
}

// MARK: - HTML WebView Component
private struct HTMLWebView: UIViewRepresentable {
    let htmlContent: String
    let contentHash: String
    @Binding var height: CGFloat
    @Binding var isLoading: Bool
    let onHeightCalculated: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "heightUpdate")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        
        // Performance optimizations
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: HTMLWebView
        
        init(_ parent: HTMLWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightUpdate", let height = message.body as? CGFloat {
                DispatchQueue.main.async {
                    self.parent.height = height
                    self.parent.onHeightCalculated(height)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow only initial load, block all navigation
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}

// MARK: - UIColor Extensions
private extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "#%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255))
    }
}

// MARK: - Fallback AttributedString Renderer (iOS 15+)
@available(iOS 15.0, *)
public struct AttributedStringHTMLRenderer: View {
    private let htmlContent: String
    private let baseFont: UIFont
    private let baseColor: UIColor
    
    @State private var attributedString: AttributedString?
    
    public init(
        htmlContent: String,
        baseFont: UIFont = UIFont.systemFont(ofSize: 16),
        baseColor: UIColor = UIColor.label
    ) {
        self.htmlContent = htmlContent
        self.baseFont = baseFont
        self.baseColor = baseColor
    }
    
    public var body: some View {
        Group {
            if let attributedString = attributedString {
                Text(attributedString)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(htmlContent.strippingHTMLTags)
                    .font(Font(baseFont))
                    .foregroundColor(Color(baseColor))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task {
            await loadAttributedString()
        }
    }
    
    @MainActor
    private func loadAttributedString() async {
        do {
            let data = Data(htmlContent.utf8)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let nsAttributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            attributedString = AttributedString(nsAttributedString)
        } catch {
            // Fallback to plain text
            attributedString = AttributedString(htmlContent.strippingHTMLTags)
        }
    }
}

// MARK: - HTML Renderer Factory
public enum HTMLRendererFactory {
    
    /// Create the best available HTML renderer for the current iOS version
    @MainActor
    public static func createRenderer(
        htmlContent: String,
        baseFont: UIFont = UIFont.systemFont(ofSize: 16),
        baseColor: UIColor = UIColor.label
    ) -> AnyView {
        if #available(iOS 16.0, *) {
            // Use WebKit for best performance and compatibility
            return AnyView(HTMLRenderer(
                htmlContent: htmlContent,
                baseFont: baseFont,
                baseColor: baseColor
            ))
        } else if #available(iOS 15.0, *) {
            // Use AttributedString as fallback
            return AnyView(AttributedStringHTMLRenderer(
                htmlContent: htmlContent,
                baseFont: baseFont,
                baseColor: baseColor
            ))
        } else {
            // Use plain text for older versions
            return AnyView(
                Text(htmlContent.strippingHTMLTags)
                    .font(Font(baseFont))
                    .foregroundColor(Color(baseColor))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            )
        }
    }
}