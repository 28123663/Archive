#include "iot_touchscreen.h"


/**��������ʼ���ӿ�
*@param		:	������Ϣ�ص�����
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��
**/

BOOL iot_init_touchScreen(
				PTOUCHSCREEN_MESSAGE pTouchScreenMessage
				)
{
	return IVTBL(init_touchScreen)(pTouchScreenMessage);
}


/**������˯�߽ӿ�
*@param		:	�Ƿ�Ҫ˯��
*@return		: 	   
**/

VOID iot_touchScreen_sleep(
						BOOL sleep
						)
{
	
	return IVTBL(touchScreenSleep)(sleep);
}

