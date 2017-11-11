//
//  FPUser.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/08.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import Foundation
import Firebase
import STXDynamicTableView
import KZPropertyMapper

class FPUser: NSObject, NSCoding, NSCopying, STXUserItem {
    @objc private var _userID: String?
    @objc private var _fullname: String?
    @objc private var _profilePictureURL: URL?

    func userID() -> String? {
        return _userID
    }

    func setUserID(_ userID: String?) {
        _userID = userID
    }

    func username() -> String? {
        return _fullname
    }
    
    func fullname() -> String? {
        return _fullname
    }
    
    func profilePictureURL() -> URL? {
        return _profilePictureURL
    }

    func author() -> [String: String] {
        return [
            "uid": _userID ?? "",
            "full_name": _fullname ?? "",
            "profile_picture": _profilePictureURL?.absoluteString ?? ""
        ]
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(_userID, forKey: "userID")
        aCoder.encode(_fullname, forKey: "fullname")
        aCoder.encode(_profilePictureURL, forKey: "profilePictureURL")
    }

    required init?(coder aDecoder: NSCoder) {
        _userID = aDecoder.decodeObject(forKey: "userID") as? String
        _fullname = aDecoder.decodeObject(forKey: "fullname") as? String
        _profilePictureURL = aDecoder.decodeObject(forKey: "profilePictureURL") as? URL
    }

    init(user: FPUser) {
        _userID = user._userID
        _fullname = user._fullname
        _profilePictureURL = user._profilePictureURL
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return FPUser(user: self)
    }

    init(dictionary: [AnyHashable: Any]?) {
        super.init()
        guard let dictionary = dictionary else {
            return
        }
        let mappingDictionary: [String: Any] = [
            "full_name": KZPropertyDescriptor(propertyName: "_fullname", andMapping: nil),
            "profile_picture": KZPropertyDescriptor(propertyName: "_profilePictureURL", andMapping: "URL"),
            "uid": KZPropertyDescriptor(propertyName: "_userID", andMapping: nil)
        ]
        KZPropertyMapper.mapValues(from: NSDictionary(dictionary: dictionary), toInstance: self, usingMapping: mappingDictionary)
    }

    convenience init?(snapshot: DataSnapshot) {
        self.init(dictionary: snapshot.value as? [AnyHashable: Any])
        _userID = snapshot.key
    }

    override var hash: Int {
        return _userID?.hash ?? 0
    }

    func isEqualToUser(_ user: FPUser) -> Bool {
        if let left = self._userID, let right = user._userID, left == right {
            return true
        } else {
            return false
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? FPUser else {
            return false
        }

        if self === object {
            return true
        }

        return isEqualToUser(object)
    }

    override var description: String {
        let dictionary = [
            "userID": _userID ?? "",
            "fullname": _fullname ?? "",
            "profilePictureURL": _profilePictureURL?.description ?? ""
        ]
        return String(format: "<%@: %p> %@", NSStringFromClass(type(of: self)), self, dictionary)
    }

}

