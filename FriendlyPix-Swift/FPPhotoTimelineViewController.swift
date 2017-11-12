//
//  FPPhotoTimelineViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GoogleMobileAds
import STXDynamicTableView

let photoCellRow = 0

class FPPhotoTimelineViewController: UITableViewController, STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate {

    var ref: DatabaseReference!
    var postsRef: DatabaseReference!
    var commentsRef: DatabaseReference!
    var likesRef: DatabaseReference!
    var query: DatabaseReference?

    private var tableViewDataSource: STXFeedTableViewDataSource!
    private var tableViewDelegate: STXFeedTableViewDelegate!
    private var posts = [FPPost]()
    private var loadingPostCount = 0

    deinit {
        // To prevent crash when popping this from navigation controller
        tableView.delegate = nil
        tableView.dataSource = nil
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(FPPhotoTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl!)

        ref = Database.database().reference()
        postsRef = ref.child("posts")
        commentsRef = ref.child("comments")
        likesRef = ref.child("likes")

        tableView.separatorStyle = .none

        let dataSource = STXFeedTableViewDataSource(controller: self, tableView: tableView)
        tableView.dataSource = dataSource
        tableViewDataSource = dataSource

        let delegate = STXFeedTableViewDelegate(controller: self)
        tableView.delegate = delegate
        tableViewDelegate = delegate

        loadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // This will be notified when the Dynamic Type user setting changes (from the system Settings app)
        NotificationCenter.default.addObserver(self, selector: #selector(FPPhotoTimelineViewController.contentSizeCategoryChanged(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIContentSizeCategoryDidChange, object: nil)
    }

    // MARK: -

    @objc func refreshControlValueChanged(_ sender: UIRefreshControl) {
        loadData()
        refreshControl!.endRefreshing()
    }

    @objc func contentSizeCategoryChanged(_ notification: Notification) {
        tableView.reloadData()
    }

    func loadData() {
        query = postsRef
        posts.removeAll()
        tableViewDataSource.posts = posts
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            self?.loadFeed(nil)
        }
    }

    func loadItem(_ item: DataSnapshot) {
        loadPost(item)
    }

    func loadFeed(_ earliestEntryID: String?) {
        guard let queryRef = self.query else {
            return
        }
        let query: DatabaseQuery
        if let earliestEntryID = earliestEntryID {
            query = queryRef.queryOrderedByKey().queryEnding(atValue: earliestEntryID)
        } else {
            query = queryRef.queryOrderedByKey()
        }
        loadingPostCount += 6
        query.queryLimited(toLast: 6).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let `self` = self else {
                return
            }
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                return
            }
            if earliestEntryID != nil {
                children.reversed().dropFirst().forEach({ self.loadItem($0) })
            } else {
                children.reversed().forEach({ self.loadItem($0) })
            }
        }
        postsRef.observe(.childRemoved) { [weak self] postSnapshot in
            guard let `self` = self else {
                return
            }
            let post = FPPost(snapshot: postSnapshot, andComments: nil)
            self.posts = self.posts.filter({ !$0.isEqualToPost(post) })
            self.tableViewDataSource.posts = self.posts
            self.tableView.deleteSections(IndexSet(integer: self.tableViewDataSource.posts.count), with: .none)
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == loadingPostCount - 1 && indexPath.row == 0 {
            if let photoCell = cell as? STXFeedPhotoCell {
                loadFeed(photoCell.postItem.postID())
            }
        }
    }

    func loadPost(_ postSnapshot: DataSnapshot) {
        commentsRef.child(postSnapshot.key).observe(.value) { [weak self] commentsSnapshot in
            guard let `self` = self else {
                return
            }
            guard let currentUserID = FPAppState.sharedInstance.currentUser?.userID() else {
                return
            }
            let comments = commentsSnapshot.children.allObjects.flatMap({ $0 as? DataSnapshot }).map({ FPComment(snapshot: $0) })
            self.likesRef.child(postSnapshot.key).observeSingleEvent(of: .value) { snapshot in
                let post = FPPost(snapshot: postSnapshot, andComments: comments)
                if let likes = snapshot.value as? [AnyHashable: Any] {
                    post.setLikes(likes)
                    post.setLiked(likes[currentUserID] != nil)
                } else {
                    post.setLikes([:])
                    post.setLiked(false)
                }
                var replaced = false
                for i in 0 ..< self.posts.count {
                    if (self.posts[i].postID() ?? "") == (post.postID() ?? "") {
                        self.posts[i] = post
                        replaced = true
                        break
                    }
                }
                if !replaced {
                    self.posts.append(post)
                    self.posts.sort(by: { $0.postDate()! > $1.postDate()! })
                }
                self.tableViewDataSource.posts = self.posts
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - STXUserActionDelegate

    func userDidLike(_ userActionCell: STXUserActionCell!) {
        guard let postItem = userActionCell.postItem as? FPPost else {
            return
        }
        guard let postID = postItem.postID() else {
            return
        }
        guard let userID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        ref.child("likes/\(postID)/\(userID)").setValue(ServerValue.timestamp()) { [weak self] error, ref in
            if error != nil {
                print("error in syncing like")
                return
            }
            postItem.setLiked(true)
            self?.tableView.reloadRows(at: [userActionCell.indexPath], with: .none)
        }
    }

    func userDidUnlike(_ userActionCell: STXUserActionCell!) {
        guard let postItem = userActionCell.postItem as? FPPost else {
            return
        }
        guard let postID = postItem.postID() else {
            return
        }
        guard let userID = FPAppState.sharedInstance.currentUser?.userID() else {
            return
        }
        ref.child("likes/\(postID)/\(userID)").removeValue { [weak self] error, ref in
            if error != nil {
                print("error in syncing unlike")
                return
            }
            postItem.setLiked(false)
            self?.tableView.reloadRows(at: [userActionCell.indexPath], with: .none)
        }
    }

    func userWillComment(_ userActionCell: STXUserActionCell!) {
        let postItem = userActionCell.postItem
        // Present comment view controller
        performSegue(withIdentifier: "comment", sender: postItem)
    }

    func userWillShare(_ userActionCell: STXUserActionCell!) {
        guard let postItem = userActionCell.postItem else {
            return
        }
        let photoCellIndexPath = IndexPath(row: photoCellRow, section: userActionCell.indexPath.section)
        let photoCell = tableView.cellForRow(at: photoCellIndexPath) as? STXFeedPhotoCell
        let photoImage = photoCell?.photoImage
        share(photoImage, text: postItem.captionText(), url: postItem.sharedURL())
    }

    // MARK: - STXFeedPhotoCellDelegate

    func feedCellWillShowPoster(_ poster: STXUserItem!) {
        if self is FPAccountViewController {
            let anim = CAKeyframeAnimation(keyPath: "transform")
            anim.values = [
                NSValue(caTransform3D: CATransform3DMakeTranslation(-5.0, 0.0, 0.0)),
                NSValue(caTransform3D: CATransform3DMakeTranslation(5.0, 0.0, 0.0))
            ]
            anim.autoreverses = true
            anim.repeatCount = 2.0
            anim.duration = 0.07
            view.layer.add(anim, forKey: nil)
        } else {
            performSegue(withIdentifier: "account", sender: poster)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "account" {
            if let accountViewController = segue.destination as? FPAccountViewController {
                accountViewController.user = sender as? FPUser
            }
        } else if segue.identifier == "comment" {
            if let commentViewController = segue.destination as? FPCommentViewController {
                commentViewController.post = sender as? FPPost
            }
        }
    }

}

