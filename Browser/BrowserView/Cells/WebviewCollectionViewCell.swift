//
//  WebviewCollectionViewCell.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 26/09/22.
//

import UIKit

import UIKit
import WebKit

final class WebviewCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String { "\(Self.description())" }
    let webViewImage = UIImageView()
    var viewModel: BrowserViewModel?
    var index: Int?

    private lazy var deleteButton: UIButton = {
        let button = UIButton(frame: CGRect(origin: .zero,
                                            size: CGSize(width: 45, height: 45)))
        button.setImage(UIImage(systemName: "clear"), for: .normal)
        button.tintColor = .label
        button.layer.cornerRadius = 17.5
        button.backgroundColor = .systemGray6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteBrowser), for: .touchUpInside)
        return button
    }()
    
    @objc private func deleteBrowser() {
        guard let index = index else { return }
        viewModel?.delete(index: index)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        index = nil
        contentView.addSubview(webViewImage)
        webViewImage.frame = contentView.bounds
        webViewImage.constraintsEquals()
        webViewImage.contentMode = .scaleAspectFill
        contentView.layer.masksToBounds = true
        contentView.addSubview(deleteButton)
        
        deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5).isActive = true
        deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5).isActive = true
        deleteButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        deleteButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
    }
    
    func setImage(_ image: UIImage?) {
        webViewImage.image = image
    }
}

