import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rtc_conference_tui_kit/common/index.dart';

import '../index.dart';
import 'widgets.dart';

class UserControlWidget extends GetView<UserListController> {
  final UserModel userModel;

  const UserControlWidget({Key? key, required this.userModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      width: Get.width,
      height: controller.getUserControlWidgetHeight(userModel),
      child: Column(
        children: [
          const DropDownButton(),
          UserInfoWidget(userModel: userModel),
          SizedBox(height: 10.0.scale375()),
          Visibility(
            visible: userModel.isOnSeat.value || !controller.isSeatMode(),
            child: UserControlItemWidget(
              onPressed: () {
                Get.back();
                controller.muteAudioAction(userModel);
              },
              text: RoomContentsTranslations.translate(
                  controller.isSelf(userModel) ? 'unmute' : 'requestOpenAudio'),
              selectedText: RoomContentsTranslations.translate('mute'),
              image: Image.asset(
                AssetsImages.roomMuteAudio,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              selectedImage: Image.asset(
                AssetsImages.roomUnMuteAudio,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: userModel.hasAudioStream,
            ),
          ),
          Visibility(
            visible: userModel.isOnSeat.value || !controller.isSeatMode(),
            child: UserControlItemWidget(
              onPressed: () {
                Get.back();
                controller.muteVideoAction(userModel);
              },
              text: RoomContentsTranslations.translate(
                  controller.isSelf(userModel)
                      ? 'openVideo'
                      : 'requestOpenVideo'),
              selectedText: RoomContentsTranslations.translate('closeVideo'),
              image: Image.asset(
                AssetsImages.roomMuteVideo,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              selectedImage: Image.asset(
                AssetsImages.roomUnMuteVideo,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: userModel.hasVideoStream,
            ),
          ),
          if (controller.isOwner() && !controller.isSelf(userModel)) ...[
            UserControlItemWidget(
              onPressed: () {
                Get.back();
                controller.transferHostAction(userModel.userId.value);
              },
              text: RoomContentsTranslations.translate('changeHost'),
              image: Image.asset(
                AssetsImages.roomChangeHost,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: false.obs,
            ),
            UserControlItemWidget(
              onPressed: () {
                Get.back();
                controller.changeAdministratorAction(userModel);
              },
              text: RoomContentsTranslations.translate('setAsAdministrator'),
              selectedText:
                  RoomContentsTranslations.translate('undoAdministrator'),
              image: Image.asset(
                AssetsImages.roomSetAdministrator,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              selectedImage: Image.asset(
                AssetsImages.roomUndoAdministrator,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: controller.isAdministrator(userModel).obs,
            ),
            Divider(
                height: 3.0.scale375(),
                thickness: 3.0.scale375(),
                color: RoomColors.dividerGrey),
          ],
          Visibility(
            visible: !controller.isSelf(userModel) &&
                (controller.isOwner() ||
                    controller.isAdministrator(RoomStore.to.currentUser)),
            child: UserControlItemWidget(
              onPressed: () {
                Get.back();
                controller.disableMessageAction(userModel);
              },
              text: RoomContentsTranslations.translate('enableMessage'),
              selectedText:
                  RoomContentsTranslations.translate('disableMessage'),
              image: Image.asset(
                AssetsImages.roomEnableMessage,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              selectedImage: Image.asset(
                AssetsImages.roomDisableMessage,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: userModel.ableSendingMessage,
            ),
          ),
          Visibility(
            visible: !controller.isSelf(userModel) &&
                controller.isSeatMode() &&
                (controller.isOwner() ||
                    controller.isAdministrator(RoomStore.to.currentUser)),
            child: UserControlItemWidget(
              onPressed: () {
                controller.changeSeatStatusAction(userModel);
                Get.back();
              },
              text: RoomContentsTranslations.translate('inviteToTakeSeat'),
              selectedText: RoomContentsTranslations.translate('kickOffSeat'),
              image: Image.asset(
                AssetsImages.roomRequestOnSeat,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              selectedImage: Image.asset(
                AssetsImages.roomKickOffSeat,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: userModel.isOnSeat,
            ),
          ),
          Visibility(
            visible: controller.isOwner() && !controller.isSelf(userModel),
            child: UserControlItemWidget(
              onPressed: () {
                Get.back();
                controller.kickOutAction(userModel);
              },
              text: RoomContentsTranslations.translate('kick'),
              image: Image.asset(
                AssetsImages.roomKickOutRoom,
                package: 'rtc_conference_tui_kit',
                width: 20.0.scale375(),
                height: 20.0.scale375(),
              ),
              isSelected: false.obs,
              textStyle: RoomTheme.defaultTheme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
