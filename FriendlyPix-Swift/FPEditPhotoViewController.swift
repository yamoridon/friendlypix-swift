//
//  FPEditPhotoViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class FPEditPhotoViewController: UIViewController, UITextFieldDelegate {

    var image: UIImage?

    private var storageRef: StorageReference!
    private var postRef: DatabaseReference?
    private var imageURL: String?
    private var storageURI: String?

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var commentTextField: UITextField!

    // MARK: - UIViewControlle

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        storageRef = Storage.storage().reference()
        _ = shouldUploadImage(image)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneButtonAction(nil)
        textField.resignFirstResponder()
        return true
    }

    // MARK: -

    func shouldUploadImage(_ image: UIImage?) -> Bool {
        guard let image = image else {
            return false
        }
        guard let data = UIImageJPEGRepresentation(image, 0.75) else {
            return false
        }
        guard let userID = FPAppState.sharedInstance.currentUser?.userID() else {
            return false
        }
        postRef = Database.database().reference().child("posts").childByAutoId()
        guard let key = postRef?.key else {
            return false
        }
        let filePath = "\(userID)/\(key)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        self.storageRef.child(filePath).putData(data, metadata: metadata) { [weak self] metadata, error in
            if let error = error {
                print("Error uploading: \((error as NSError).description)")
                return
            }
            guard let `self` = self, let metadata = metadata, let path = metadata.path, let url = metadata.downloadURLs?.first else {
                return
            }
            self.imageURL = url.absoluteString
            self.storageURI = self.storageRef.child(path).description
        }

        return true
    }

    @IBAction func doneButtonAction(_ sender: UIBarButtonItem?) {
        guard let postRef = postRef else {
            return
        }
        guard let currentUser = FPAppState.sharedInstance.currentUser else {
            return
        }
        guard let userID = currentUser.userID() else {
            return
        }
        // Push data to Firebase Database
        let trimmedComment = commentTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let data: [AnyHashable: Any] = [
            "image_url": imageURL ?? "",
            "storage_uri": storageURI ?? "",
            "text": trimmedComment,
            "author": currentUser.author(),
            "timestamp": ServerValue.timestamp()
        ]
        postRef.setValue(data)
        let postID = postRef.key
        postRef.root.updateChildValues([
            "people/\(userID)/posts/\(postID)": true,
            "feed/\(userID)/\(postID)": true
        ])
        parent?.dismiss(animated: true)
    }

    @IBAction func cancelbuttonAction(_ sender: UIBarButtonItem?) {
        parent?.dismiss(animated: true)
    }
}
