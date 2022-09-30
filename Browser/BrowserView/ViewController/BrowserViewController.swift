//
//  BrowserViewController.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 27/09/22.
//

import UIKit
import WebKit
import SnapshotKit

protocol BrowserObserver: AnyObject {
    func loadInBrowser(url: URL)
    func updateBack(isEnabled: Bool)
    func updateForward(isEnabled: Bool)
    func updateBrowsers()
    func selectNewBrowser(index: Int)
}

final class BrowserViewController: UIViewController {
    @IBOutlet weak var collectionSearch: UICollectionView!
    @IBOutlet weak var collectionWebBrowser: UICollectionView!

    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var forward: UIButton!
    @IBOutlet weak var navigation: UIButton!
    
    @IBOutlet weak var done: UIButton!
    @IBOutlet weak var add: UIButton!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    private var indexCellSelected: IndexPath {
        IndexPath(item: viewModel.browserSelected, section: 0)
    }
    private let timeAnimations = 0.5
    private lazy var webViewBrowser: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let web = WKWebView(frame: .zero, configuration: webConfiguration)
        web.allowsBackForwardNavigationGestures = true
        web.navigationDelegate = self
        return web
    }()
    
    private lazy var initialView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        let button = UIButton()
        button.setTitle("Take me somewhere", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(goSomeWhere), for: .touchUpInside)
        view.addSubview(button)
        button.constraintsCenter()
        return view
    }()
    
    private lazy var imageWebView: UIImageView = {
        let image = UIImageView()
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.backgroundColor = .yellow
        return image
    }()
        
    private let viewModel: BrowserViewModel
    
    init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.loadBrowsers()
        setupView()
        loadInitial()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionSearch.collectionViewLayout.invalidateLayout()
        collectionWebBrowser.collectionViewLayout.invalidateLayout()
    }
    
    private func setupView() {
        view.addSubview(imageWebView)
        imageWebView.isHidden = true

        view.addSubview(webViewBrowser)
        webViewBrowser.constraintsEquals(to: collectionWebBrowser)
        view.bringSubviewToFront(webViewBrowser)

        view.addSubview(initialView)
        initialView.constraintsEquals(to: collectionWebBrowser)
        view.bringSubviewToFront(initialView)

        collectionWebBrowser.dataSource = self
        collectionWebBrowser.delegate = self
        collectionWebBrowser.register(WebviewCollectionViewCell.self,
                                forCellWithReuseIdentifier: WebviewCollectionViewCell.reuseIdentifier)
        
        collectionSearch.dataSource = self
        collectionSearch.delegate = self
        collectionSearch.register(SearchCollectionViewCell.self,
                                  forCellWithReuseIdentifier: SearchCollectionViewCell.reuseIdentifier)
        
        setStatus(browserShowed: true)
        
        back.setTitle("", for: .normal)
        forward.setTitle("", for: .normal)
        navigation.setTitle("", for: .normal)
        add.setTitle("", for: .normal)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

    }
    
    private func loadInitial() {
        webViewBrowser.isHidden = !viewModel.browserHasURL
        initialView.isHidden = viewModel.browserHasURL
    }
       
    @objc func goSomeWhere() {
        view.endEditing(true)
        showWebview()
        viewModel.initNavigation()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraint.constant = keyboardSize.height
            view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 0
        view.layoutIfNeeded()
    }
    
    @objc func appMovedToBackground() {
        viewModel.save()
    }
    
    @IBAction func backAction(_ sender: Any) {
        view.endEditing(true)
        viewModel.goBack()
    }
    
    @IBAction func forwardAction(_ sender: Any) {
        view.endEditing(true)
        viewModel.goForward()
    }
    
    @IBAction func addWebView(_ sender: Any) {
        view.endEditing(true)
        viewModel.createBrowser()
        collectionWebBrowser.reloadData {
            DispatchQueue.main.async {
                self.selectBrowser(index: self.indexCellSelected)
            }
        }
    }
    
    @IBAction func doneAction(_ sender: Any) {
        view.endEditing(true)
        selectBrowser(index: indexCellSelected)
    }
        
    @IBAction func navigationAction(_ sender: Any) {
        view.endEditing(true)
        guard let cell = collectionWebBrowser.cellForItem(at: indexCellSelected) as? WebviewCollectionViewCell else { return }
        let frameCellSelected = collectionWebBrowser.convert(cell.frame, to: view)

        setStatus(browserShowed: false)
        collectionWebBrowser.isUserInteractionEnabled = true
        
        imageWebView.frame = collectionWebBrowser.frame
        imageWebView.isHidden = false

        imageWebView.image = initialView.isHidden ? webViewBrowser.takeSnapshotOfVisibleContent() : initialView.takeSnapshotOfVisibleContent()
        view.bringSubviewToFront(imageWebView)
        webViewBrowser.isHidden = true
        initialView.isHidden = true
        
        UIView.animate(withDuration: timeAnimations, animations: {
            self.imageWebView.frame = frameCellSelected
        }) { _ in
            self.imageWebView.isHidden = true
            cell.setImage(self.imageWebView.image)
            self.viewModel.updateImageInBrowser(index: self.indexCellSelected.item,
                                                image: self.imageWebView.image)
        }
    }
    
    private func setStatus(browserShowed: Bool) {
        let alphaBrowser = browserShowed ? 1.0 : 0.0
        let alphaNav = browserShowed ? 0.0 : 1.0

        UIView.animate(withDuration: timeAnimations) {
            self.back.alpha = alphaBrowser
            self.forward.alpha = alphaBrowser
            self.navigation.alpha = alphaBrowser
            
            self.done.alpha = alphaNav
            self.add.alpha = alphaNav
        }
    }
    
    func selectBrowser(index: IndexPath) {
        guard let cell = collectionWebBrowser.cellForItem(at: index) as? WebviewCollectionViewCell else { return }
        setStatus(browserShowed: true)
        let frameCellSelected = collectionWebBrowser.convert(cell.frame, to: view)
        collectionWebBrowser.isUserInteractionEnabled = false
        if viewModel.browserHasURL {
            //if there is a page loaded
            imageWebView.isHidden = false
            imageWebView.image = cell.webViewImage.image
            
            view.bringSubviewToFront(imageWebView)
            
            imageWebView.frame = frameCellSelected
            UIView.animate(withDuration: timeAnimations, animations: {
                self.imageWebView.frame = self.collectionWebBrowser.frame
            }) { _ in
                self.webViewBrowser.isHidden = false
                self.imageWebView.isHidden = true
                self.viewModel.loadURLCurrentBrowser()
                self.view.bringSubviewToFront(self.webViewBrowser)
            }
        } else {
            //Show the first view
            initialView.removeAllConstraints()
            initialView.isHidden = false
            view.bringSubviewToFront(initialView)
            initialView.frame = frameCellSelected

            initialView.subviews.first?.constraintsCenter()

            UIView.animate(withDuration: timeAnimations, animations: {
                self.initialView.frame = self.collectionWebBrowser.frame
            }) { _ in
                self.initialView.constraintsEquals(to: self.collectionWebBrowser)
                self.webViewBrowser.isHidden = false
                self.viewModel.loadURLCurrentBrowser()
            }
        }
    }
    
    private func showWebview() {
        initialView.isHidden = true
        webViewBrowser.isHidden = false
        view.bringSubviewToFront(webViewBrowser)
    }
}

