//
//  FPCommentViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/12.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseDatabase
import STXDynamicTableView

class FPCommentViewController: UITableViewController, UITextFieldDelegate, STXCommentCellDelegate {

    var hideDropShadow = false
    var post: FPPost?

    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var footerView: UIView!

    private var comments = [FPComment]()

    override func viewDidLoad() {
        if let comments = post?.comments() as? [FPComment] {
            self.comments = comments
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = comments[indexPath.row]
        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? STXCommentCell
        if cell == nil {
            cell = STXCommentCell(style: .singleComment, comment: comment, reuseIdentifier: cellIdentifier)
        } else {
            cell!.comment = comment
        }
        cell!.delegate = self
        cell!.setNeedsUpdateConstraints()
        cell!.updateConstraintsIfNeeded()

        return cell!
    }

    @IBAction func didSendComment(_ sender: Any) {
        _ = textFieldShouldReturn(commentField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let postID = post?.postID() else {
            return false
        }
        guard let author = FPAppState.sharedInstance.currentUser?.author() else {
            return false
        }
        let data: [AnyHashable: Any] = [
            "timestamp": ServerValue.timestamp(),
            "author": author,
            "text": textField.text ?? ""
        ]
        // Push data to Firebase Database
        let ref = Database.database().reference()
        let comment = ref.child("comments/\(postID)").childByAutoId()
        comment.setValue(data) { [weak self] error, ref in
            guard let `self` = self else {
                return
            }
            guard error == nil else {
                print("comment push error")
                return
            }
            ref.observe(.value) { snapshot in
                self.comments.append(FPComment(snapshot: snapshot))
                self.tableView.insertRows(at: [IndexPath(row: self.comments.count - 1, section: 0)], with: .none)
            }
        }
        textField.text = ""
        return true
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.footerView
    }
}
