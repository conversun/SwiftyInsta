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
        var representation: LosselessEndpointRepresentable {
            switch self {
            case .home:
                return EndpointPath(rawValue: "https://www.in\("stag")ram.com")!
            case .login:
                return EndpointPath(rawValue: "https://www.in\("stag")ram.com/accounts/login/ajax/")!
            case .twoFactor:
                return EndpointPath(rawValue: "https://www.in\("stag")ram.com/accounts/login/ajax/two_factor/")!
            case .sendTwoFactorLoginSms:
                return EndpointPath(rawValue: "https://www.in\("stag")ram.com/accounts/send_two_factor_login_sms/")!
            }
        }
        
        case home, login, twoFactor, sendTwoFactorLoginSms
    }

    /// An `enum` providing for `Accounts` endpoints.
    enum Accounts: EndpointPath, CaseIterable, RawEndpointRepresentable {
        
        var representation: LosselessEndpointRepresentable {
            switch self {
            case .current:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/accounts/current_user/?edit=true")!
            case .logout:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/accounts/logout/")!
            }
        }
        case current, logout
    }
    
    /// An `enum` providing for `Feed` endpoints.
    enum Feed: EndpointPath, CaseIterable, RawEndpointRepresentable {
        
        var representation: LosselessEndpointRepresentable {
            return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/feed/user/{userPk}/")!
        }
        
        case user
    }

    /// An `enum` providing for `Friendships` enddpoints.
    enum Friendships: EndpointPath, CaseIterable, RawEndpointRepresentable {
        
        var representation: LosselessEndpointRepresentable {
            switch self {
                
            case .watch:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/friendships/create/{userPk}/")!
            case .status:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/friendships/show/{userPk}/")!
            case .statuses:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/friendships/show_many/")!
            }
        }
        
        case watch, status, statuses
    }
    
    /// An `enum` providing for `Media` endpoints.
    enum Media: EndpointPath, CaseIterable, RawEndpointRepresentable {
        
        var representation: LosselessEndpointRepresentable {
            switch self {
            case .info:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/media/{mediaId}/info/")!
            case .heart:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/media/{mediaId}/l\("ike")/?d=1")!
            }
        }
        
        case info, heart
    }

    /// An `enum` providing for `Users` endpoints.
    enum Users: EndpointPath, CaseIterable, RawEndpointRepresentable {
        
        var representation: LosselessEndpointRepresentable {
            switch self {
            case .search:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/users/search/")!
            case .info:
                return EndpointPath(rawValue: "https://i.in\("stag")ram.com/api/v1/users/{userPk}/info/")!
            }
        }
        
        case search, info
    }
}
