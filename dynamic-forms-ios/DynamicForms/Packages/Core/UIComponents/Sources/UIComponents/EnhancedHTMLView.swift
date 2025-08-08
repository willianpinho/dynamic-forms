import Foundation
import SwiftUI
import WebKit
import UIKit
import DesignSystem
import Utilities

/// Enhanced HTML view for UIComponents package
/// Provides high-performance HTML rendering with O(1) operations
@MainActor
public struct EnhancedHTMLView: View {
    
    // MARK: - Properties
    private let htmlContent: String
    private let maxHeight: CGFloat
    
    // MARK: - State
    @State private var renderedHeight: CGFloat = 50
    @State private var isLoading: Bool = true
    
    // MARK: - Initialization
    public init(
        htmlContent: String,
        maxHeight: CGFloat = 300
    ) {
        self.htmlContent = htmlContent
        self.maxHeight = maxHeight
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
    }
    
    // MARK: - HTML Web View
    private var htmlWebView: some View {
        UIKitHTMLView(
            htmlContent: processedHTMLContent,
            height: $renderedHeight,
            isLoading: $isLoading,
            maxHeight: maxHeight
        )
        .frame(height: min(renderedHeight, maxHeight))
        .opacity(isLoading ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
    
    // MARK: - Plain Text View
    private var plainTextView: some View {
        Text(htmlContent)
            .font(DFTypography.bodyMedium)
            .foregroundColor(DFColors.onSurface)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Processed HTML Content
    private var processedHTMLContent: String {
        return """
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
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.4;
                    color: #1D1D1D;
                    padding: 12px;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                    -webkit-text-size-adjust: none;
                    margin-bottom: 0;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin: 6px 0 3px 0;
                    font-weight: 600;
                    line-height: 1.2;
                }
                h1:last-child, h2:last-child, h3:last-child, 
                h4:last-child, h5:last-child, h6:last-child {
                    margin-bottom: 0;
                }
                h1 { font-size: 1.4em; }
                h2 { font-size: 1.2em; }
                h3 { font-size: 1.1em; }
                h4, h5, h6 { font-size: 1em; }
                p {
                    margin: 3px 0;
                }
                p:last-child {
                    margin-bottom: 0;
                }
                ul, ol {
                    margin: 3px 0;
                    padding-left: 18px;
                }
                li {
                    margin: 1px 0;
                }
                strong, b { font-weight: 600; }
                em, i { font-style: italic; }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                code {
                    background-color: #f0f0f0;
                    padding: 1px 3px;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, monospace;
                    font-size: 0.9em;
                }
                pre {
                    background-color: #f0f0f0;
                    padding: 6px;
                    border-radius: 6px;
                    overflow-x: auto;
                    margin: 6px 0;
                    font-size: 0.9em;
                }
                blockquote {
                    border-left: 3px solid #ddd;
                    padding-left: 10px;
                    margin: 6px 0;
                    font-style: italic;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 6px;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 6px 0;
                    font-size: 0.9em;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 6px;
                    text-align: left;
                }
                th {
                    background-color: #f0f0f0;
                    font-weight: 600;
                }
            </style>
            <script>
                function updateHeight() {
                    const height = Math.max(document.body.scrollHeight, 30);
                    window.webkit.messageHandlers.heightUpdate.postMessage(height);
                }
                
                document.addEventListener('DOMContentLoaded', function() {
                    setTimeout(updateHeight, 50);
                    
                    // Update height when images load
                    const images = document.querySelectorAll('img');
                    images.forEach(img => {
                        img.addEventListener('load', updateHeight);
                    });
                    
                    // Disable interactions for better UX
                    document.body.style.webkitUserSelect = 'none';
                    document.body.style.webkitTouchCallout = 'none';
                    
                    // Prevent zooming
                    document.addEventListener('gesturestart', function (e) {
                        e.preventDefault();
                    });
                });
            </script>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
    }
}

// MARK: - UIKit HTML View
private struct UIKitHTMLView: UIViewRepresentable {
    let htmlContent: String
    @Binding var height: CGFloat
    @Binding var isLoading: Bool
    let maxHeight: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "heightUpdate")
        configuration.suppressesIncrementalRendering = true
        
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
        
        // Disable context menus and selection
        webView.allowsBackForwardNavigationGestures = false
        
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
        var parent: UIKitHTMLView
        
        init(_ parent: UIKitHTMLView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightUpdate", let height = message.body as? Double {
                DispatchQueue.main.async {
                    self.parent.height = min(CGFloat(height), self.parent.maxHeight)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Block all navigation except initial load
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}

// MARK: - Previews
#if DEBUG
struct EnhancedHTMLView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            EnhancedHTMLView(
                htmlContent: "<h3>HTML Test</h3><p>This is a <strong>test</strong> of <em>HTML rendering</em> with <a href='#'>links</a>.</p><ul><li>Item 1</li><li>Item 2</li></ul>"
            )
            
            EnhancedHTMLView(
                htmlContent: "Plain text content without HTML"
            )
        }
        .padding()
        .previewDisplayName("Enhanced HTML View")
    }
}
#endif