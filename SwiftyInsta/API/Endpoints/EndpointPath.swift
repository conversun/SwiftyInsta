//
//  File.swift
//
//
//  Created by Stefano Bertagno on 25/11/2019.
//

import Foundation

public protocol OriginURLProtocol {
    var originURL: String { get }
}

/// An `enum` describing possible `URL`s.
public enum EndpointPath {
    case noVersion(String)
    case version1(String)
    case version2(String)
    case generic(String)
}
/// Accessories.
extension EndpointPath: LosselessEndpointRepresentable {
    // MARK: Placeholders
    /// The holders in path.
    public var placeholders: [String]? {
        let path = self.endpointPath
        let expression = try? NSRegularExpression(pattern: "\\{.+?\\}")
        return expression?.matches(in: path,
                                   options: [],
                                   range: .init(location: 0, length: path.utf16.count))
            .compactMap { Range($0.range, in: path).flatMap { String(path[$0]) }}
    }
    /// Fill a placeholder.
    public func filling(_ placeholder: String, with string: String) -> LosselessEndpointRepresentable! {
        var former = placeholder
        if !former.hasPrefix("{") { former = "{"+former }
        if !former.hasSuffix("}") { former = former+"}" }
        let escaped = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
        return EndpointPath(rawValue: rawValue.replacingOccurrences(of: former, with: escaped))
    }

    // MARK: Query
    /// Query.
    public func query<L>(_ items: [String: L]) -> LosselessEndpointRepresentable! where L: LosslessStringConvertible {
        return EndpointQuery(endpoint: self, items: items.mapValues(String.init))
    }
    /// Append path.
    public func appending(_ path: String) -> LosselessEndpointRepresentable! {
        return EndpointPath(rawValue: (basePath+endpointPath+path).replacingOccurrences(of: "//", with: "/"))
    }

    // MARK: URL components
    /// The base path.
    public var basePath: String {
        switch self {
        case .noVersion: return "https://i.in\("stag")ram.com"
        case .version1: return "https://i.in\("stag")ram.com/api/v1"
        case .version2: return "https://i.in\("stag")ram.com/api/v2"
        case .generic: return "https://www.in\("stag")ram.com"
        }
    }
    /// The main path component.
    public var endpointPath: String {
        switch self {
        case .noVersion(let path), .version1(let path), .version2(let path), .generic(let path):
            return path
        }
    }
    /// The `URLComponents`.
    public var components: URLComponents? {
        return URL(string: basePath+endpointPath).flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
    }

    // MARK: Description
    public var description: String { return basePath+endpointPath }
}
/// Extend `EndpointPath` to make it `RawRepresentable`.
extension EndpointPath: RawRepresentable, ExpressibleByStringLiteral, Equatable {
    /// Init with `stringLiteral`.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }
    /// Init with `rawValue`.
    public init?(rawValue: String) {
        if rawValue.hasPrefix("https://i.in\("stag")ram.com/api/v1") {
            self = .version1(String(rawValue.dropFirst("https://i.in\("stag")ram.com/api/v1".count)))
        } else if rawValue.hasPrefix("https://i.in\("stag")ram.com/api/v2") {
            self = .version2(String(rawValue.dropFirst("https://i.in\("stag")ram.com/api/v2".count)))
        } else if rawValue.hasPrefix("https://www.in\("stag")ram.com") {
            self = .generic(String(rawValue.dropFirst("https://www.in\("stag")ram.com".count)))
        } else if rawValue.hasPrefix("https://i.in\("stag")ram.com") {
            self = .noVersion(String(rawValue.dropFirst("https://i.in\("stag")ram.com".count)))
        } else {
            return nil
        }
    }

    /// The raw value.
    public var rawValue: String {
        if endpointPath.hasPrefix("/") {
            return basePath+endpointPath
        } else {
            return basePath+"/"+endpointPath
        }
    }
}
