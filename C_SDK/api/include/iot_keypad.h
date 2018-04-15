#ifndef __IOT_KEYPAD_H__
#define __IOT_KEYPAD_H__

#include "iot_os.h"

/**
 * @ingroup iot_sdk_device ����ӿ�
 * @{
 */
/**
 * @defgroup iot_sdk_keypad �����ӿ�
 * @{
 */

/**@example demo_lcd/src/demo_lcd.c
* LCD&���̽ӿ�ʾ��
*/ 

/**���̳�ʼ�� 
*@param		pConfig: �������ò���
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��
**/
BOOL iot_keypad_init(                         
                        T_AMOPENAT_KEYPAD_CONFIG *pConfig
                  );

/** @}*/
/** @}*/

#endif

