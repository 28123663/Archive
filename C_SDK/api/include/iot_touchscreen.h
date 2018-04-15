#ifndef __IOT_TOUCHSCREEN_H__
#define __IOT_TOUCHSCREEN_H__

#include "iot_os.h"

/**
 * @ingroup iot_sdk_device ����ӿ�
 * @{
 */
/**
 * @defgroup iot_sdk_lcd lcd�ӿ�
 * @{
 */
 
/**@example demo_ui/src/demo_ui.c
* LCD&�������ӿ�ʾ��
*/ 

/**��ʼ��������
*@param		pTouchScreenMessage:	�������ص�����
*@return	TRUE: 	    �ɹ�
*             FALSE:      ʧ��
**/

BOOL iot_init_touchScreen(PTOUCHSCREEN_MESSAGE pTouchScreenMessage);


/**������˯�߽ӿ�
*@param		sleep:	�Ƿ�Ҫ˯��
*@return	: 	   
**/

VOID iot_touchScreen_sleep(BOOL sleep);

/** @}*/
/** @}*/
#endif

