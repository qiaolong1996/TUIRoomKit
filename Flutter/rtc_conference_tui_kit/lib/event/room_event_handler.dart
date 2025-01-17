import 'package:rtc_conference_tui_kit/common/index.dart';
import 'package:rtc_conference_tui_kit/manager/rtc_engine_manager.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

class RoomEventHandler extends TUIRoomObserver {
  final int volumeCanHeardMinLimit = 10;
  final _store = RoomStore.to;
  RoomEventHandler() {
    super.onAllUserMicrophoneDisableChanged = (roomId, isDisable) {
      _store.roomInfo.isMicrophoneDisableForAllUser = isDisable;
      if (_store.currentUser.userRole.value == TUIRole.roomOwner) {
        return;
      }
      if (isDisable) {
        makeToast(msg: RoomContentsTranslations.translate('allMutePrompt'));
      } else {
        makeToast(msg: RoomContentsTranslations.translate('allUnMutePrompt'));
      }
      _store.updateItemTouchableState();
    };

    super.onAllUserCameraDisableChanged = (roomId, isDisable) {
      _store.roomInfo.isCameraDisableForAllUser = isDisable;
      if (_store.currentUser.userRole.value == TUIRole.roomOwner) {
        return;
      }
      if (isDisable) {
        makeToast(
            msg: RoomContentsTranslations.translate('disableAllVideoPrompt'));
      } else {
        makeToast(
            msg: RoomContentsTranslations.translate('enableAllVideoPrompt'));
      }
      _store.updateItemTouchableState();
    };

    super.onRemoteUserEnterRoom = (roomId, userInfo) {
      _store.addUser(userInfo, _store.userInfoList);
    };

    super.onRemoteUserLeaveRoom = (roomId, userInfo) {
      _store.removeUser(userInfo.userId, _store.userInfoList);
      if (_store.roomInfo.speechMode == TUISpeechMode.speakAfterTakingSeat) {
        _store.deleteInviteSeatUser(userInfo.userId);
      }
    };

    super.onUserVideoStateChanged = (userId, streamType, hasVideo, reason) {
      _store.updateUserVideoState(userId, hasVideo, reason, _store.userInfoList,
          isScreenStream: streamType == TUIVideoStreamType.screenStream);
      if (_store.roomInfo.speechMode == TUISpeechMode.speakAfterTakingSeat) {
        _store.updateUserVideoState(
            userId, hasVideo, reason, _store.seatedUserList,
            isScreenStream: streamType == TUIVideoStreamType.screenStream);
      }

      if (streamType == TUIVideoStreamType.screenStream) {
        var userModel = _store.getUserById(userId);
        if (userModel != null) {
          _store.screenShareUser = userModel;
          _store.isSharing.value = hasVideo;
        }
      }

      if (userId == _store.currentUser.userId.value) {
        _store.updateSelfVideoState(hasVideo, reason,
            isScreenStream: streamType == TUIVideoStreamType.screenStream);
      }
    };

    super.onUserAudioStateChanged = (userId, hasAudio, reason) {
      _store.updateUserAudioState(
          userId, hasAudio, reason, _store.userInfoList);
      if (_store.roomInfo.speechMode == TUISpeechMode.speakAfterTakingSeat) {
        _store.updateUserAudioState(
            userId, hasAudio, reason, _store.seatedUserList);
      }

      if (userId == _store.currentUser.userId.value) {
        _store.updateSelfAudioState(hasAudio, reason);
      }
    };

    super.onUserVoiceVolumeChanged = (volumeMap) {
      volumeMap.forEach((userId, volume) {
        bool isTalking = false;
        if (volume > volumeCanHeardMinLimit) {
          isTalking = true;
        }

        _store.updateUserTalkingState(userId, isTalking, _store.userInfoList);
        if (_store.roomInfo.speechMode == TUISpeechMode.speakAfterTakingSeat) {
          _store.updateUserTalkingState(
              userId, isTalking, _store.seatedUserList);
        }
      });
    };

    super.onUserRoleChanged = (String userId, TUIRole role) {
      if (role == TUIRole.roomOwner) {
        _store.roomInfo.ownerId = userId;
      }
      _store.updateUserRole(userId, role, _store.userInfoList);

      if (_store.roomInfo.speechMode == TUISpeechMode.speakAfterTakingSeat) {
        _store.updateUserRole(userId, role, _store.seatedUserList);
      }

      if (userId == _store.currentUser.userId.value) {
        _store.updateSelfRole(role);
      }
    };

    super.onSendMessageForUserDisableChanged =
        (String roomId, String userId, bool isDisable) {
      _store.updateUserMessageState(userId, isDisable, _store.userInfoList);
    };

    super.onSeatListChanged = (seatList, seatedList, leftList) async {
      for (var element in seatedList) {
        _store.updateUserSeatedState(element.userId, true);
        _store.deleteInviteSeatUser(element.userId);
        var result = await RoomEngineManager()
            .getRoomEngine()
            .getUserInfo(element.userId);
        if (result.code == TUIError.success) {
          _store.addUser(result.data!, RoomStore.to.seatedUserList);
        }
      }
      for (var element in leftList) {
        _store.updateUserSeatedState(element.userId, false);
        _store.removeUser(element.userId, RoomStore.to.seatedUserList);
      }
    };

    super.onRequestReceived = (request) {
      if (request.userId == RoomStore.to.currentUser.userId.value) {
        TUIRoomEngine.createInstance()
            .responseRemoteRequest(request.requestId, true);
      }
      switch (request.requestAction) {
        case TUIRequestAction.requestToTakeSeat:
          if (_store.roomInfo.speechMode ==
              TUISpeechMode.speakAfterTakingSeat) {
            var userModel = _store.getUserById(request.userId);
            if (_store.inviteSeatMap[request.userId] == null &&
                userModel != null) {
              _store.addInviteSeatUser(userModel, request);
            }
          }
        default:
          break;
      }
    };

    super.onRequestCancelled = (requestId, userId) {
      var cancelledUserId = userId;
      _store.inviteSeatMap.forEach((key, value) {
        if (value == requestId) {
          cancelledUserId = key;
        }
      });
      _store.deleteInviteSeatUser(cancelledUserId);
    };

    super.onKickedOffSeat = (userId) {
      makeToast(msg: RoomContentsTranslations.translate('kickedOffSeat'));
    };

    super.onKickedOutOfRoom = (roomId, reason, message) {
      _store.clearStore();
    };

    super.onRoomDismissed = (roomId) {
      _store.clearStore();
    };
  }
}
