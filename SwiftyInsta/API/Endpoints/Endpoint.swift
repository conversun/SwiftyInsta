//
//  Endpoint.swift
//  iOS
//
//  Created by Stefano Bertagno on 25/08/2019.
//  Copyright © 2019 Mahdi. All rights reserved.
//

import Foundation

/// A `struct` holding reference to specific endpoints.
public struct Endpoint {
    /// An `enum` providing for `Authentication` endpoints.
    enum Authentication: EndpointPath, CaseIterable, RawEndpointRepresentable {
        /// Home.
        case home = "https://www.instagram.com"
        /// Login.
        case login = "https://www.instagram.com/accounts/login/ajax/"
        /// Two factor.
        case twoFactor = "https://www.instagram.com/accounts/login/ajax/two_factor/"
        /// Resend two factor.
        case sendTwoFactorLoginSms = "https://www.instagram.com/accounts/send_two_factor_login_sms/"
    }

    /// An `enum` providing for `Accounts` endpoints.
    enum Accounts: EndpointPath, CaseIterable, RawEndpointRepresentable {
        /// Create.
        case create = "https://i.instagram.com/api/v1/accounts/create/"
        /// Login.
        case login = "https://i.instagram.com/api/v1/accounts/login/"
        /// Two factor login.
        case twoFactorLogin = "https://i.instagram.com/api/v1/accounts/two_factor_login/"
        /// Send two factor login sms.
        case sendTwoFactorLoginSms = "https://i.instagram.com/api/v1/accounts/send_two_factor_login_sms/"
        /// Current user.
        case current = "https://i.instagram.com/api/v1/accounts/current_user/?edit=true"
        /// Logout.
        case logout = "https://i.instagram.com/api/v1/accounts/logout/"
        /// Set account public.
        case setPublic = "https://i.instagram.com/api/v1/accounts/set_public/"
        /// Set account private.
        case setPrivate = "https://i.instagram.com/api/v1/accounts/set_private/"
        /// Edit profile.
    }
    
    /// An `enum` providing for `Feed` endpoints.
    enum Feed: EndpointPath, CaseIterable, RawEndpointRepresentable {
        /// User's feed.
        case user = "https://i.instagram.com/api/v1/feed/user/{userPk}/"
    }

    /// An `enum` providing for `Friendships` enddpoints.
    enum Friendships: EndpointPath, CaseIterable, RawEndpointRepresentable {
        case follow = "https://i.instagram.com/api/v1/friendships/create/{userPk}/"
        /// Friendship status.
        case status = "https://i.instagram.com/api/v1/friendships/show/{userPk}/"
        /// Friendship statuses.
        case statuses = "https://i.instagram.com/api/v1/friendships/show_many/"
    }
    
    /// An `enum` providing for `Media` endpoints.
    enum Media: EndpointPath, CaseIterable, RawEndpointRepresentable {
        /// Media info.
        case info = "https://i.instagram.com/api/v1/media/{mediaId}/info/"
        /// Like.
        case like = "https://i.instagram.com/api/v1/media/{mediaId}/like/?d=1"
    }

    /// An `enum` providing for `Users` endpoints.
    enum Users: EndpointPath, CaseIterable, RawEndpointRepresentable {
        /// Search.
        case search = "https://i.instagram.com/api/v1/users/search/"
        /// Info.
        case info = "https://i.instagram.com/api/v1/users/{userPk}/info/"
    }
}
