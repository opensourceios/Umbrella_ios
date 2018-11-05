//
//  ReviewLessonViewController.swift
//  Umbrella
//
//  Created by Lucas Correa on 10/10/2018.
//  Copyright © 2018 Security First. All rights reserved.
//

import UIKit

class ReviewLessonViewController: UIViewController {
    
    //
    // MARK: - Properties
    @IBOutlet weak var sideScrollView: SideScrollLessonView!
    @IBOutlet weak var reviewScrollView: UIScrollView!
    var currentPage: CGFloat = 0
    
    lazy var reviewLessonViewModel: ReviewLessonViewModel = {
        let reviewLessonViewModel = ReviewLessonViewModel()
        return reviewLessonViewModel
    }()
    
    lazy var pages: [UIViewController] = {
        return getViewControllers()
    }()
    
    //
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let modeBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(self.shareAction(_:)))
        self.navigationItem.rightBarButtonItem  = modeBarButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.sideScrollView.dataSource = self
        self.sideScrollView.reloadData()
        
        for (index, viewController) in pages.enumerated() {
            var frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
            frame.origin.x = self.reviewScrollView.frame.size.width * CGFloat(index)
            frame.size = self.reviewScrollView.frame.size
            
            if let subView = viewController.view {
                subView.frame = frame
                subView.tag = index
                
                self.reviewScrollView.addSubview(subView)
            }
        }
        
        self.reviewScrollView.contentSize = CGSize(width: self.reviewScrollView.frame.size.width * CGFloat(pages.count), height: self.reviewScrollView.frame.size.height)
        
        setCurrentPosition()
    }
    
    //
    // MARK: - Functions
    
    /// Get Viewcontrollers
    ///
    /// - Returns: [UIViewController]
    func getViewControllers() -> [UIViewController] {
        var viewControllers = [UIViewController]()
        
        self.reviewLessonViewModel.segments?.forEach({ (segment) in
            let viewcontroller = (self.getViewController(withIdentifier: "MarkdownViewController") as? MarkdownViewController)!
            viewcontroller.markdownViewModel.segment = segment
            viewControllers.append(viewcontroller)
        })
        
        self.reviewLessonViewModel.checkLists?.forEach({ (checklist) in
            let viewcontroller = (self.getViewController(withIdentifier: "LessonCheckListViewController") as? LessonCheckListViewController)!
            viewcontroller.lessonCheckListViewModel.category = self.reviewLessonViewModel.category
            viewcontroller.lessonCheckListViewModel.checklist = checklist
            viewControllers.append(viewcontroller)
        })
        
        return viewControllers
    }
    
    /// Get ViewController with Identifier
    ///
    /// - Parameter identifier: String
    /// - Returns: UIViewController
    func getViewController(withIdentifier identifier: String) -> UIViewController {
        return UIStoryboard(name: "Lesson", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    /// Set position of the workflow tabs
    fileprivate func setCurrentPosition() {
        var segment:Segment? = nil
        var checklist:CheckList? = nil
        
        if self.reviewLessonViewModel.selected is Segment {
            segment = (self.reviewLessonViewModel.selected as? Segment)
        } else if self.reviewLessonViewModel.selected is CheckList {
            checklist = (self.reviewLessonViewModel.selected as? CheckList)
        }
        
        for (index, viewController) in pages.enumerated() {
            if viewController is MarkdownViewController, loadSegment(index: index, viewController: viewController, segment: segment) {
                break
            }
            
            if viewController is LessonCheckListViewController, loadChecklist(index: index, viewController: viewController, checklist: checklist) {
                break
            }
        }
    }
    
    /// Load segment selected
    ///
    /// - Parameters:
    ///   - index: Int
    ///   - viewController: UIViewController
    ///   - segment: Segment
    /// - Returns: Bool
    fileprivate func loadSegment(index: Int, viewController: UIViewController, segment: Segment?) -> Bool {
        let controller = (viewController as? MarkdownViewController)!
        
        if controller.markdownViewModel.segment?.id == segment?.id {
            self.sideScrollView.scrollViewDidPage(page: CGFloat(index))
            self.reviewScrollView.contentOffset = CGPoint(x: self.reviewScrollView.frame.size.width * CGFloat(index), y: 0)
            
            // Set title navigationController
            if let name = controller.markdownViewModel.segment?.name {
                self.title = name
            }
            
            controller.loadMarkdown()
            return true
        }
        
        return false
    }
    
    /// Load checklist selected
    ///
    /// - Parameters:
    ///   - index: Int
    ///   - viewController: UIViewController
    ///   - segment: Segment
    /// - Returns: Bool
    fileprivate func loadChecklist(index: Int, viewController: UIViewController, checklist: CheckList?) -> Bool {
        let controller = (viewController as? LessonCheckListViewController)!
        
        if controller.lessonCheckListViewModel.checklist?.id == checklist?.id {
            self.sideScrollView.scrollViewDidPage(page: CGFloat(index))
            self.reviewScrollView.contentOffset = CGPoint(x: self.reviewScrollView.frame.size.width * CGFloat(index), y: 0)
            
            // Set title navigationController
            self.title = "CheckList".localized()
            return true
        }
        return false
    }
    
    //
    // MARK: - Actions
    
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        var checkItemChecked = ""
        
        let viewController = self.pages.filter { $0 is LessonCheckListViewController }.first
        if let viewController = viewController {
            let controller = (viewController as? LessonCheckListViewController)!
            
            for checkItem in (controller.lessonCheckListViewModel.checklist?.items)! {
                checkItemChecked.append("\(checkItem.checked ? "✓" : "✗") \(checkItem.name)\n")
            }
            
            let objectsToShare = [checkItemChecked]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.copyToPasteboard]
            
            activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if !completed {
                    // User canceled
                    return
                }
                // User completed activity
            }
            
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}

