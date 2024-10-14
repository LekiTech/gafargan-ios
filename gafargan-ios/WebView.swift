//
//  WebView.swift
//  gafargan-ios
//
//  Created by Kamran Tadzjibov on 14/10/2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    let url: URL
    @Binding var isLoading: Bool

    
    class Coordinator: NSObject, WKScriptMessageHandler {
        @Binding var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleHandler" {
                print("JavaScript console.log: \(message.body)")
            }  else if message.name == "initCompleted" {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    func readJSONFile(filename: String) -> String? {
        if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "dist") {
            if let data = try? Data(contentsOf: url) {
                let jsonString = String(data: data, encoding: .utf8)
                return jsonString
            }
        }
        return nil
    }

    func makeUIView(context: Context) -> WKWebView {
        // configuring the `WKWebView` is very important
        // without doing this the local index.html will not be able to read
        // the css or js files properly
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // Add script message handler
        config.userContentController.add(context.coordinator, name: "consoleHandler")
        config.userContentController.add(context.coordinator, name: "initCompleted")
        
        // Inject JavaScript to override console.log
        let js = """
        (function() {
            var oldLog = console.log;
            console.log = function() {
                var message = Array.prototype.slice.call(arguments).join(' ');
                window.webkit.messageHandlers.consoleHandler.postMessage(message);
                oldLog.apply(console, arguments);
            };
            console.error = function() {
                var message = Array.prototype.slice.call(arguments).join(' ');
                window.webkit.messageHandlers.consoleHandler.postMessage(message);
                oldLog.apply(console, arguments);
            };
        })();
        """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        
        // Read and inject JSON data
        let expressionsJSON = readJSONFile(filename: "expressions") ?? "null"
        let expressionDetailsJSON = readJSONFile(filename: "expressionDetails") ?? "null"
        let definitionsJSON = readJSONFile(filename: "definitions") ?? "null"
        let examplesJSON = readJSONFile(filename: "examples") ?? "null"
        let lookUpDataJSON = readJSONFile(filename: "lookUpData") ?? "null"
        
        let injectionJS = """
        window.expressions = \(expressionsJSON);
        window.expressionDetails = \(expressionDetailsJSON);
        window.definitions = \(definitionsJSON);
        window.examples = \(examplesJSON);
        window.lookUpData = \(lookUpDataJSON);
        """
        let injectionUserScript = WKUserScript(source: injectionJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(injectionUserScript)
        
        // set the configuration on the `WKWebView`
        // don't worry about the frame: .zero, SwiftUI will resize the `WKWebView` to
        // fit the parent
        let webView = WKWebView(frame: .zero, configuration: config)
        // now load the local url
        // Allow read access to the directory containing the HTML file
        let directoryURL = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: directoryURL)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Allow read access to the directory containing the HTML file
        let directoryURL = url.deletingLastPathComponent()
        uiView.loadFileURL(url, allowingReadAccessTo: directoryURL)
    }
}
