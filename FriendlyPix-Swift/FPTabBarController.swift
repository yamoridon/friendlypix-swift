//
//  FPTabBarController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseAuth
import MobileCoreServices

protocol FPTabBarControllerDelegate: class {
    func tabBarController(_ tabBarController: UITabBarController, cameraButtonTouchUpInsideAction button: UIButton)
}

class FPTabBarController: UITabBarController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {

    // MARK: - UITabBarController
    override func viewDidLoad() {
        super.viewDidLoad()

        let cameraButton = UIButton(type: .custom)
        cameraButton.setImage(#imageLiteral(resourceName: "ButtonCamera"), for: .normal)
        cameraButton.setImage(#imageLiteral(resourceName: "ButtonCameraSelected"), for: .highlighted)
        cameraButton.imageView?.contentMode = .scaleAspectFit
        tabBar.addSubview(cameraButton)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor).isActive = true
        if #available(iOS 11, *) {
            cameraButton.topAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.topAnchor).isActive = true
            cameraButton.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            cameraButton.topAnchor.constraint(equalTo: tabBar.topAnchor).isActive = true
            cameraButton.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor).isActive = true
        }
        cameraButton.addTarget(self, action: #selector(FPTabBarController.photoCaptureButtonAction(_:)), for: .touchUpInside)

        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(FPTabBarController.handleGesture(_:)))
        swipeUpGestureRecognizer.direction = .up
        swipeUpGestureRecognizer.numberOfTouchesRequired = 1
        cameraButton.addGestureRecognizer(swipeUpGestureRecognizer)
    }

    // MARK: - UIImagePickerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: false)
        performSegue(withIdentifier: "edit", sender: info)
    }

    // MARK: - UIActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {
            _ = shouldStartCameraController()
        } else if buttonIndex == 2 {
            _ = shouldStartPhotoLibraryPickerController()
        }
    }

    // MARK: - PAPTabBarController
    func shouldPresentPhotoCaptureController() -> Bool {
        var presentedPhotoCaptureController = shouldStartCameraController()
        if !presentedPhotoCaptureController {
            presentedPhotoCaptureController = shouldStartPhotoLibraryPickerController()
        }
        return presentedPhotoCaptureController
    }

    // MARK: - ()
    @objc func photoCaptureButtonAction(_ button: UIButton) {
        let cameraDeviceAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)

        if cameraDeviceAvailable && photoLibraryAvailable {
            let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Take Photo", "Choose Photo")
            actionSheet.show(from: tabBar)
        } else {
            // if we don't have at least two options, we automatically show whichever is available (camera or roll)
            _ = shouldPresentPhotoCaptureController()
        }
    }

    func shouldStartCameraController() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return false
        }

        let cameraUI = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) && UIImagePickerController.availableMediaTypes(for: .camera)!.contains(kUTTypeImage as String) {
            cameraUI.mediaTypes = [kUTTypeImage as String]
            cameraUI.sourceType = .camera

            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                cameraUI.cameraDevice = .rear
            } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                cameraUI.cameraDevice = .front
            }
        } else {
            return false
        }

        cameraUI.allowsEditing = true
        cameraUI.showsCameraControls = true
        cameraUI.delegate = self

        present(cameraUI, animated: true)

        return true
    }

    func shouldStartPhotoLibraryPickerController() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            return false
        }

        let cameraUI = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) && UIImagePickerController.availableMediaTypes(for: .photoLibrary)!.contains(kUTTypeImage as String) {
            cameraUI.sourceType = .photoLibrary
            cameraUI.mediaTypes = [kUTTypeImage as String]
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) && UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum)!.contains(kUTTypeImage as String) {
            cameraUI.sourceType = .savedPhotosAlbum
            cameraUI.mediaTypes = [kUTTypeImage as String]
        } else {
            return false
        }

        cameraUI.allowsEditing = true
        cameraUI.delegate = self

        present(cameraUI, animated: true)

        return true
    }

    @objc func handleGesture(_ gesture: UIGestureRecognizer) {
        _ = shouldPresentPhotoCaptureController()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "edit", let sender = sender as? [String : Any] {
            let navigationController = segue.destination as! UINavigationController
            let viewController = navigationController.topViewController as! FPEditPhotoViewController
            viewController.image = sender[UIImagePickerControllerEditedImage] as? UIImage
        }
    }

    @IBAction func didTapSignOut(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
        } catch let error as NSError {
            print("Error signing out: \(error)")
        }
        parent?.dismiss(animated: true)
    }
}
