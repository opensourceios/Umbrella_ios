//
//  ChatItemRequestViewController.swift
//  Umbrella
//
//  Created by Lucas Correa on 01/07/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import UIKit

class ChatItemRequestViewController: UIViewController {
    
    //
    // MARK: - Properties
    @IBOutlet weak var chatItemRequestTableView: UITableView!
    @IBOutlet weak var sendBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var emptyLabel: UILabel!
    
    lazy var chatItemRequestViewModel: ChatItemRequestViewModel = {
        let chatItemRequestViewModel = ChatItemRequestViewModel()
        return chatItemRequestViewModel
    }()
    
    lazy var chatMessageViewModel: ChatMessageViewModel = {
        let chatMessageViewModel = ChatMessageViewModel()
        return chatMessageViewModel
    }()
    
    lazy var checklistViewModel: ChecklistViewModel = {
        let checklistViewModel = ChecklistViewModel()
        return checklistViewModel
    }()
    
    lazy var customChecklistViewModel: CustomChecklistViewModel = {
        let customChecklistViewModel = CustomChecklistViewModel()
        return customChecklistViewModel
    }()
    
    lazy var pathwayViewModel: PathwayViewModel = {
        let pathwayViewModel = PathwayViewModel()
        return pathwayViewModel
    }()
    
    @IBOutlet weak var sendButton: UIButton!
    var itemSelected: [IndexPath] = [IndexPath]() {
        didSet {
            if itemSelected.count > 0 {
                self.sendButton.setTitle("Send", for: .normal)
                self.sendBottomConstraint.constant = 44
            } else {
                self.sendButton.setTitle("", for: .normal)
                self.sendBottomConstraint.constant = 0
            }
            
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: [.curveEaseOut, .beginFromCurrentState],
                           animations: {
                            self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 300, height: 250)
        
        self.title = self.chatItemRequestViewModel.item.name
        
        switch self.chatItemRequestViewModel.item.type {
        case .forms:
            if self.chatItemRequestViewModel.umbrella.loadFormAnswersByCurrentLanguage().count == 0 {
                delay(0.5) {
                    self.chatItemRequestTableView.isHidden = true
                    self.emptyLabel.text = "You do not have forms filled."
                }
            }
        case .checklists:
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let controller = (storyboard.instantiateViewController(withIdentifier: "LoadingViewController") as? LoadingViewController)!
            controller.showLoading(view: self.view)
            DispatchQueue.global(qos: .default).async {
                self.checklistViewModel.reportOfItemsChecked()
                self.customChecklistViewModel.loadCustomChecklist()
                
                self.chatItemRequestViewModel.checklistChecked = self.checklistViewModel.checklistChecked
                self.chatItemRequestViewModel.favouriteChecklistChecked = self.checklistViewModel.favouriteChecklistChecked
                self.chatItemRequestViewModel.customChecklistChecked = self.customChecklistViewModel.customChecklistChecked
                self.chatItemRequestViewModel.customChecklists = self.customChecklistViewModel.customChecklists
                
                let languageName: String = UserDefaults.standard.object(forKey: "Language") as? String ?? "en"
                let language = UmbrellaDatabase.languagesStatic.filter { $0.name == languageName }.first
                
                if let language = language {
                    let success = self.pathwayViewModel.listPathways(languageId: language.id)
                    if success {
                        self.pathwayViewModel.updatePathways()
                    }
                    
                    self.chatItemRequestViewModel.pathways = self.pathwayViewModel.pathwayFavorite()
                }
                
                DispatchQueue.main.async {
                    controller.closeLoading()
                    
                    if self.chatItemRequestViewModel.checklistChecked.count == 0 && self.chatItemRequestViewModel.favouriteChecklistChecked.count == 0 && self.chatItemRequestViewModel.customChecklists.count == 0 {
                        self.chatItemRequestTableView.isHidden = true
                        self.emptyLabel.text = "You do not have checklist filled."
                    }
                    
                    self.chatItemRequestTableView.reloadData()
                }
            }
        case .answers:
            break
        default:
            break
        }
    }
    
    fileprivate func exportFormJSON() -> (url: URL, filename: String) {
        do {
            var formAnswer = FormAnswer()
            var form = Form()
            var formAnswers: [FormAnswer] = [FormAnswer]()
            
            let indexPath = self.itemSelected.first!
            
            if indexPath.section == 0 {
                formAnswer = self.chatItemRequestViewModel.umbrella.loadFormAnswersByCurrentLanguage()[indexPath.row]
                
                for formResult in self.chatItemRequestViewModel.umbrella.loadFormByCurrentLanguage() where formAnswer.formId == formResult.id {
                    form = formResult
                }
                
                formAnswers = self.chatItemRequestViewModel.loadFormAnswersTo(formAnswerId: formAnswer.formAnswerId, formId: form.id)
            }
            
            for screen in form.screens {
                
                for item in screen.items {
                    switch item.formType {
                    case .textInput:
                        for formAnswer in formAnswers where formAnswer.itemFormId == item.id {
                            item.answer = formAnswer.text
                        }
                    case .textArea:
                        for formAnswer in formAnswers where formAnswer.itemFormId == item.id {
                            item.answer = formAnswer.text
                        }
                    case .multiChoice:
                        for optionItem in item.options {
                            for formAnswer in formAnswers where formAnswer.itemFormId == item.id && formAnswer.optionItemId == optionItem.id {
                                optionItem.answer = 1
                            }
                        }
                    case .singleChoice:
                        for optionItem in item.options {
                            for formAnswer in formAnswers where formAnswer.itemFormId == item.id && formAnswer.optionItemId == optionItem.id {
                                optionItem.answer = 1
                            }
                        }
                    case .label:
                        break
                    case .none:
                        break
                    }
                }
            }
            
            let languageName: String = UserDefaults.standard.object(forKey: "Language") as? String ?? "en"
            
            var matrixFile = MatrixFile()
            matrixFile.matrixType = "form"
            matrixFile.language = languageName
            matrixFile.name = form.name
            matrixFile.object = form
            
            let data = try JSONEncoder().encode(matrixFile)
            let jsonString = String(data: data, encoding: String.Encoding.utf8)!
            
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)
            let filename = form.name.replacingOccurrences(of: " ", with: "_")   + ".json"
            let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            return (url: fileURL, filename: filename)
        } catch {
            print(error)
        }
        
        return (url: URL(string: "")!, filename: "")
    }
    
