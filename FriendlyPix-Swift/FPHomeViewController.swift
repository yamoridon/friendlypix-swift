//
//  FPHomeViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/12.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseDatabase

class FPHomeViewController: FPPhotoTimelineViewController {

    override func loadData() {
        guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        query = ref.child("feed").child(currentUserID)
        // Make sure the home feed is updated with followed users's new posts.
        // Only after the feed creation is complete, start fetching the posts.
        updateHomeFeeds()
    }

    func getHomeFeedPosts() {
        loadFeed(nil)
    }

    override func loadItem(_ item: DataSnapshot) {
        ref.child("posts/\(item.key)").observe(.value) { [weak self] snapshot in
            self?.loadPost(snapshot)
        }
    }

    // Keeps the home feed populated with latest followed users' posts live.
    func startHomeFeedLiveUpdaters() {
        guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }

        // Make sure we listen on each followed people's posts.
        let followingRef = ref.child("people").child(currentUserID).child("following")
        followingRef.observe(.childAdded) { [weak self] followingSnapshot in
            guard let `self` = self else {
                return
            }
            // Start listening the followed user's posts to populate the home feed.
            let followedUID = followingSnapshot.key
            var followedUserPostsRef: DatabaseQuery = self.ref.child("people").child(followedUID).child("posts")
            if followingSnapshot.exists() && followingSnapshot.value is String {
                followedUserPostsRef = followedUserPostsRef.queryOrderedByKey().queryStarting(atValue: followingSnapshot.value)
            }
            followedUserPostsRef.observe(.childAdded) { postSnapshot in
                if postSnapshot.key != followingSnapshot.key {
                    let updates: [AnyHashable: Any] = [
                        "/feed/\(currentUserID)/\(postSnapshot.key)": true,
                        "/people/\(currentUserID)/following/\(followedUID)": postSnapshot.key
                    ]
                    self.ref.updateChildValues(updates)
                }
            }
        }

        // Stop listening to users we unfollow.
        followingRef.observe(.childRemoved) { [weak self] snapshot in
            // Stop listening the followed user's posts to populate the home feed.
            let followedUserID = snapshot.key
            self?.ref.child("people").child(followedUserID).child("posts").removeAllObservers()
        }
    }

    // Updates the home feed with new followed users' posts and returns a promise once that's done.
    func updateHomeFeeds() {
        guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        // Make sure we listen on each followed people's posts.
        let followingRef = ref.child("people").child(currentUserID).child("following")
        followingRef.observe(.value) { [weak self] followingSnapshot in
            guard let `self` = self else {
                return
            }
            // Start listening the followed user's posts to populate the home feed.
            guard let following = followingSnapshot.value as? [String: Any] else {
                return
            }
            following.forEach { followedUID, lastSyncedPostID in
                var followedUserPostsRef: DatabaseQuery = self.ref.child("people").child(followedUID).child("posts")
                if lastSyncedPostID is String {
                    followedUserPostsRef = followedUserPostsRef.queryOrderedByKey().queryStarting(atValue: lastSyncedPostID)
                }
                followedUserPostsRef.observeSingleEvent(of: .value) { postSnapshot in
                    guard let postArray = postSnapshot.value as? [String: Any] else {
                        return
                    }
                    var updates = [AnyHashable: Any]()
                    postArray.forEach { postID, _ in
                        if !(lastSyncedPostID is String) || ((lastSyncedPostID as! String) != postID) {
                            updates["/feed/\(currentUserID)/\(postID)"] = true
                            updates["/people/\(currentUserID)/following/\(followedUID)"] = postID
                        }
                    }
                    self.ref.updateChildValues(updates)

                    // Add new posts from followers live.
                    self.startHomeFeedLiveUpdaters()
                    // Get home feed posts
                    self.getHomeFeedPosts()
                }
            }
        }
    }
}
