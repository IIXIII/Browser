//
//  SearchCollectionViewCell.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 26/09/22.
//

import UIKit

final class SearchCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String { "\(Self.description())" }
    private let searchBar = UISearchBar()
    var viewModel: BrowserViewModel?
    var onStartWriting: (()->Void)?
    var onError: ((NavigationError)->Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        setupView(frame: frame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(frame: CGRect) {
        searchBar.frame = frame
        searchBar.delegate = self
        backgroundColor = .green

        contentView.addSubview(searchBar)
        searchBar.constraintsEquals()
    }
}

extension SearchCollectionViewCell: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        do {
            try viewModel?.search(urlString: searchBar.text ?? "")
        } catch let navError as NavigationError {
            onError?(navError)
        } catch { }
        contentView.endEditing(true)
        searchBar.text = ""
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        onStartWriting?()
    }
}
