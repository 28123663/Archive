#include "iot_keypad.h"



/**���̳�ʼ�� 
*@param		:�������ò���
*@return	TRUE: 	    �ɹ�
*           FALSE:      ʧ��
**/	
BOOL iot_keypad_init(                         
                        T_AMOPENAT_KEYPAD_CONFIG *pConfig
                  )
{
   return IVTBL(init_keypad)(  pConfig );
}