//
// MARK: - UIScrollViewDelegate
extension ReviewLessonViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateDidScroll(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDidScroll(scrollView)
    }
    
    func updateDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        currentPage = pageNumber
        self.sideScrollView.scrollViewDidPage(page: currentPage)
        self.view.endEditing(true)
        
        let viewController = self.pages[Int(currentPage)]
        
        if viewController is MarkdownViewController {
            let controller = (viewController as? MarkdownViewController)!
            if let name = controller.markdownViewModel.segment?.name {
                self.title = name
            }
            controller.loadMarkdown()
        } else if viewController is LessonCheckListViewController {
            self.title = "CheckList".localized()
        }
    }
}

//
// MARK: - StepperViewDataSource
extension ReviewLessonViewController: SideScrollLessonViewDataSource {
    
    func viewAtIndex(_ index: Int) -> UIView {
        
        //ViewMain
        let titleFormView = TitleLessonView(frame: CGRect(x: CGFloat(index) * self.sideScrollView.visivelPercentualSize, y: 2, width: self.sideScrollView.viewWidth(index: index), height: self.sideScrollView.frame.size.height-5))
        
        //Title
        titleFormView.titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: titleFormView.frame.size.width, height: titleFormView.frame.size.height))
        titleFormView.titleLabel?.font = UIFont(name: "SFProText-SemiBold", size: 11)
        titleFormView.titleLabel?.textAlignment = .center
        titleFormView.titleLabel?.numberOfLines = 0
        titleFormView.titleLabel?.minimumScaleFactor = 0.5
        titleFormView.titleLabel?.adjustsFontSizeToFitWidth = true
        titleFormView.addSubview(titleFormView.titleLabel!)
        
        let viewController = self.pages[index]
        
        if viewController is LessonCheckListViewController {
            titleFormView.setTitle("CheckList".localized())
        } else {
            let controller = (viewController as? MarkdownViewController)!
            titleFormView.setTitle(controller.markdownViewModel.segment?.name ?? "")
        }
        
        return titleFormView
    }
    
    func numberOfTitles() -> Int {
        return pages.count
    }
}
