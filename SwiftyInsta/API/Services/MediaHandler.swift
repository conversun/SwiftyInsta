//
//  MediaHandler.swift
//  SwiftyInsta
//
//  Created by Mahdi Makhdumi on 11/23/18.
//  Copyright © 2018 Mahdi. All rights reserved.
//

import Foundation

public protocol MediaHandlerProtocol {
    func getUserMedia(for username: String, paginationParameter: PaginationParameters, completion: @escaping (Result<[UserFeedModel]>) -> ()) throws
    func getMediaInfo(mediaId: String, completion: @escaping (Result<MediaModel>) -> ()) throws
    func likeMedia(mediaId: String, completion: @escaping (Bool) -> ()) throws
    func unLikeMedia(mediaId: String, completion: @escaping (Bool) -> ()) throws
    func uploadPhoto(photo: InstaPhoto, completion: @escaping (Result<UploadPhotoResponse>) -> ()) throws
    func uploadPhotoAlbum(photos: [InstaPhoto], caption: String, completion: @escaping (Result<UploadPhotoAlbumResponse>) -> ()) throws
    func deleteMedia(mediaId: String, mediaType: MediaTypes, completion: @escaping (Result<DeleteMediaResponse>) -> ()) throws
    func editMedia(mediaId: String, caption: String, completion: @escaping (Result<MediaModel>) -> ()) throws
}

class MediaHandler: MediaHandlerProtocol {
    
    static let shared = MediaHandler()
    
    private init() {
        
    }
    
    func getUserMedia(for username: String, paginationParameter: PaginationParameters, completion: @escaping (Result<[UserFeedModel]>) -> ()) throws {
        try UserHandler.shared.getUser(username: username, completion: { [weak self] (result) in
            self!.getMediaList(from: try! URLs.getUserFeedUrl(userPk: result.value?.pk), userPk: result.value?.pk, list: [], paginationParameter: paginationParameter, completion: { (value) in
                completion(Return.success(value: value))
            })
        })
    }
    
    fileprivate func getMediaList(from url: URL, userPk: Int?, list: [UserFeedModel], paginationParameter: PaginationParameters, completion: @escaping ([UserFeedModel]) -> ()) {
        if paginationParameter.pagesLoaded == paginationParameter.maxPagesToLoad {
            completion(list)
        } else {
            var _paginationParameter = paginationParameter
            _paginationParameter.pagesLoaded += 1
            HandlerSettings.shared.httpHelper!.sendAsync(method: .get, url: url, body: [:], header: [:]) { [weak self] (data, response, error) in
                if error != nil {
                    completion(list)
                } else {
                    if response?.statusCode != 200 {
                        completion(list)
                    } else {
                        if let data = data {
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            var mediaList = list
                            do {
                                let newItems = try decoder.decode(UserFeedModel.self, from: data)
                                mediaList.append(newItems)
                                if newItems.moreAvailable! {
                                    _paginationParameter.nextId = newItems.nextMaxId!
                                    let url = try URLs.getUserFeedUrl(userPk: userPk, maxId: _paginationParameter.nextId)
                                    self!.getMediaList(from: url, userPk: userPk, list: mediaList, paginationParameter: _paginationParameter, completion: { (result) in
                                        completion(result)
                                    })
                                } else {
                                    completion(mediaList)
                                }
                            } catch {
                                completion(list)
                            }
                        } else {
                            completion(list)
                        }
                    }
                }
            }
        }
    }

