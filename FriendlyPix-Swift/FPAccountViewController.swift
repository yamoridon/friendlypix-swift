//
//  FPAccountViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/12.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit

class FPAccountViewController: FPPhotoTimelineViewController {

    var user: FPUser?

    @IBOutlet private weak var photoCountLabel: UILabel!
    @IBOutlet private weak var followerCountLabel: UILabel!
    @IBOutlet private weak var followingCountLabel: UILabel!
    @IBOutlet private weak var profilePictureImageView: UIImageView!

    private var postCount = 0
    private var followers: [AnyHashable: Any]?
    private var followingCount = UInt(0)

    override func loadData() {
        guard let userID = user?.userID() else {
            return
        }
        ref.child("people").child(userID).observe(.value) { [weak self] userSnapshot in
            guard let `self` = self else {
                return
            }
            let posts = userSnapshot.childSnapshot(forPath: "posts").value as? [String: Any]
            self.followingCount = userSnapshot.childSnapshot(forPath: "following").childrenCount
            if let posts = posts {
                self.postCount = posts.count
                for (postID, _) in posts {
                    self.ref.child("posts/\(postID)").observe(.value) { postSnapshot in
                        self.loadPost(postSnapshot)
                    }
                }
            } else {
                self.postCount = 0
            }
            self.feedDidLoad()
        }
        ref.child("followers").child(userID).observe(.value) { [weak self] snapshot in
            guard let `self` = self else {
                return
            }
            self.followers = snapshot.value as? [AnyHashable: Any]
            if let followers = self.followers {
                let followersCount = followers.count
                self.followerCountLabel.text = "\(followersCount) follower\(followersCount == 1 ? "" : "s")"
            }
        }

        if let profilePictureURL = user?.profilePictureURL() {
            profilePictureImageView.setCircleImageWith(profilePictureURL, placeholderImage: #imageLiteral(resourceName: "PlaceholderPhoto"))
        }

    }

    func feedDidLoad() {
        guard let user = user, let userID = user.userID() else {
            return
        }
        guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        navigationItem.title = user.username()
        photoCountLabel.text = "\(postCount) post\(postCount == 1 ? "" : "s")"
        followingCountLabel.text = "\(followingCount) following"

        if userID != currentUserID {
            let loadingActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            loadingActivityIndicator.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicator)

            // check if the currentUser is following this user
            if let followers = followers, followers[currentUserID] != nil {
                configureUnfollowButton()
            } else {
                configureFollowButton()
            }
        }
    }

    @objc func followButtonAction(_ sender: Any) {
        guard let userID = user?.userID() else {
            return
        }
        guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        loadingActivityIndicatorView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
        let myFeed = ref.child("feed/\(currentUserID)")
        ref.child("people/\(userID)/posts").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let `self` = self else {
                return
            }
            guard let feeds = snapshot.value as? [String: Bool] else {
                return
            }
            var lastPostID = ""
            for postID in feeds.keys {
                myFeed.child(postID).setValue(true)
                lastPostID = postID
            }
            self.ref.updateChildValues([
                "followers/\(userID)/\(currentUserID)": lastPostID,
                "people/\(currentUserID)/following/\(userID)": true
            ])
            self.configureUnfollowButton()
        }
    }

    @objc func unfollowButtonAction(_ sender: Any) {
        guard let userID = user?.userID() else {
            return
        }
        guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        let loadingActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        loadingActivityIndicator.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicator)
        let myFeed = ref.child("feed/\(currentUserID)")
        ref.child("people/\(userID)/posts").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let postIDs = snapshot.value as? [String] else {
                return
            }
            postIDs.forEach({ myFeed.child($0).removeValue() })
            self?.ref.updateChildValues([
                "followers/\(currentUserID)/\(userID)": NSNull(),
                "people/\(currentUserID)/\(userID)": NSNull()
            ])
        }
    }

    func configureFollowButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Follow", style: .plain, target: self, action: #selector(FPAccountViewController.followButtonAction(_:)))
    }

    func configureUnfollowButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unfollow", style:. plain, target: self, action: #selector(FPAccountViewController.unfollowButtonAction(_:)))
    }

}
