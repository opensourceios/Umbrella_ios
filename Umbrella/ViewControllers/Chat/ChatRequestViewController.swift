//
//  ChatRequestViewController.swift
//  Umbrella
//
//  Created by Lucas Correa on 01/07/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import UIKit

class ChatRequestViewController: UIViewController {
    
    //
    // MARK: - Properties
    lazy var chatRequestViewModel: ChatRequestViewModel = {
        let chatRequestViewModel = ChatRequestViewModel()
        return chatRequestViewModel
    }()
    
    lazy var chatItemRequestViewModel: ChatItemRequestViewModel = {
        let chatItemRequestViewModel = ChatItemRequestViewModel()
        return chatItemRequestViewModel
    }()
    
    lazy var chatMessageViewModel: ChatMessageViewModel = {
        let chatMessageViewModel = ChatMessageViewModel()
        return chatMessageViewModel
    }()
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    var isAllChat: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        self.preferredContentSize = CGSize(width: 300, height: 250)
        self.navigationController!.navigationBar.tintColor = UIColor.white
        self.chatRequestViewModel.loadItems()
        self.chatItemRequestViewModel.userLogged = self.chatRequestViewModel.userLogged
        self.chatMessageViewModel.userLogged = self.chatRequestViewModel.userLogged
        self.chatMessageViewModel.room = self.chatRequestViewModel.room
    }
    
    // MARK: - UIStoryboardSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "itemRequestSegue" {
            let chatItemRequestViewController = (segue.destination as? ChatItemRequestViewController)!
            let item = self.chatRequestViewModel.items[(sender as? Int)!]
            chatItemRequestViewController.chatItemRequestViewModel.item = item
            chatItemRequestViewController.chatItemRequestViewModel.userLogged = self.chatRequestViewModel.userLogged
            chatItemRequestViewController.chatMessageViewModel.userLogged = self.chatRequestViewModel.userLogged
            chatItemRequestViewController.chatMessageViewModel.room = self.chatRequestViewModel.room
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDataSource
extension ChatRequestViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAllChat {
            return self.chatRequestViewModel.items.count
        } else {
            return self.chatRequestViewModel.items.count - 1
        }
        
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatRequestCell = (tableView.dequeueReusableCell(withIdentifier: "ChatRequestCell", for: indexPath) as? ChatRequestCell)!
        
        cell.configure(withViewModel: self.chatRequestViewModel, indexPath: indexPath)
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension ChatRequestViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.chatRequestViewModel.items[indexPath.row]
        
        if item.type == ChatRequestType.file {
            self.dismiss(animated: true, completion: nil)
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
            documentPicker.delegate = self
            UIApplication.shared.delegate!.window?!.rootViewController!.present(documentPicker, animated: true, completion: nil)
        } else if item.type == ChatRequestType.invite {
//            NavigationChatInviteUser
            self.dismiss(animated: true, completion: nil)
            let storyboard = UIStoryboard(name: "Chat", bundle: Bundle.main)
            let navigationChatInviteUser = (storyboard.instantiateViewController(withIdentifier: "NavigationChatInviteUser") as? UINavigationController)!
            
            let chatInviteUserViewController = (navigationChatInviteUser.viewControllers.first! as? ChatInviteUserViewController)!
            chatInviteUserViewController.chatInviteUserViewModel.roomId = self.chatRequestViewModel.room.roomId!
            UIApplication.shared.keyWindow?.rootViewController!.present(navigationChatInviteUser, animated: true)
        } else {
            self.performSegue(withIdentifier: "itemRequestSegue", sender: indexPath.row)
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension ChatRequestViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print(url)
        print(url.lastPathComponent)
        let filename = url.lastPathComponent
        DispatchQueue.global(qos: .background).async {
            self.chatItemRequestViewModel.uploadFile(filename: filename, fileURL: url, success: { (response) in
                
                guard let url = response as? String else {
                    print("Error cast response to String")
                    return
                }
                
                self.chatMessageViewModel.sendMessage(messageType: .file,
                                                      message: filename,
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
}