//
//  FPComment.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/09.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import Foundation
import FirebaseDatabase
import KZPropertyMapper

class FPComment: NSObject, NSCoding, NSCopying {
    @objc private var _commentID: String?
    @objc private var _text: String?
    @objc private var _postDate: Date?
    @objc private var _from: FPUser?

    func commentID() -> String? {
        return _commentID
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(_commentID, forKey: "commentID")
        aCoder.encode(_text, forKey: "text")
        aCoder.encode(_postDate, forKey: "postDate")
        aCoder.encode(_from, forKey: "from")
    }

    required init?(coder aDecoder: NSCoder) {
        _commentID = aDecoder.decodeObject(forKey: "commentID") as? String
        _text = aDecoder.decodeObject(forKey: "text") as? String
        _postDate = aDecoder.decodeObject(forKey: "postDate") as? Date
        _from = aDecoder.decodeObject(forKey: "from") as? FPUser
    }

    init(comment: FPComment) {
        _commentID = comment._commentID
        _text = comment._text
        _postDate = comment._postDate
        if let from = comment._from {
            _from = FPUser(user: from)
        } else {
            _from = nil
        }
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return FPComment(comment: self)
    }

    init(dictionary: [AnyHashable: Any]?) {
        super.init()
        guard let dictionary = dictionary else {
            return
        }
        let mappingDictionary: [AnyHashable: Any] = [
            "text": KZPropertyDescriptor(propertyName: "_text", andMapping: nil),
            "timestamp": KZPropertyDescriptor(propertyName: "_postDate", andMapping: "Date"),
        ]
        KZPropertyMapper.mapValues(from: NSDictionary(dictionary: dictionary), toInstance: self, usingMapping: mappingDictionary)
        if let author = dictionary["author"] as? [AnyHashable: Any] {
            _from = FPUser(dictionary: author)
        }
    }

    convenience init(snapshot: DataSnapshot) {
        self.init(dictionary: snapshot.value as? [AnyHashable: Any])
        _commentID = snapshot.key
    }

    override var hash: Int {
        return _commentID?.hash ?? 0
    }

    func isEqualToComment(_ comment: FPComment) -> Bool {
        if let left = self._commentID, let right = comment._commentID, left == right {
            return true
        } else {
            return false
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? FPComment else {
            return false
        }

        if self === object {
            return true
        }

        return isEqualToComment(object)
    }

    override var description: String {
        let dictionary = [
            "commentID": _commentID ?? "",
            "from": _from?.username() ?? "",
            "text": _text ?? "",
        ]
        return String(format: "<%@: %p> %@>", NSStringFromClass(type(of: self)), self, dictionary)
    }

}
