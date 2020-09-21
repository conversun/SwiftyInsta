//
//  UserHandler.swift
//  SwiftyInsta
//
//  Created by Mahdi Makhdumi on 11/23/18.
//  V. 2.0 by Stefano Bertagno on 7/21/19.
//  Copyright © 2018 Mahdi. All rights reserved.
//

import Foundation

public final class UserHandler: Handler {
    public func current(delay: ClosedRange<Double>?, completionHandler: @escaping (Result<User, Error>) -> Void) {
        requests.request(User.self,
                         method: .get,
                         endpoint: Endpoint.Accounts.current,
                         delay: delay,
                         process: { User(rawResponse: $0.user) },
                         completion: completionHandler)
    }

    // Its not working yet.
    /*func createAccount(account: CreateAccountModel, completion: @escaping (Bool) -> ()) throws {
     guard let httpHelper = HandlerSettings.shared.httpHelper else {return}
     httpHelper.sendAsync(method: .get, url: try URLs.getInstagramUrl(), body: [:], header: [:]) { (data, response, error) in
     if let error = error {
     print(error.localizedDescription)
     } else {
     // find CSRF token
     let fields = response?.allHeaderFields
     let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields as! [String : String], for: (response?.url)!)
     for cookie in cookies {
     if cookie.name == "csrftoken" {
     HandlerSettings.shared.user!.csrfToken = cookie.value
     break
     }
     }
     
     let content = [
     "allow_contacts_sync": "true",
     "sn_result": "API_ERROR:+null",
     "phone_id": UUID.init().uuidString,
     "_csrftoken": HandlerSettings.shared.user!.csrfToken,
     "username": account.username,
     "first_name": account.firstName,
     "adid": UUID.init().uuidString,
     "guid": UUID.init().uuidString,
     "device_id": RequestMessageModel.generateDeviceId(),
     "email": account.email,
     "sn_nonce": "",
     "force_sign_up_code": "",
     "waterfall_id": UUID.init().uuidString,
     "qs_stamp": "",
     "password": account.password,
     "gdpr_s": "[0,2,0,null]"
     ]
     
     let encoder = JSONEncoder()
     let payload = String(data: try! encoder.encode(content), encoding: .utf8)!
     let hash = payload.hmac(algorithm: .SHA256, key: Headers.igSignatureValue)
     // Creating Post Request Body
     let signature = "\(hash).\(payload)"
     let body: [String: Any] = [
     Headers.HeaderIGSignatureKey: signature.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
     Headers.igSignatureVersionKey: Headers.igSignatureVersionValue
     ]
     
     let headers: [String: String] = [
     "X-IG-App-ID": "567067343352427",
     Headers.HeaderXGoogleADID: (HandlerSettings.shared.device!.googleAdId?.uuidString)!
     ]
     
     guard let httpHelper = HandlerSettings.shared.httpHelper else {return}
     httpHelper.sendAsync(method: .post, url: try URLs.getCreateAccountUrl(), body: body, header: headers, completion: { (data, response, error) in
     if error != nil {
     completion(false)
     } else {
     if let data = data {
     //print(response)
     print(String(data: data, encoding: .utf8)!)
     }
     }
     })
     }
     }
     }*/

    /// Search for users matching the query.
    public func search(forUsersMatching query: String, completionHandler: @escaping (Result<[User], Error>) -> Void) {
        guard let storage = handler.response?.storage else {
            return completionHandler(.failure(GenericError.custom("Invalid `Authentication.Response` in `APIHandler.respone`. Log in again.")))
        }
        let headers = [Headers.timeZoneOffsetKey: Headers.timeZoneOffsetValue,
                       Headers.countKey: Headers.countValue,
                       Headers.rankTokenKey: storage.rankToken]

        pages.request(User.self,
                      page: AnyPaginatedResponse.self,
                      with: .init(maxPagesToLoad: 1),
                      endpoint: { _ in Endpoint.Users.search.q(query) },
                      headers: { _ in headers },
                      splice: { $0.rawResponse.users.array?.compactMap(User.init) ?? [] },
                      update: nil) { result, _ in
                        completionHandler(result)
        }
    }

    /// Get user matching username.
    public func user(_ user: User.Reference, completionHandler: @escaping (Result<User, Error>) -> Void) {
        switch user {
        case .me:
            // fetch current user.
            current(delay: nil, completionHandler: completionHandler)
        case .username(let username):
            // fetch username.
            search(forUsersMatching: username) {
                completionHandler($0.flatMap {
                    $0.first.flatMap(Result.success) ?? .failure(GenericError.custom("Invalid response. Processing handler returned `nil`."))
                })
            }
        case .primaryKey(let pk):
            // load user info directly.
            requests.request(User.self,
                             method: .get,
                             endpoint: Endpoint.Users.info.user(pk),
                             process: { User(rawResponse: $0.user) },
                             completion: completionHandler)
        }
    }