    @IBAction func sendAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
        switch self.chatItemRequestViewModel.item.type {
        case .forms:
            if itemSelected.count > 0 {
                
                let json = exportFormJSON()
                
                DispatchQueue.global(qos: .background).async {
                    self.chatItemRequestViewModel.uploadFile(filename: json.filename, fileURL: json.url, success: { (response) in
                        
                        guard let url = response as? String else {
                            print("Error cast response to String")
                            return
                        }
                        
                        self.chatMessageViewModel.sendMessage(messageType: .file,
                                                              message: json.filename,
                                                              url: url,
                                                              success: { _ in
                                                                NotificationCenter.default.post(name: Notification.Name("UpdateMessages"), object: nil)
                        }, failure: { (response, object, error) in
                            print(error ?? "")
                        })
                    }, failure: { (response, object, error) in
                        print(error ?? "")
                    })
                }
            }
        case .checklists:
            
            if itemSelected.count > 0 {
                var shareItem = (filename: "", fileURL: URL(string: "file://")!)
                if itemSelected[0].section == 0 {
                    var checklistChecked: ChecklistChecked? = ChecklistChecked()
                    checklistChecked = self.chatItemRequestViewModel.favouriteChecklistChecked[itemSelected[0].row]
                    if let checklistChecked = checklistChecked {
                        shareItem = self.shareChecklist(checked: checklistChecked)
                    }
                    
                } else if itemSelected[0].section == 1 {
                    var checklistChecked: ChecklistChecked? = ChecklistChecked()
                    checklistChecked = self.chatItemRequestViewModel.checklistChecked[itemSelected[0].row]
                    if let checklistChecked = checklistChecked {
                        shareItem = self.shareChecklist(checked: checklistChecked)
                    }
                } else if itemSelected[0].section == 2 {
                    var customChecklist = self.chatItemRequestViewModel.customChecklists[itemSelected[0].row]
                    shareItem = self.shareCustomChecklist(customChecklist: customChecklist)
                }
                
//                DispatchQueue.global(qos: .background).async {
//                    self.chatItemRequestViewModel.uploadFile(filename: shareItem.filename, fileURL: shareItem.fileURL, success: { (response) in
//
//                        guard let url = response as? String else {
//                            print("Error cast response to String")
//                            return
//                        }
//
//                        self.chatMessageViewModel.sendMessage(messageType: .file,
//                                                              message: shareItem.filename,
//                                                              url: url,
//                                                              success: { _ in
//                                                                NotificationCenter.default.post(name: Notification.Name("UpdateMessages"), object: nil)
//                        }, failure: { (response, object, error) in
//                            print(error ?? "")
//                        })
//                    }, failure: { (response, object, error) in
//                        print(error ?? "")
//                    })
//                }
            }
        case .answers:
            break
        default:
            break
        }
        
    }
    
    func shareChecklist(checked: ChecklistChecked) -> (filename: String, fileURL: URL) {
        
        let checklist = self.checklistViewModel.getChecklist(checklistId: checked.checklistId)
        
        for checkItem in checklist.items {
            checkItem.answer = checkItem.checked ? 1 : 0
        }
        
        let languageName: String = UserDefaults.standard.object(forKey: "Language") as? String ?? "en"
        
        var matrixFile = MatrixFile()
        matrixFile.matrixType = "checklist"
        matrixFile.language = languageName
        matrixFile.name = checked.subCategoryName
        
        let difficulty = self.chatItemRequestViewModel.searchCategoryBy(id: checked.difficultyId)
        matrixFile.extra = difficulty?.name ?? ""
        matrixFile.object = checklist
        
        do {
            let data = try JSONEncoder().encode(matrixFile)
            let jsonString = String(data: data, encoding: String.Encoding.utf8)!
            
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)
            let filename = checked.subCategoryName.replacingOccurrences(of: " ", with: "_")   + ".json"
            let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            return (filename, fileURL)
        } catch {
            print(error)
        }
        
        return (filename: "", fileURL: URL(string: "")!)
    }
    
    func shareCustomChecklist(customChecklist: CustomChecklist) -> (filename: String, fileURL: URL) {
        
        let checklist = self.customChecklistViewModel.getCustomChecklist(checklistId: customChecklist.id)
        
        for checkItem in checklist.items {
            checkItem.answer = checkItem.checked ? 1 : 0
        }
        
        let languageName: String = UserDefaults.standard.object(forKey: "Language") as? String ?? "en"
        
        var matrixFile = MatrixFile()
        matrixFile.matrixType = "customChecklist"
        matrixFile.language = languageName
        matrixFile.name = checklist.name
        matrixFile.object = checklist
        
        do {
            let data = try JSONEncoder().encode(matrixFile)
            let jsonString = String(data: data, encoding: String.Encoding.utf8)!
            
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)
            let filename = checklist.name.replacingOccurrences(of: " ", with: "_")   + ".json"
            let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            return (filename, fileURL)
        } catch {
            print(error)
        }
        
        return (filename: "", fileURL: URL(string: "")!)
    }
}

