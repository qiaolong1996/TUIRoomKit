//
//  UserListViewModel.swift
//  TUIRoomKit
//
//  Created by 唐佳宁 on 2023/1/4.
//  Copyright © 2023 Tencent. All rights reserved.
//

import Foundation
import TUIRoomEngine

protocol UserListViewResponder: NSObject {
    func updateButtonHiddenState(isHidden: Bool)
    func reloadUserListView()
    func makeToast(text: String)
    func updateUserManagerViewDisplayStatus(isHidden: Bool)
    func updateMuteAllAudioButtonState(isSelect: Bool)
    func updateMuteAllVideoButtonState(isSelect: Bool)
    func showAlert(title: String?, message: String?, sureTitle:String?, declineTitle: String?, sureBlock: (() -> ())?, declineBlock: (() -> ())?)
}

class UserListViewModel: NSObject {
    var userId: String = ""
    var userName: String = ""
    var attendeeList: [UserEntity] = []
    var engineManager: EngineManager {
        EngineManager.createInstance()
    }
    var currentUser: UserEntity {
        engineManager.store.currentUser
    }
    var roomInfo: TUIRoomInfo {
        engineManager.store.roomInfo
    }
    let timeoutNumber: Double = 0
    weak var viewResponder: UserListViewResponder? = nil
    
    override init() {
        super.init()
        self.attendeeList = engineManager.store.attendeeList
        EngineEventCenter.shared.subscribeUIEvent(key: .TUIRoomKitService_CurrentUserRoleChanged, responder: self)
        EngineEventCenter.shared.subscribeUIEvent(key: .TUIRoomKitService_RenewUserList, responder: self)
        EngineEventCenter.shared.subscribeUIEvent(key: .TUIRoomKitService_RenewSeatList, responder: self)
        EngineEventCenter.shared.subscribeUIEvent(key: .TUIRoomKitService_RoomOwnerChanged, responder: self)
        EngineEventCenter.shared.subscribeEngine(event: .onAllUserMicrophoneDisableChanged, observer: self)
        EngineEventCenter.shared.subscribeEngine(event: .onAllUserCameraDisableChanged, observer: self)
        EngineEventCenter.shared.subscribeUIEvent(key: .TUIRoomKitService_CurrentUserRoleChanged, responder: self)
    }
    
    deinit {
        EngineEventCenter.shared.unsubscribeUIEvent(key: .TUIRoomKitService_CurrentUserRoleChanged, responder: self)
        EngineEventCenter.shared.unsubscribeUIEvent(key: .TUIRoomKitService_RenewUserList, responder: self)
        EngineEventCenter.shared.unsubscribeUIEvent(key: .TUIRoomKitService_RenewSeatList, responder: self)
        EngineEventCenter.shared.unsubscribeUIEvent(key: .TUIRoomKitService_RoomOwnerChanged, responder: self)
        EngineEventCenter.shared.unsubscribeEngine(event: .onAllUserMicrophoneDisableChanged, observer: self)
        EngineEventCenter.shared.unsubscribeEngine(event: .onAllUserCameraDisableChanged, observer: self)
        EngineEventCenter.shared.unsubscribeUIEvent(key: .TUIRoomKitService_CurrentUserRoleChanged, responder: self)
        debugPrint("deinit \(self)")
    }
    
    func muteAllAudioAction(sender: UIButton, view: UserListView) {
        let isSelected = sender.isSelected
        viewResponder?.showAlert(title: sender.isSelected ? .allUnmuteTitle : .allMuteTitle,
                                 message: sender.isSelected ? .allUnmuteMessage : .allMuteMessage,
                                 sureTitle: sender.isSelected ? .confirmReleaseText : .allMuteActionText,
                                 declineTitle: .cancelText, sureBlock: { [weak self] in
            guard let self = self else { return }
            self.engineManager.muteAllAudioAction(isMute: !isSelected) {
            } onError: { [weak self] _, message in
                guard let self = self else { return }
                self.viewResponder?.makeToast(text:message)
            }
        }, declineBlock: nil)
    }
    
    func muteAllVideoAction(sender: UIButton, view: UserListView) {
        let isSelected = sender.isSelected
        viewResponder?.showAlert(title: sender.isSelected ? .allUnmuteVideoTitle : .allMuteVideoTitle,
                                 message: sender.isSelected ? .allUnmuteVideoMessage : .allMuteVideoMessage,
                                 sureTitle: sender.isSelected ? .confirmReleaseText : .allMuteVideoActionText,
                                 declineTitle: .cancelText, sureBlock: { [weak self] in
            guard let self = self else { return }
            self.engineManager.muteAllVideoAction(isMute: !isSelected) {
            } onError: { [weak self] _, message in
                guard let self = self else { return }
                self.viewResponder?.makeToast(text:message)
            }
        }, declineBlock: nil)
    }
    
