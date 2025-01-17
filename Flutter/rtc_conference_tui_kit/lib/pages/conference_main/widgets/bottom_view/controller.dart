import 'dart:io';

import 'package:get/get.dart';
import 'package:rtc_conference_tui_kit/common/index.dart';
import 'package:rtc_conference_tui_kit/manager/rtc_engine_manager.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';

class BottomViewController extends GetxController {
  BottomViewController();

  static const _seatIndex = -1;
  static const _reqTimeout = 0;

  final isUnfold = false.obs;
  final showMoreButton = false.obs;
  final isRequestingTakeSeat = false.obs;
  final isSeatMode = false.obs;

  late RoomEngineManager _engineManager;
  late RoomStore _store;
  late String _takeSeatRequestId;

  @override
  void onInit() {
    super.onInit();
    _engineManager = RoomEngineManager();
    _store = RoomStore.to;
    _takeSeatRequestId = '';
    isSeatMode.value =
        _store.roomInfo.speechMode == TUISpeechMode.speakAfterTakingSeat;
  }

  void muteAudioAction() {
    if (_isOffSeatInSeatMode()) {
      return;
    }

    if (_store.currentUser.hasAudioStream.value) {
      _engineManager.muteLocalAudio();
      return;
    }
    if (_store.roomInfo.isMicrophoneDisableForAllUser &&
        _store.currentUser.userRole.value != TUIRole.roomOwner) {
      makeToast(msg: RoomContentsTranslations.translate('muteRoomReason'));
      return;
    }
    _engineManager.unMuteLocalAudio();
  }

  void muteVideoAction() {
    if (_isOffSeatInSeatMode()) {
      return;
    }

    if (_store.currentUser.hasVideoStream.value) {
      _engineManager.closeLocalCamera();
      return;
    }
    if (_store.roomInfo.isCameraDisableForAllUser &&
        _store.currentUser.userRole.value != TUIRole.roomOwner) {
      makeToast(
          msg: RoomContentsTranslations.translate('disableVideoRoomReason'));
      return;
    }
    _engineManager.openLocalCamera();
  }

  bool _isOffSeatInSeatMode() {
    if (isSeatMode.value && !_store.currentUser.isOnSeat.value) {
      makeToast(
        msg: RoomContentsTranslations.translate('raiseHandTip'),
      );
      return true;
    }
    return false;
  }

  void _startScreenSharing() {
    if (_isOffSeatInSeatMode()) {
      return;
    }

    if (_store.isSharing.value &&
        _store.screenShareUser.userId.value !=
            _store.currentUser.userId.value) {
      makeToast(
        msg: RoomContentsTranslations.translate('otherUserScreenSharing'),
      );
      return;
    }

    String appGroup = '';
    if (Platform.isIOS) {
      //TODO appGroup
    }
    _engineManager.startScreenSharing(appGroup: appGroup);
  }

  void onScreenShareButtonPressed() {
    if (_store.currentUser.hasScreenStream.value) {
      _engineManager.stopScreenSharing();
    } else {
      _startScreenSharing();
    }
  }

  void raiseHandAction() {
    if (_store.currentUser.isOnSeat.value) {
      return;
    }
    if (!isRequestingTakeSeat.value) {
      isRequestingTakeSeat.value = true;
      if (RoomStore.to.currentUser.userRole.value != TUIRole.administrator) {
        makeToast(
          msg: RoomContentsTranslations.translate('joinStageApplicationSent'),
        );
      }
      _takeSeatRequestId = _engineManager
          .takeSeat(
            _seatIndex,
            _reqTimeout,
            TUIRequestCallback(
              onAccepted: (requestId, userId) {
                makeToast(
                  msg: RoomContentsTranslations.translate(
                      'takeSeatRequestAgreed'),
                );
                isRequestingTakeSeat.value = false;
              },
              onRejected: (requestId, userId, message) {
                makeToast(
                  msg: RoomContentsTranslations.translate(
                      'takeSeatRequestRejected'),
                );
                isRequestingTakeSeat.value = false;
              },
              onCancelled: (requestId, userId) {
                isRequestingTakeSeat.value = false;
              },
              onTimeout: (requestId, userId) {
                isRequestingTakeSeat.value = false;
              },
              onError: (requestId, userId, error, message) {
                isRequestingTakeSeat.value = false;
              },
            ),
          )
          .requestId;
    } else {
      _engineManager.cancelRequest(_takeSeatRequestId);
      _takeSeatRequestId = '';

      makeToast(
        msg:
            RoomContentsTranslations.translate('joinStageApplicationCancelled'),
      );
      isRequestingTakeSeat.value = false;
    }
  }

  void leaveSeat() {
    showConferenceDialog(
      title: RoomContentsTranslations.translate('leaveSeatTitle'),
      message: RoomContentsTranslations.translate('leaveSeatMessage'),
      confirmText: RoomContentsTranslations.translate('leaveSeat'),
      cancelText: RoomContentsTranslations.translate('cancel'),
      onConfirm: () {
        _engineManager.leaveSeat();
        Get.back();
      },
    );
  }

  bool isMicAndCameraButtonVisible() {
    return !isSeatMode.value ||
        RoomStore.to.currentUser.isOnSeat.value ||
        RoomStore.to.currentUser.userRole.value == TUIRole.administrator;
  }

  bool isRaiseHandButtonVisible() {
    return isSeatMode.value &&
        RoomStore.to.currentUser.userRole.value != TUIRole.roomOwner;
  }

  bool isRaiseHandListButtonVisible() {
    return isSeatMode.value &&
        RoomStore.to.currentUser.userRole.value != TUIRole.generalUser;
  }

  bool isScreenShareButtonInBaseRow() {
    return !isSeatMode.value ||
        RoomStore.to.currentUser.userRole.value != TUIRole.administrator;
  }

  bool isInviteButtonInBaseRow() {
    return !isSeatMode.value ||
        !RoomStore.to.currentUser.isOnSeat.value &&
            RoomStore.to.currentUser.userRole.value != TUIRole.administrator;
  }

  bool isSettingButtonInBaseRow() {
    return isSeatMode.value &&
        !RoomStore.to.currentUser.isOnSeat.value &&
        RoomStore.to.currentUser.userRole.value != TUIRole.administrator;
  }
}
