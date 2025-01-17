
import RoomInfoH5 from './RoomInfoH5.vue';
import RoomInfoPc from './RoomInfoPC.vue';
import { isMobile }  from '../../../utils/useMediaValue';


const RoomInfo = isMobile ? RoomInfoH5 : RoomInfoPc;

export default RoomInfo;