    func getMediaInfo(mediaId: String, completion: @escaping (Result<MediaModel>) -> ()) throws {
        HandlerSettings.shared.httpHelper!.sendAsync(method: .get, url: try URLs.getMediaUrl(mediaId: mediaId), body: [:], header: [:]) { (data, response, error) in
            if let error = error {
                completion(Return.fail(error: error, response: .fail, value: nil))
            } else {
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let media = try decoder.decode(UserFeedModel.self, from: data)
                        completion(Return.success(value: media.items?.first))
                    } catch {
                        completion(Return.fail(error: error, response: .ok, value: nil))                    }
                } else {
                    let error = CustomErrors.unExpected("The data couldn’t be read because it is missing error when decoding JSON.")
                    completion(Return.fail(error: error, response: .ok, value: nil))
                }
            }
        }
    }
    
    func likeMedia(mediaId: String, completion: @escaping (Bool) -> ()) throws {
        let body = [
            "_uuid": HandlerSettings.shared.device!.deviceGuid.uuidString,
            "_uid": String(HandlerSettings.shared.user!.loggedInUser.pk!),
            "_csrftoken": HandlerSettings.shared.user!.csrfToken,
            "media_id": mediaId
        ]
        
        HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: try URLs.getLikeMediaUrl(mediaId: mediaId), body: body, header: [:]) { (data, response, error) in
            if error != nil {
                completion(false)
            } else {
                if response?.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    func unLikeMedia(mediaId: String, completion: @escaping (Bool) -> ()) throws {
        let body = [
            "_uuid": HandlerSettings.shared.device!.deviceGuid.uuidString,
            "_uid": String(HandlerSettings.shared.user!.loggedInUser.pk!),
            "_csrftoken": HandlerSettings.shared.user!.csrfToken,
            "media_id": mediaId
        ]
        
        HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: try URLs.getUnLikeMediaUrl(mediaId: mediaId), body: body, header: [:]) { (data, response, error) in
            if error != nil {
                completion(false)
            } else {
                if response?.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func uploadPhoto(photo: InstaPhoto, completion: @escaping (Result<UploadPhotoResponse>) -> ()) throws {
        let uploadId = HandlerSettings.shared.request!.generateUploadId()
        var content = Data()
        content.append(string: "--\(uploadId)\n")
        content.append(string: "Content-Type: text/plain; charset=utf-8\n")
        content.append(string: "Content-Disposition: form-data; name=\"upload_id\"\n\n")
        content.append(string: "\(uploadId)\n")
        content.append(string: "--\(uploadId)\n")
        content.append(string: "Content-Type: text/plain; charset=utf-8\n")
        content.append(string: "Content-Disposition: form-data; name=\"_uuid\"\n\n")
        content.append(string: "\(HandlerSettings.shared.device!.deviceGuid.uuidString)\n")
        content.append(string: "--\(uploadId)\n")
        content.append(string: "Content-Type: text/plain; charset=utf-8\n")
        content.append(string: "Content-Disposition: form-data; name=\"_csrftoken\"\n\n")
        content.append(string: "\(HandlerSettings.shared.user!.csrfToken)\n")
        content.append(string: "--\(uploadId)\n")
        content.append(string: "Content-Type: text/plain; charset=utf-8\n")
        content.append(string: "Content-Disposition: form-data; name=\"image_compression\"\n\n")
        content.append(string: "{\"lib_name\":\"jt\",\"lib_version\":\"1.3.0\",\"quality\":\"87\"}\n")
        content.append(string: "--\(uploadId)\n")
        content.append(string: "Content-Transfer-Encoding: binary\n")
        content.append(string: "Content-Type: application/octet-stream\n")
        content.append(string: "Content-Disposition: form-data; name=photo; filename=pending_media_\(uploadId).jpg; filename*=utf-8''pending_media_\(uploadId).jpg\n\n")
        
        let imageData = photo.image.jpegData(compressionQuality: 1)
        
        content.append(imageData!)
        content.append(string: "\n--\(uploadId)--\n\n")
        
        let header = ["Content-Type": "multipart/form-data; boundary=\"\(uploadId)\""]
        
        HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: try URLs.getUploadPhotoUrl(), body: [:], header: header, data: content) { [weak self] (data, response, error) in
            if let error = error {
                completion(Return.fail(error: error, response: .fail, value: nil))
            } else {
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let res = try decoder.decode(UploadPhotoResponse.self, from: data)
                        if res.status! == "ok" {
                            self!.configureMedia(photo: photo, uploadId: uploadId, caption: photo.caption, completion: { (media, error) in
                                if let error = error {
                                    completion(Return.fail(error: error, response: .ok, value: nil))
                                } else {
                                    completion(Return.success(value: media))
                                }
                            })
                        } else {
                            let error = CustomErrors.unExpected("failed status response from server.)")
                            completion(Return.fail(error: error, response: .ok, value: nil))
                        }
                    } catch {
                        completion(Return.fail(error: error, response: .ok, value: nil))
                    }
                }
            }
        }
    }
    
    fileprivate func configureMedia(photo: InstaPhoto, uploadId: String, caption: String, completion: @escaping (UploadPhotoResponse?, Error?) -> ()) {
        let url = try! URLs.getConfigureMediaUrl()
        let _device = HandlerSettings.shared.device!
        let _user = HandlerSettings.shared.user!
        let version = _device.frimwareFingerprint.split(separator: "/")[2].split(separator: ":")[1]
        let androidVersion = AndroidVersion.fromString(versionString: String(version))
        if let androidVersion = androidVersion {
            let configureDevice = ConfigureDevice.init(manufacturer: _device.hardwareManufacturer, model: _device.hardwareModel, android_version: androidVersion.versionNumber, android_release: androidVersion.apiLevel)
            let configureEdits = ConfigureEdits.init(crop_original_size: [photo.width, photo.height], crop_center: [0.0, -0.0], crop_zoom: 1)
            let configureExtras = ConfigureExtras.init(source_width: photo.width, source_height: photo.height)
            let configure = ConfigurePhotoModel.init(_uuid: _device.deviceGuid.uuidString, _uid: _user.loggedInUser.pk!, _csrftoken: _user.csrfToken, media_folder: "Camera", source_type: "4", caption: caption, upload_id: uploadId, device: configureDevice, edits: configureEdits, extras: configureExtras)
            
            let encoder = JSONEncoder()
            let payload = String(data: try! encoder.encode(configure), encoding: .utf8)!
            let hash = payload.hmac(algorithm: .SHA256, key: Headers.HeaderIGSignatureValue)
            
            // Creating Post Request Body
            let signature = "\(hash).\(payload)"
            let body: [String: Any] = [
                Headers.HeaderIGSignatureKey: signature.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                Headers.HeaderIGSignatureVersionKey: Headers.HeaderIGSignatureVersionValue
            ]
            
            HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: url, body: body, header: [:]) { (data, response, error) in
                if error != nil {
                    completion(nil, error)
                } else {
                    if let data = data {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        do {
                            let media = try decoder.decode(UploadPhotoResponse.self, from: data)
                            completion(media, nil)
                        } catch {
                            completion(nil, error)
                        }
                    } else {
                        completion(nil, CustomErrors.unExpected("no data received from server."))
                    }
                }
            }
        } else {
            completion(nil, CustomErrors.unExpected("Unsupported android version"))
        }
    }
    
    func uploadPhotoAlbum(photos: [InstaPhoto], caption: String, completion: @escaping (Result<UploadPhotoAlbumResponse>) -> ()) throws {
        getUploadIdsForPhotoAlbum(uploadIds: [], photos: photos) { [weak self] (uploadIds) in
            self!.configureMediaAlbum(uploadIds: uploadIds, caption: caption, completion: { (value, error) in
                if let error = error {
                    completion(Return.fail(error: error, response: .fail, value: nil))
                } else {
                    completion(Return.success(value: value))
                }
            })
        }
    }
    
    fileprivate func getUploadIdsForPhotoAlbum(uploadIds: [String], photos: [InstaPhoto], completion: @escaping ([String]) -> ()) {
        if photos.count == 0 {
            completion(uploadIds)
        } else {
            var _uploadIds = uploadIds
            var _photos = photos
            let _currentPhoto = _photos.removeFirst()
            
            let _device = HandlerSettings.shared.device!
            let _user = HandlerSettings.shared.user!
            let _request = HandlerSettings.shared.request!
            
            let uploadId = _request.generateUploadId()
            var content = Data()
            content.append(string: "--\(uploadId)\n")
            content.append(string: "Content-Type: text/plain; charset=utf-8\n")
            content.append(string: "Content-Disposition: form-data; name=\"upload_id\"\n\n")
            content.append(string: "\(uploadId)\n")
            content.append(string: "--\(uploadId)\n")
            content.append(string: "Content-Type: text/plain; charset=utf-8\n")
            content.append(string: "Content-Disposition: form-data; name=\"_uuid\"\n\n")
            content.append(string: "\(_device.deviceGuid.uuidString)\n")
            content.append(string: "--\(uploadId)\n")
            content.append(string: "Content-Type: text/plain; charset=utf-8\n")
            content.append(string: "Content-Disposition: form-data; name=\"_csrftoken\"\n\n")
            content.append(string: "\(_user.csrfToken)\n")
            content.append(string: "--\(uploadId)\n")
            content.append(string: "Content-Type: text/plain; charset=utf-8\n")
            content.append(string: "Content-Disposition: form-data; name=\"image_compression\"\n\n")
            content.append(string: "{\"lib_name\":\"jt\",\"lib_version\":\"1.3.0\",\"quality\":\"87\"}\n")
            content.append(string: "--\(uploadId)\n")
            content.append(string: "Content-Type: text/plain; charset=utf-8\n")
            content.append(string: "Content-Disposition: form-data; name=\"is_sidecar\"\n\n")
            content.append(string: "1\n")
            content.append(string: "--\(uploadId)\n")
            content.append(string: "Content-Transfer-Encoding: binary\n")
            content.append(string: "Content-Type: application/octet-stream\n")
            content.append(string: "Content-Disposition: form-data; name=photo; filename=pending_media_\(uploadId).jpg; filename*=utf-8''pending_media_\(uploadId).jpg\n\n")
            
            let imageData = _currentPhoto.image.jpegData(compressionQuality: 1)
            
            content.append(imageData!)
            content.append(string: "\n--\(uploadId)--\n\n")
            
            let header = ["Content-Type": "multipart/form-data; boundary=\"\(uploadId)\""]
            
            HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: try! URLs.getUploadPhotoUrl(), body: [:], header: header, data: content) { [weak self] (data, response, error) in
                if error != nil {
                    completion(_uploadIds)
                } else {
                    if let data = data {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        do {
                            let res = try decoder.decode(UploadPhotoResponse.self, from: data)
                            if res.status! == "ok" {
                                _uploadIds.append(res.uploadId!)
                                self!.getUploadIdsForPhotoAlbum(uploadIds: _uploadIds, photos: _photos, completion: { (ids) in
                                    completion(ids)
                                })
                            } else {
                                completion(_uploadIds)
                            }
                        } catch {
                            completion(_uploadIds)
                        }
                    } else {
                        completion(_uploadIds)
                    }
                }
            }
            
        }
    }
    
    fileprivate func configureMediaAlbum(uploadIds: [String], caption: String, completion: @escaping (UploadPhotoAlbumResponse?, Error?) -> ()) {
        let url = try! URLs.getConfigureMediaAlbumUrl()
        let _device = HandlerSettings.shared.device!
        let _user = HandlerSettings.shared.user!
        let _request = HandlerSettings.shared.request!

        
        let clientSidecarId = _request.generateUploadId()
        
        var childrens: [ConfigureChildren] = []
        for id in uploadIds {
            childrens.append(ConfigureChildren.init(scene_capture_type: "standard", mas_opt_in: "NOT_PROMPTED", camera_position: "unknown", allow_multi_configures: false, geotag_enabled: false, disable_comments: false, source_type: 0, upload_id: id))
        }
        
        let content = ConfigurePhotoAlbumModel.init(_uuid: _device.deviceGuid.uuidString, _uid: _user.loggedInUser.pk!, _csrftoken: _user.csrfToken, caption: caption, client_sidecar_id: clientSidecarId, geotag_enabled: false, disable_comments: false, children_metadata: childrens)
        
        let encoder = JSONEncoder()
        let payload = String(data: try! encoder.encode(content), encoding: .utf8)!
        let hash = payload.hmac(algorithm: .SHA256, key: Headers.HeaderIGSignatureValue)
        // Creating Post Request Body
        let signature = "\(hash).\(payload)"
        let body: [String: Any] = [
            Headers.HeaderIGSignatureKey: signature.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
            Headers.HeaderIGSignatureVersionKey: Headers.HeaderIGSignatureVersionValue
        ]
        
        HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: url, body: body, header: [:]) { (data, response, error) in
            if let error = error {
                completion(nil, error)
            } else {
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let res = try decoder.decode(UploadPhotoAlbumResponse.self, from: data)
                        completion(res, nil)
                    } catch {
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    func deleteMedia(mediaId: String, mediaType: MediaTypes, completion: @escaping (Result<DeleteMediaResponse>) -> ()) throws {
        let content = [
            "_uuid": HandlerSettings.shared.device!.deviceGuid.uuidString,
            "_uid": String(HandlerSettings.shared.user!.loggedInUser.pk!),
            "_csrftoken": HandlerSettings.shared.user!.csrfToken,
            "media_id": mediaId,
        ]
        
        HandlerSettings.shared.httpHelper!.sendAsync(method: .post, url: try URLs.getDeleteMediaUrl(mediaId: mediaId, mediaType: mediaType.rawValue), body: content, header: [:]) { (data, response, error) in
            if let error = error {
                completion(Return.fail(error: error, response: .fail, value: nil))
            } else {
                if let data = data {
                    let decoder = JSONDecoder()
                    do {
                        let value = try decoder.decode(DeleteMediaResponse.self, from: data)
                        completion(Return.success(value: value))
                    } catch {
                        completion(Return.fail(error: error, response: .ok, value: nil))
                    }
                }
            }
        }
    }
    
    func editMedia(mediaId: String, caption: String, completion: @escaping (Result<MediaModel>) -> ()) throws {
        let encoder = JSONEncoder()
        
        let content = [
            "_uuid": HandlerSettings.shared.device!.deviceGuid.uuidString,
            "_uid": String(format: "%ld", HandlerSettings.shared.user!.loggedInUser.pk!),
            "_csrftoken": HandlerSettings.shared.user!.csrfToken,
            "caption_text": caption,
        ]

        let payload = String(data: try! encoder.encode(content), encoding: .utf8)!
        let hash = payload.hmac(algorithm: .SHA256, key: Headers.HeaderIGSignatureValue)
        // Creating Post Request Body
        let signature = "\(hash).\(payload)"
        let body: [String: Any] = [
            Headers.HeaderIGSignatureKey: signature.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
            Headers.HeaderIGSignatureVersionKey: Headers.HeaderIGSignatureVersionValue
        ]
        
        HandlerSettings.shared.httpHelper?.sendAsync(method: .post, url: try! URLs.getEditMediaUrl(mediaId: mediaId), body: body, header: [:], completion: { (data, response, error) in
            if let error = error {
                completion(Return.fail(error: error, response: .fail, value: nil))
            } else {
                if response?.statusCode == 200 {
                    if let data = data {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        do {
                            let value = try decoder.decode(MediaModel.self, from: data)
                            completion(Return.success(value: value))
                        } catch {
                            completion(Return.fail(error: error, response: .ok, value: nil))
                        }
                    }
                } else {
                    completion(Return.fail(error: nil, response: .fail, value: nil))
                }
            }
        })
    }
}