// MARK: - UITableViewDataSource
extension ChatItemRequestViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        switch self.chatItemRequestViewModel.item.type {
        case .forms:
            return 1
        case .checklists:
            return 4
        case .answers:
            return 1
        default:
            return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.chatItemRequestViewModel.item.type {
        case .forms:
            return self.chatItemRequestViewModel.umbrella.loadFormAnswersByCurrentLanguage().count
        case .checklists:
            if section == 0 {
                return self.chatItemRequestViewModel.favouriteChecklistChecked.count
            } else if section == 1 {
                return self.chatItemRequestViewModel.checklistChecked.count
            } else if section == 2 {
                return self.chatItemRequestViewModel.customChecklists.count
            } else if section == 3 {
                return self.chatItemRequestViewModel.pathways.count
            }
            
            return 0
        case .answers:
            return 0
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatItemRequestCell = (tableView.dequeueReusableCell(withIdentifier: "ChatItemRequestCell", for: indexPath) as? ChatItemRequestCell)!
        cell.configure(withViewModel: self.chatItemRequestViewModel, indexPath: indexPath)
        cell.iconImageView.image = itemSelected.contains(indexPath) ? #imageLiteral(resourceName: "checkSelected") : #imageLiteral(resourceName: "groupNormal")
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension ChatItemRequestViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch self.chatItemRequestViewModel.item.type {
        case .forms:
            return 30
        case .checklists:
            return 30
        case .answers:
            return 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 30))
        view.backgroundColor = UIColor.white
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 30, height: 30))
        label.font = UIFont.init(name: "SFProText-SemiBold", size: 12)
        label.textColor = #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5764705882, alpha: 1)
        
        switch self.chatItemRequestViewModel.item.type {
        case .forms:
            label.text = "Active".localized()
            view.addSubview(label)
        case .checklists:
            if section == 0 {
                label.text = "Favourites".localized()
            } else if section == 1 {
                label.text = "My Checklists".localized()
            } else if section == 2 {
                label.text = "Custom Checklists".localized()
            } else if section == 3 {
                label.text = "Pathways".localized()
            }
            
            view.addSubview(label)
        case .answers:
            break
        default:
            break
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        itemSelected.removeAll()
        itemSelected.append(indexPath)
        tableView.reloadData()
    }
}
