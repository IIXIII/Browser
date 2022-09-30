//
//  StorageManager.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 28/09/22.
//

import Foundation
import RealmSwift

protocol StorageManager {
    func getBrowsers()->[Browser]
    func getCurrentBrowser()->Int
    func saveBrowsers(browsers: [Browser])
    func saveCurrentBrowser(_ index: Int )
}

final class BrowserRealm: Object {
    @Persisted var indexHistory: Int
    @Persisted var currentImage: Data?
    @Persisted var stackHistory = List<String>()
    convenience init(indexHistory: Int, currentImage: Data?, stackHistory: [URL]) {
        self.init()
        self.indexHistory = indexHistory
        self.currentImage = currentImage
        self.stackHistory.append(objectsIn: stackHistory.map { $0.absoluteString })
    }
}

final class StorageRealm: StorageManager {
    private let realm = try! Realm()
    private let currentBrowser = "CurrentBrowser"

    func getBrowsers() -> [Browser] {
        let browsersRealm = realm.objects(BrowserRealm.self)
        let browsers: [Browser] = browsersRealm.map {
            var image: UIImage? = nil
            if let data = $0.currentImage {
                image = UIImage(data: data)
            }
            let array = $0.stackHistory.toArray().map { url in URL(string: url)! }
            return Browser(indexHistory: $0.indexHistory,
                    currentImage: image,
                           stackHistory: array)
        }
        return browsers
    }
    
    func saveBrowsers(browsers: [Browser]) {
        //TODO: This is not the best, but for time this was the easiest way
        delete()
        let browsersRealm = browsers.map {  BrowserRealm(indexHistory: $0.indexHistory,
                                                         currentImage: $0.currentImage?.jpegData(compressionQuality: 1),
                                                         stackHistory: $0.stackHistory)}
        do {
            try realm.write {
                realm.add(browsersRealm)
            }
        } catch let error as NSError {
            print("error saving: \(error)")
        }
    }
    
    func delete() {
        do {
            try realm.write {
                let browsersRealm = realm.objects(BrowserRealm.self)
                realm.delete(browsersRealm)
            }
        } catch let error as NSError {
            print("error deleting: \(error)")
        }
    }
    
    func saveCurrentBrowser(_ index: Int ) {
        UserDefaults.standard.set(index, forKey: currentBrowser)
    }
    
    func getCurrentBrowser()->Int {
        UserDefaults.standard.integer(forKey: currentBrowser)
    }
}

extension RealmCollection {
    func toArray<T>() ->[T] {
        compactMap{$0 as? T}
    }
}