    func showUserManageViewAction(userId: String, userName: String) {
        self.userId = userId
        self.userName = userName
        guard checkShowManagerView() else { return }
        viewResponder?.updateUserManagerViewDisplayStatus(isHidden: false)
    }
    
    private func checkShowManagerView() -> Bool {
        guard let userInfo = engineManager.store.attendeeList.first(where: { $0.userId == userId }) else { return false }
        if currentUser.userRole == .roomOwner, userId != currentUser.userId {
            return true
        } else if currentUser.userRole == .administrator, userId != currentUser.userId, userInfo.userRole == .generalUser {
            return true
        } else {
            return false
        }
    }
    
    func inviteSeatAction(sender: UIButton) {
        guard let userInfo = attendeeList.first(where: { $0.userId == userId }) else { return }
        //如果已经邀请了，不需要再次发出邀请
        if !engineManager.store.extendedInvitationList.contains(userId) {
            engineManager.takeUserOnSeatByAdmin(userId: userId, timeout: timeoutNumber) { _,_ in
            } onRejected: { [weak self] requestId, userId, message in
                guard let self = self else { return }
                self.viewResponder?.makeToast(text: (userInfo.userName) + .refusedTakeSeatInvitationText)
            } onTimeout: { [weak self] _, _ in
                guard let self = self else { return }
                self.viewResponder?.makeToast(text: .takeSeatInvitationTimeoutText)
            } onError: { [weak self] _, _, _, message in
                guard let self = self else { return }
                self.viewResponder?.makeToast(text: message)
            }
        }
        viewResponder?.makeToast(text: .invitedTakeSeatText)
    }
    
    func checkSelfInviteAbility(invitee: UserEntity) -> Bool {
        if currentUser.userRole == .roomOwner {
            return true
        } else if currentUser.userRole == .administrator, invitee.userRole == .generalUser {
            return true
        } else {
            return false
        }
    }
}

extension UserListViewModel: RoomKitUIEventResponder {
    func onNotifyUIEvent(key: EngineEventCenter.RoomUIEvent, Object: Any?, info: [AnyHashable : Any]?) {
        switch key {
        case .TUIRoomKitService_RenewUserList, .TUIRoomKitService_RenewSeatList:
            attendeeList = engineManager.store.attendeeList
            viewResponder?.reloadUserListView()
        case .TUIRoomKitService_CurrentUserRoleChanged:
            guard let userRole = info?["userRole"] as? TUIRole else { return }
            viewResponder?.updateButtonHiddenState(isHidden: userRole == .generalUser)
        case .TUIRoomKitService_RoomOwnerChanged:
            viewResponder?.reloadUserListView()
        default: break
        }
    }
}

extension UserListViewModel: RoomEngineEventResponder {
    func onEngineEvent(name: EngineEventCenter.RoomEngineEvent, param: [String : Any]?) {
        switch name {
        case .onAllUserCameraDisableChanged:
            guard let isDisable = param?["isDisable"] as? Bool else { return }
            viewResponder?.updateMuteAllVideoButtonState(isSelect: isDisable)
        case .onAllUserMicrophoneDisableChanged:
            guard let isDisable = param?["isDisable"] as? Bool else { return }
            viewResponder?.updateMuteAllAudioButtonState(isSelect: isDisable)
        default: break
        }
    }
}

private extension String {
    static var invitedTakeSeatText: String {
        localized("TUIRoom.invited.take.seat")
    }
    static var refusedTakeSeatInvitationText: String {
        localized("TUIRoom.refused.take.seat.invitation")
    }
    static var takeSeatInvitationTimeoutText: String {
        localized("TUIRoom.take.seat.invitation.timeout")
    }
    static var allMuteTitle: String {
        localized("TUIRoom.all.mute.title")
    }
    static var allMuteVideoTitle: String {
        localized("TUIRoom.all.mute.video.title")
    }
    static var allMuteMessage: String {
        localized("TUIRoom.all.mute.message")
    }
    static var allMuteVideoMessage: String {
        localized("TUIRoom.all.mute.video.message")
    }
    static var allUnmuteMessage: String {
        localized("TUIRoom.all.unmute.message")
    }
    static var allUnmuteVideoMessage: String {
        localized("TUIRoom.all.unmute.video.message")
    }
    static var allUnmuteTitle: String {
        localized("TUIRoom.all.unmute")
    }
    static var allUnmuteVideoTitle: String {
        localized("TUIRoom.all.unmute.video")
    }
    static var cancelText: String {
        localized("TUIRoom.cancel")
    }
    static var allMuteActionText: String {
        localized("TUIRoom.all.mute")
    }
    static var allMuteVideoActionText: String {
        localized("TUIRoom.all.mute.video")
    }
    static var confirmReleaseText: String {
        localized("TUIRoom.confirm.release")
    }
}
