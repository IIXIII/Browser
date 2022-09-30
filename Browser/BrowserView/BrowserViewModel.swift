//
//  BrowserViewModel.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 27/09/22.
//

import Foundation
import UIKit

enum NavigationError: String, Error {
    case invalidURL = "Invalid URL"
}

final class BrowserViewModel {
    private var browsers: [Browser] = []
    private let firstURL = ["https://www.google.com",
                            "https://www.hackingwithswift.com",
                            "https://browser.kagi.com",
                            "https://medium.com",
                            "https://www.raywenderlich.com",
                            "https://stackoverflow.com"]
    
    private let blankURL = URL(string: "about:blank")!
    private(set) var browserSelected: Int = 0 {
        didSet {
            updateBrowserIndex()
        }
    }
    
    private let storage: StorageManager

    weak var delegate: BrowserObserver?
    var numberBrowsers: Int {
        browsers.count
    }
    var browserHasURL: Bool {
        !browsers[browserSelected].stackHistory.isEmpty
    }
    
    init(storage: StorageManager) {
        self.storage = storage
    }

    func createBrowser() {
        browsers.append(Browser(indexHistory: 0,
                                currentImage: nil,
                                stackHistory: []))
        browserSelected = numberBrowsers - 1
    }
    
    func selectBrowser(index: Int) {
        guard browserSelected != index else { return }
        browserSelected = index
        clearBrowser()
    }
    
    func loadURLCurrentBrowser() {
        if !browsers[browserSelected].stackHistory.isEmpty {
            let url = browsers[browserSelected].stackHistory[browsers[browserSelected].indexHistory]
            delegate?.loadInBrowser(url: url)
        }
    }
    
    func initNavigation() {
        if let url = URL(string: firstURL.randomElement() ?? "") {
            clearBrowser()
            delegate?.loadInBrowser(url: url)
        }
    }
    
    func search(urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw NavigationError.invalidURL }
        delegate?.loadInBrowser(url: url)
    }
    
    func getImage(for index: Int)->UIImage? {
        browsers[index].currentImage
    }
    
    func addToHistory(url: URL) {
        defer { updateBrowserIndex() }
        
        let currentBrowser = browsers[browserSelected]
        
        if (!currentBrowser.stackHistory.isEmpty && currentBrowser.stackHistory[currentBrowser.indexHistory] == url) ||
            url == blankURL { return }
        
        let indexHistory = browsers[browserSelected].indexHistory
        
        //Check if the browser went backwards
        if indexHistory > 0,
           browsers[browserSelected].stackHistory[indexHistory - 1] == url {
            browsers[browserSelected].indexHistory -= 1
            return
        }
        
        //Check if the browser went forward
        if indexHistory < browsers[browserSelected].stackHistory.count - 1,
           browsers[browserSelected].stackHistory[indexHistory + 1] == url {
            browsers[browserSelected].indexHistory += 1
            return
        }
        
        if indexHistory < browsers[browserSelected].stackHistory.count - 1 {
            browsers[browserSelected].stackHistory.removeSubrange(indexHistory + 1..<browsers[browserSelected].stackHistory.count)
        }
        browsers[browserSelected].stackHistory.append(url)
        browsers[browserSelected].indexHistory = browsers[browserSelected].stackHistory.count - 1
    }
    
    func goBack() {
        let currentBrowser = browsers[browserSelected]
        let url = currentBrowser.stackHistory[currentBrowser.indexHistory - 1]
        delegate?.loadInBrowser(url: url)
    }
    
    func goForward() {
        let currentBrowser = browsers[browserSelected]
        let url = currentBrowser.stackHistory[currentBrowser.indexHistory + 1]
        delegate?.loadInBrowser(url: url)
    }
    
    func updateImageInBrowser(index: Int, image: UIImage?) {
        browsers[browserSelected].currentImage = image
    }
    
    func loadBrowsers() {
        browsers = storage.getBrowsers()
        if !browsers.isEmpty {
            if !browsers[browserSelected].stackHistory.isEmpty {
                let currentBrowser = browsers[browserSelected]
                delegate?.loadInBrowser(url: currentBrowser.stackHistory[currentBrowser.indexHistory])
            }
        } else {
            browsers = [Browser(indexHistory: 0, currentImage: nil, stackHistory: [])]
        }
        browserSelected = storage.getCurrentBrowser()
    }
    
    func save() {
        storage.saveBrowsers(browsers: browsers)
        storage.saveCurrentBrowser(browserSelected)
    }
    
    func delete(index: Int) {
        let count = browsers.count - 1
        browsers.remove(at: index)
        if index < browserSelected {
            browserSelected -= 1
        }
        if index == browserSelected {
            if index == count {
                browserSelected -= 1
            }
        }
        delegate?.updateBrowsers()
        if browsers.isEmpty {
            createBrowser()
            delegate?.updateBrowsers()
            delegate?.selectNewBrowser(index: 0)
        }
    }
    
    private func updateBrowserIndex() {
        guard !browsers.isEmpty else {
            delegate?.updateBack(isEnabled: false)
            delegate?.updateForward(isEnabled: false)
            return
        }
        let currentBrowser = browsers[browserSelected]
        delegate?.updateBack(isEnabled: currentBrowser.indexHistory > 0)
        delegate?.updateForward(isEnabled: currentBrowser.indexHistory < currentBrowser.stackHistory.count - 1)
    }
    
    private func clearBrowser() {
        delegate?.loadInBrowser(url: blankURL)
    }
}
