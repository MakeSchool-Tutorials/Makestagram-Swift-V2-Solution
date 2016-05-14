//
//  Post.swift
//  Makestagram
//
//  Created by Jason Katzer on 5/12/16.
//  Copyright © 2016 Make School. All rights reserved.
//

import Foundation

import Bond
import Parse

// 1
class Post : PFObject, PFSubclassing {

  // 2

  var image: Observable<UIImage?> = Observable(nil)

  var photoUploadTask: UIBackgroundTaskIdentifier?

  var likes: Observable<[PFUser]?> = Observable(nil)

  @NSManaged var imageFile: PFFile?
  @NSManaged var user: PFUser?


  //MARK: PFSubclassing Protocol

  // 3
  static func parseClassName() -> String {
    return "Post"
  }

  // 4
  override init () {
    super.init()
  }

  override class func initialize() {
    var onceToken : dispatch_once_t = 0;
    dispatch_once(&onceToken) {
      // inform Parse about this subclass
      self.registerSubclass()
    }
  }



  func uploadPost() {

    if let image = image.value {

      photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
        () -> Void in
        UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
      }

      let imageData = UIImageJPEGRepresentation(image, 0.8)
      guard let imageFile = PFFile(data: imageData!) else {return}
      imageFile.saveInBackgroundWithBlock(nil)

      user = PFUser.currentUser()
      self.imageFile = imageFile
      saveInBackgroundWithBlock {
        (success: Bool, error: NSError?) -> Void in
        UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
      }
    }
  }

  func downloadImage() {
    // if image is not downloaded yet, get it
    // 1
    if (image.value == nil) {
      // 2
      imageFile?.getDataInBackgroundWithBlock { (data: NSData?, error: NSError?) -> Void in
        if let data = data {
          let image = UIImage(data: data, scale:1.0)!
          // 3
          self.image.value = image
        }
      }
    }
  }

  func fetchLikes() {
    // 1
    if (likes.value != nil) {
      return
    }

    // 2
    ParseHelper.likesForPost(self, completionBlock: { (var likes: [PFObject]?, error: NSError?) -> Void in
      // 3
      likes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }

      // 4
      self.likes.value = likes?.map { like in
        let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser

        return fromUser
      }
    })
  }

  func doesUserLikePost(user: PFUser) -> Bool {
    if let likes = likes.value {
      return likes.contains(user)
    } else {
      return false
    }
  }

  func toggleLikePost(user: PFUser) {
    if (doesUserLikePost(user)) {
      // if image is liked, unlike it now
      // 1
      likes.value = likes.value?.filter { $0 != user }
      ParseHelper.unlikePost(user, post: self)
    } else {
      // if this image is not liked yet, like it now
      // 2
      likes.value?.append(user)
      ParseHelper.likePost(user, post: self)
    }
  }
}