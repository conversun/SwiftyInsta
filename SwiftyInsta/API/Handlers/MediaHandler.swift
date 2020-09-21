//
//  MediaHandler.swift
//  SwiftyInsta
//
//  Created by Mahdi Makhdumi on 11/23/18.
//  V. 2.0 by Stefano Bertagno on 7/21/19.
//  Copyright © 2018 Mahdi. All rights reserved.
//

import CryptoSwift
import Foundation

/// **Instagram** accepted `Media`s.
public enum MediaType: String {
    /// Image.
    case image = "1"
    /// Video.
    case video = "2"
    /// Carousel (a.k.a. **album**).
    case carousel = "8"
}

public final class MediaHandler: Handler {
    /// Get user media.
    public func by(user: User.Reference,
                   with paginationParameters: PaginationParameters,
                   updateHandler: PaginationUpdateHandler<Media, AnyPaginatedResponse>?,
                   completionHandler: @escaping PaginationCompletionHandler<Media>) {
        switch user {
        case .me:
            // check for valid user.
            guard let pk = handler.user?.identity.primaryKey ?? Int(handler.response?.storage?.dsUserId ?? "invaild") else {
                return completionHandler(.failure(AuthenticationError.invalidCache), paginationParameters)
            }
            by(user: .primaryKey(pk),
               with: paginationParameters,
               updateHandler: updateHandler,
               completionHandler: completionHandler)
        case .username:
            // fetch username.
            self.handler.users.user(user) { [weak self] in
                guard let handler = self else {
                    return completionHandler(.failure(GenericError.weakObjectReleased), paginationParameters)
                }
                switch $0 {
                case .success(let user) where user.identity.primaryKey != nil:
                    handler.by(user: .primaryKey(user.identity.primaryKey ?? -1),
                               with: paginationParameters,
                               updateHandler: updateHandler,
                               completionHandler: completionHandler)
                case .failure(let error): completionHandler(.failure(error), paginationParameters)
                default: completionHandler(.failure(GenericError.custom("No user matching `username`.")), paginationParameters)
                }
            }
        case .primaryKey(let pk):
            // load media directly.
            pages.request(Media.self,
                          page: AnyPaginatedResponse.self,
                          with: paginationParameters,
                          endpoint: { Endpoint.Feed.user.user(pk).next($0.nextMaxId) },
                          splice: { $0.rawResponse.items.array?.compactMap(Media.init) ?? [] },
                          update: updateHandler,
                          completion: completionHandler)
        }
    }

    /// Like media.
    public func heart(media mediaId: String, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        guard let storage = handler.response?.storage else {
            return completionHandler(.failure(GenericError.custom("Invalid `Authentication.Response` in `APIHandler.respone`. Log in again.")))
        }
        let body = ["_uuid": handler.settings.device.deviceGuid.uuidString,
                    "device_id": handler.settings.device.deviceGuid.uuidString,
                    "_uid": storage.dsUserId,
                    "_csrftoken": storage.csrfToken,
                    "delivery_class": "organic",
                    "inventory_source": "media_or_ad",
                    "is_carousel_bumped_post": "false",
                    "container_module": "feed_timeline",
                    "carousel_index": "0",
                    "media_id": mediaId]

        requests.request(Status.self,
                         method: .post,
                         endpoint: Endpoint.Media.like.media(mediaId),
                         body: .payload(body),
                         completion: { completionHandler($0.map { $0.state == .ok }) })
    }
}
