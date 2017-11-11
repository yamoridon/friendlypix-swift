//
//  FPPost.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/10.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import Foundation
import STXDynamicTableView
import KZPropertyMapper
import FirebaseDatabase

class FPPost: NSObject, NSCoding, NSCopying, STXPostItem {
    @objc private var _postID: String?
    @objc private var _postDate: Date?
    @objc private var _imageURL: URL?
    @objc private var _link: URL?
    @objc private var _user: FPUser?
    @objc private var _text: String?
    @objc private var _comments: [FPComment]?
    @objc private var _likes: [String: Bool]?
    @objc private var _liked: Bool = false

    func postID() -> String? {
        return _postID
    }

    func postDate() -> Date? {
        return _postDate
    }

    func sharedURL() -> URL? {
        return _link
    }

    func photoURL() -> URL? {
        return _imageURL
    }

    func captionText() -> String? {
        return _text
    }

    func caption() -> [AnyHashable: Any]? {
        guard let text = _text else {
            return nil
        }
        return ["text": text]
    }

    func likes() -> [AnyHashable: Any] {
        return ["count": totalLikes()]
    }

    func liked() -> Bool {
        return _liked
    }

    func comments() -> [Any]? {
        return _comments
    }

    func totalLikes() -> Int {
        guard let userId = FPAppState.sharedInstance.currentUser?.userID() else {
            return 0
        }
        guard let likes = _likes else {
            return 0
        }
        var totalLikes = likes.count
        if _liked && (likes[userId] ?? false) {
            totalLikes += 1
        } else if (!_liked && !(likes[userId] ?? false)) {
            totalLikes -= 1
        }
        return max(0, totalLikes)
    }

    func totalComments() -> Int {
        return _comments?.count ?? 0
    }

    func user() -> STXUserItem? {
        return _user
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(_postID, forKey: "postID")
        aCoder.encode(_postDate, forKey: "postDate")
        aCoder.encode(_imageURL, forKey: "imageURL")
        aCoder.encode(_link, forKey: "link")
        aCoder.encode(_comments, forKey: "comments")
        aCoder.encode(_likes, forKey: "likes")

    }

    required init?(coder aDecoder: NSCoder) {
        _postID = aDecoder.decodeObject(forKey: "postID") as? String
        _postDate = aDecoder.decodeObject(forKey: "postDate") as? Date
        _imageURL = aDecoder.decodeObject(forKey: "imageURL") as? URL
        _link = aDecoder.decodeObject(forKey: "link") as? URL
        _comments = aDecoder.decodeObject(forKey: "comments") as? [FPComment]
        _likes = aDecoder.decodeObject(forKey: "likes") as? [String: Bool]
        _user = aDecoder.decodeObject(forKey: "user") as? FPUser
        _text = aDecoder.decodeObject(forKey: "text") as? String
        _liked = aDecoder.decodeBool(forKey: "liked")
    }

    init(post: FPPost) {
        _postID = post._postID
        _postDate = post._postDate
        _imageURL = post._imageURL
        _link = post._link
        _comments = post._comments
        _likes = post._likes
        if let user = post._user {
            _user = FPUser(user: user)
        } else {
            _user = nil
        }
        _text = post._text
        _liked = post._liked
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return FPPost(post: self)
    }

    init(dictionary: [AnyHashable: Any]?) {
        super.init()
        guard let dictionary = dictionary else {
            return
        }
        let mappingDictionary: [AnyHashable: Any] = [
            "text": KZPropertyDescriptor(propertyName: "_text", andMapping: nil),
            "full_url": KZPropertyDescriptor(propertyName: "_imageURL", andMapping: "URL"),
            "timestamp": KZPropertyDescriptor(propertyName: "_postDate", andMapping: "Date"),
        ]
        KZPropertyMapper.mapValues(from: NSDictionary(dictionary: dictionary), toInstance: self, usingMapping: mappingDictionary)
        if let author = dictionary["author"] as? [AnyHashable: Any] {
            _user = FPUser(dictionary: author)
        }
    }

    convenience init(snapshot: DataSnapshot, andComments comments: [FPComment]) {
        self.init(dictionary: snapshot.value as? [AnyHashable: Any])
        _postID = snapshot.key
        _comments = comments
        if let userID = FPAppState.sharedInstance.currentUser?.userID(), let likes = _likes {
            _liked = likes[userID] ?? false
        } else {
            _liked = false
        }
    }

    override var hash: Int {
        return _postID?.hash ?? 0
    }

    func isEqualToPost(_ post: FPPost) -> Bool {
        if let left = self._postID, let right = post._postID, left == right {
            return true
        } else {
            return false
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? FPPost else {
            return false
        }

        if self === object {
            return true
        }

        return isEqualToPost(object)
    }

    override var description: String {
        let dictionary = [
            "postID": _postID ?? "",
            "postDate": _postDate?.description ?? "",
            "sharedURL": sharedURL()?.description ?? "",
        ]
        return String(format: "<%@: %p> %@>", NSStringFromClass(type(of: self)), self, dictionary)
    }

}