    /// Follow user.
    public func watch(user: User.Reference, completionHandler: @escaping (Result<Friendship, Error>) -> Void) {
        guard let storage = handler.response?.storage else {
            return completionHandler(.failure(GenericError.custom("Invalid `Authentication.Response` in `APIHandler.respone`. Log in again.")))
        }
        switch user {
        case .me:
            completionHandler(.failure(GenericError.custom("You cannot interact with yourself.")))
        case .username:
            // fetch username.
            self.user(user) { [weak self] in
                guard let handler = self else {
                    return completionHandler(.failure(GenericError.weakObjectReleased))
                }
                switch $0 {
                case .success(let user) where user.identity.primaryKey != nil:
                    handler.watch(user: .primaryKey(user.identity.primaryKey!), completionHandler: completionHandler)
                case .failure(let error): completionHandler(.failure(error))
                default: completionHandler(.failure(GenericError.custom("No user matching `username`.")))
                }
            }
        case .primaryKey(let pk):
            // follow user directly.
            let body = ["_uuid": handler.settings.device.deviceGuid.uuidString,
                        "_uid": storage.dsUserId,
                        "_csrftoken": storage.csrfToken,
                        "user_id": String(pk),
                        "device_id": handler.settings.device.deviceGuid.uuidString]

            requests.request(Friendship.self,
                             method: .post,
                             endpoint: Endpoint.Friendships.follow.user(pk),
                             body: .payload(body),
                             process: { Friendship(rawResponse: $0.friendshipStatus) },
                             completion: completionHandler)
        }
    }

    /// Friendship status.
    public func friendshipStatus(withUser user: User.Reference, completionHandler: @escaping (Result<Friendship, Error>) -> Void) {
        switch user {
        case .me:
            completionHandler(.failure(GenericError.custom("You cannot interact with yourself.")))
        case .username:
            // fetch username.
            self.user(user) { [weak self] in
                guard let handler = self else {
                    return completionHandler(.failure(GenericError.weakObjectReleased))
                }
                switch $0 {
                case .success(let user) where user.identity.primaryKey != nil:
                    handler.friendshipStatus(withUser: .primaryKey(user.identity.primaryKey!), completionHandler: completionHandler)
                case .failure(let error): completionHandler(.failure(error))
                default: completionHandler(.failure(GenericError.custom("No user matching `username`.")))
                }
            }
        case .primaryKey(let pk):
            // get status directly.
            requests.request(Friendship.self,
                             method: .get,
                             endpoint: Endpoint.Friendships.status.user(pk),
                             completion: completionHandler)
        }
    }

    /// Friendship statuses.
    /// Use `friendshipStatus(withUser: completionHandler:)` on each and every element of `ids` to retreieve all properties in `Friendship`.
    public func friendshipStatuses<C: Collection>(withUsersMatchingIDs ids: C,
                                                  completionHandler: @escaping(Result<[User.Reference: Friendship], Error>) -> Void)
        where C.Element == Int {
            guard let storage = handler.response?.storage else {
                return completionHandler(.failure(
                    GenericError.custom("Invalid `Authentication.Response` in `APIHandler.respone`. Log in again.")
                ))
            }
            guard !ids.isEmpty else {
                return completionHandler(.failure(GenericError.custom("`ids` must be non-empty.")))
            }

            // get status directly.
            let body = ["_uuid": handler.settings.device.deviceGuid.uuidString,
                        "include_reel_info": "0",
                        "_csrftoken": storage.csrfToken,
                        "user_ids": Set(ids).map(String.init).joined(separator: ", ")]

            pages.request([User.Reference: Friendship].self,
                          page: AnyPaginatedResponse.self,
                          with: .init(maxPagesToLoad: 1),
                          endpoint: { _ in Endpoint.Friendships.statuses },
                          body: { _ in .parameters(body) },
                          splice: {
                            $0.rawResponse.friendshipStatuses.dictionary?
                                .compactMap { key, value -> [User.Reference: Friendship]? in
                                    guard let primaryKey = Int(key) else { return nil }
                                    return [User.Reference.primaryKey(primaryKey): Friendship(rawResponse: value)]
                                        .compactMapValues { $0 }
                                } ?? []
            },
                        update: nil,
                        completion: { result, _ in
                            completionHandler(result.map {
                                Dictionary(uniqueKeysWithValues: $0.map { $0.map { ($0, $1) } }.joined())
                            })
            })
    }
}
