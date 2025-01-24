<template>
  <room
    ref="TUIRoomRef"
    @on-log-out="handleLogOut"
    @on-create-room="onCreateRoom"
    @on-enter-room="onEnterRoom"
    @on-destroy-room="onDestroyRoom"
    @on-exit-room="onExitRoom"
    @on-kicked-out-of-room="onKickedOutOfRoom"
    @on-kick-off-line="onKickedOffLine"
    @on-user-sig-expired="onUserSigExpired"
  ></room>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import Room from '@/TUIRoom/index.vue';
import { useRoute } from 'vue-router';
import router from '@/router';
import { checkNumber } from '@/TUIRoom/utils/common';
import { useI18n } from 'vue-i18n';
import TUIMessageBox from '@/TUIRoom/components/common/base/MessageBox/index';
import {
  TUIKickedOutOfRoomReason,
} from '@tencentcloud/tuiroom-engine-js';
import logger from '@/TUIRoom/utils/common/logger';
import { useBasicStore } from '../TUIRoom/stores/basic';
import { useRoomStore } from '../TUIRoom/stores/room';

const { t } = useI18n();

const route = useRoute();
const basicStore = useBasicStore();
const roomStore = useRoomStore();
const roomInfo = sessionStorage.getItem('tuiRoom-roomInfo');
const userInfo = sessionStorage.getItem('tuiRoom-userInfo');

const roomId = checkNumber((route.query.roomId) as string) ? route.query.roomId : '';

if (!roomId) {
  router.push({ path: 'home' });
} else if (!roomInfo) {
  router.push({ path: 'home', query: { roomId } });
}

const TUIRoomRef = ref();

onMounted(async () => {
  const { action, roomMode, roomParam, hasCreated } = JSON.parse(roomInfo as string);
  const { sdkAppId, userId, userSig, userName, avatarUrl } = JSON.parse(userInfo as string);
  try {
    await TUIRoomRef.value?.init({
      sdkAppId,
      userId,
      userSig,
      userName,
      avatarUrl,
    });
    if (action === 'createRoom' && !hasCreated) {
      try {
        await TUIRoomRef.value?.createRoom({ roomId, roomName: roomId, roomMode, roomParam });
        const newRoomInfo = { action, roomId, roomName: roomId, roomMode, roomParam, hasCreated: true };
        sessionStorage.setItem('tuiRoom-roomInfo', JSON.stringify(newRoomInfo));
      } catch (error: any) {
        const message = t('Failed to enter the room.') + error.message;
        TUIMessageBox({
          title: t('Note'),
          message,
          confirmButtonText: t('Sure'),
          appendToRoomContainer: true,
          callback: async () => {
            router.replace({ path: 'home' });
          },
        });
      }
    } else {
      try {
        await TUIRoomRef.value?.enterRoom({ roomId, roomParam });
      } catch (error: any) {
        const message = t('Failed to enter the room.') + error.message;
        TUIMessageBox({
          title: t('Note'),
          message,
          confirmButtonText: t('Sure'),
          appendToRoomContainer: true,
          callback: async () => {
            router.replace({ path: 'home' });
          },
        });
      }
    }
  } catch (error: any) {
    const message = t('Failed to enter the room.') + error.message;
    TUIMessageBox({
      title: t('Note'),
      message,
      confirmButtonText: t('Sure'),
      appendToRoomContainer: true,
      callback: async () => {
        sessionStorage.removeItem('tuiRoom-currentUserInfo');
        router.replace({ path: 'home' });
      },
    });
  }
});

router.beforeEach((from: any, to: any, next: any) => {
  // 解散房间后改变路由或者不改变路由和 roomId 参数的情况下不做处理
  if (!basicStore.roomId || (from.path === to.path && from.query.roomId === to.query.roomId)) {
    next();
  } else {
    const message = roomStore.isMaster
      ? t('This action causes the room to be disbanded, does it continue?')
      : t('This action causes the room to be exited, does it continue?');
    if (window.confirm(message)) {
      if (roomStore.isMaster) {
        TUIRoomRef.value?.dismissRoom();
      } else {
        TUIRoomRef.value?.leaveRoom();
      }
      TUIRoomRef.value?.resetStore();
      next();
    } else {
      next(false);
    }
  }
});
/**
 * Processing users click [Logout Login] in the upper left corner of the page
 * 处理用户点击页面左上角【退出登录】
**/
function handleLogOut() {
/**
 * The accessor handles the logout method
 * 接入方处理 logout 方法
**/
}

/**
 * Hosts create room callbacks
 * 主持人创建房间回调
**/
function onCreateRoom(info: { code: number; message: string }) {
  logger.debug('onEnterRoom:', info);
}

/**
 * Ordinary members enter the room callback
 * 普通成员进入房间回调
**/
function onEnterRoom(info: { code: number; message: string }) {
  logger.debug('onCreateRoom:', info);
}

/**
 * Hosts destroy room callbacks
 * 主持人销毁房间回调
**/
const onDestroyRoom = (info: { code: number; message: string }) => {
  logger.debug('onDestroyRoom:', info);
  sessionStorage.removeItem('tuiRoom-roomInfo');
  router.replace({ path: '/home' });
};

/**
 * Ordinary members exit the room callback
 * 普通成员退出房间回调
**/
const onExitRoom = (info: { code: number; message: string }) => {
  logger.debug('onExitRoom:', info);
  sessionStorage.removeItem('tuiRoom-roomInfo');
  router.replace({ path: '/home' });
};

/**
 * Ordinary members were kicked out of the room by the host
 * 普通成员被主持人踢出房间
**/
const onKickedOutOfRoom = (info: { roomId: string; reason: TUIKickedOutOfRoomReason, message: string }) => {
  logger.debug('onKickedOutOfRoom:', info);
  sessionStorage.removeItem('tuiRoom-roomInfo');
  router.replace({ path: '/home' });
};

/**
 * Users are kicked offline
 * 被踢下线
 */
const onKickedOffLine = (info: { message: string }) => {
  logger.debug('onKickedOffLine:', info);
  sessionStorage.removeItem('tuiRoom-roomInfo');
  router.replace({ path: '/home' });
};

/**
 * Ordinary members were kicked out of the room by the host
 * userSig 过期，需要获取新的 userSig
 */
const onUserSigExpired = () => {
  logger.debug('onUserSigExpired');
  sessionStorage.removeItem('tuiRoom-roomInfo');
  sessionStorage.removeItem('tuiRoom-currentUserInfo');
  router.replace({ path: '/home' });
};
</script>

<style lang="scss">
#app {
  font-family: PingFang SC;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  position: relative;
  width: 100%;
  height: 100%;
}
</style>
