#include "iot_camera.h"

/**����ͷ��ʼ��
*@param		cameraParam:		��ʼ������
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��
**/
BOOL iot_camera_init(T_AMOPENAT_CAMERA_PARAM *cameraParam)
{
  return IVTBL(camera_init)(cameraParam);
}

/**������ͷ
*@param		videoMode:		�Ƿ���Ƶģʽ
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��
**/
BOOL iot_camera_poweron(BOOL videoMode)
{
  return IVTBL(camera_poweron)(videoMode);
}
/**�ر�����ͷ
*@return  TRUE:       �ɹ�
*           FALSE:      ʧ��
**/
BOOL iot_camera_poweroff(void)
{
  return IVTBL(camera_poweroff)();
}
/**��ʼԤ��
*@param  previewParam:       Ԥ������
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��

**/
BOOL iot_camera_preview_open(T_AMOPENAT_CAM_PREVIEW_PARAM *previewParam)
{
  return IVTBL(camera_preview_open)(previewParam);
}
/**�˳�Ԥ��
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��

**/
BOOL iot_camera_preview_close(void)
{
  return IVTBL(camera_preview_close)();
}
/**����
*@param  captureParam:       Ԥ������
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��
**/
BOOL iot_camera_capture(T_AMOPENAT_CAM_CAPTURE_PARAM *captureParam)
{ 
  return IVTBL(camera_capture)(captureParam);
}
/**������Ƭ
*@param  iFd:       ���������Ƭ�ļ����
*@return  TRUE:       �ɹ�
*           FALSE:      ʧ��
**/
BOOL iot_camera_save_photo( INT32 iFd)
{
  return IVTBL(camera_save_photo)(iFd);
}