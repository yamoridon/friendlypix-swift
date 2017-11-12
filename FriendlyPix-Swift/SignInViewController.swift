//
//  SignInViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI

fileprivate let facebookAppID = "FACEBOOK_APP_ID"
fileprivate let firebaseTermsOfService = "https://firebase.google.com/terms/"

class SignInViewController: UIViewController, FUIAuthDelegate {

    var authUI: FUIAuth!
    var firstTime = true

    override func viewDidLoad() {
        super.viewDidLoad()

        authUI = FUIAuth.defaultAuthUI()
        authUI.delegate = self
        authUI.tosurl = URL(string: firebaseTermsOfService)
        authUI.isSignInWithEmailHidden = false
        authUI.providers = [FUIGoogleAuth(), FUIFacebookAuth()]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if firstTime {
            firstTime = false
            presentAuthViewController()
        }
    }

    func presentAuthViewController() {
        let authViewController = authUI.authViewController()
        authViewController.navigationBar.isHidden = true
        present(authViewController, animated: true)
    }

    // MARK: - FUIAuthDelegate

    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if let error = error as NSError? {
            if error.code == FUIAuthErrorCode.userCancelledSignIn.rawValue {
                print("User cancelled sign-in")
            } else {
                let errorDescription: String
                if let detailedError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    errorDescription = detailedError.localizedDescription
                } else {
                    errorDescription = error.localizedDescription
                }
                print("ERROR: \(errorDescription)")
            }
            presentAuthViewController()
        } else if let user = user {
            signedIn(user)
        }
    }

    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        return FPAuthPickerViewController(nibName: "FPAuthPickerViewController", bundle: Bundle.main, authUI: authUI)
    }

    // MARK: -

    func signedIn(_ user: User) {
        let ref = Database.database().reference()
        let peopleRef = ref.child("people/\(user.uid)")
        peopleRef.observeSingleEvent(of: .value) { [weak self] peopleSnapshot in
            guard let `self` = self else {
                return
            }
            if peopleSnapshot.exists() {
                FPAppState.sharedInstance.currentUser = FPUser(snapshot: peopleSnapshot)
            } else {
                let person: [AnyHashable: Any] = [
                    "full_name": user.displayName ?? "",
                    "profile_picture": user.photoURL?.absoluteString ?? "",
                    "_search_index": [
                        "full_name": user.displayName ?? "",
                        "reversed_full_name": user.displayName?.components(separatedBy: " ").reversed().joined(separator: " ") ?? ""
                    ]
                ]
                peopleRef.setValue(person)
                FPAppState.sharedInstance.currentUser = FPUser(dictionary: person)
                FPAppState.sharedInstance.currentUser?.setUserID(user.uid)
            }
            self.firstTime = true
            self.performSegue(withIdentifier: "SignInToFP", sender: self)
        }
    }

}