extension BrowserViewController: BrowserObserver {
    func loadInBrowser(url: URL) {
        guard webViewBrowser.url != url else { return }
        showWebview()
        webViewBrowser.load(URLRequest(url: url))
    }
    
    func updateBack(isEnabled: Bool) {
        back.isEnabled = isEnabled
    }
    
    func updateForward(isEnabled: Bool) {
        forward.isEnabled = isEnabled
    }
    
    func updateBrowsers() {
        DispatchQueue.main.async {
            self.collectionWebBrowser.performBatchUpdates({
                let indexSet = IndexSet(integersIn: 0...0)
                self.collectionWebBrowser.reloadSections(indexSet)
            }, completion: nil)
        }
    }
    
    func selectNewBrowser(index: Int) {
        selectBrowser(index: IndexPath(item: index, section: 0))
    }
    
    func handleError(error: NavigationError) {
        let title: String = "Ooops!"
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: error.rawValue, preferredStyle: .alert)
            self.present(alert, animated: true)
        }
    }
}


extension BrowserViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberBrowsers
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collectionSearch {
            let cell: SearchCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCollectionViewCell.reuseIdentifier, for: indexPath) as! SearchCollectionViewCell
            cell.viewModel = viewModel
            cell.onStartWriting = { [weak self] in
                guard let self = self else { return }
                if self.navigation.alpha == 0 {
                    self.selectBrowser(index: self.indexCellSelected)
                }
            }
            cell.onError = { [weak self] error in
                self?.handleError(error: error)
            }
            return cell
        } else {
            let cell: WebviewCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: WebviewCollectionViewCell.reuseIdentifier, for: indexPath) as! WebviewCollectionViewCell
            cell.viewModel = viewModel
            cell.index = indexPath.item
            cell.setImage(viewModel.getImage(for: indexPath.item))
            return cell
        }
    }
}


extension BrowserViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collectionWebBrowser {
            viewModel.selectBrowser(index: indexPath.item)
            selectBrowser(index: indexCellSelected)
        }
    }
}

extension BrowserViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collectionSearch {
            return  CGSize(width: collectionView.frame.size.width * 0.85,
                           height: collectionView.frame.size.height)
        }
        
        guard let flowayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let space: CGFloat = flowayout.minimumInteritemSpacing +
                             flowayout.sectionInset.left +
                             flowayout.sectionInset.right
        
        let width = (collectionView.frame.size.width - space) / 2.0
        let height = width * collectionView.frame.size.height / collectionView.frame.size.width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == collectionSearch {
            let inset = collectionView.frame.size.width * 0.075
            return UIEdgeInsets(top: 0,
                                left: inset,
                                bottom: 0,
                                right: inset)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        viewModel.addToHistory(url: url)
    }
}
