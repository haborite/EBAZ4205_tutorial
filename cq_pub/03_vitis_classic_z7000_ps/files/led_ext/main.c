/**
* @file xgpio_example.c
*
* This file contains a design example using the AXI GPIO driver (XGpio) and
* hardware device.  It only uses channel 1 of a GPIO device and assumes that
* the bit 0 of the GPIO is connected to the LED on the HW board.
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"

/************************** Constant Definitions *****************************/

/* Assumes bit 0-2 of GPIO is connected to an LED  */
#define LED1 0x01
#define LED2 0x02
#define LED3 0x04

#define GPIO_DEVICE_ID  XPAR_GPIO_0_DEVICE_ID

/*
 * The following constant is used to wait after an LED is turned on to make
 * sure that it is visible to the human eye.  This constant might need to be
 * tuned for faster or slower processor speeds.
 */
#define LED_DELAY     50000000

/*
 * The following constant is used to determine which channel of the GPIO is
 * used for the LED if there are 2 channels supported.
 */
#define GPIO_CHANNEL 1

/**************************** Type Definitions *******************************/


/************************** Variable Definitions *****************************/

XGpio Gpio; /* The Instance of the GPIO Driver */

/*****************************************************************************/
/**
*
* The purpose of this function is to illustrate how to use the GPIO
* driver to turn on and off an LED.
*
*
* @return	XST_FAILURE to indicate that the GPIO Initialization had
*		failed.
*
* @note		This function will not return if the test is running.
*
******************************************************************************/
int main(void)
{
	int Status;
	volatile int Delay;

	/* Initialize the GPIO driver */
	Status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);

	if (Status != XST_SUCCESS) {
		xil_printf("Gpio Initialization Failed\r\n");
		return XST_FAILURE;
	}

	/* Set the direction for all signals as inputs except the LED output */
	/* Output: set bit to 0, Input: set bit to 1 */
	XGpio_SetDataDirection(&Gpio, GPIO_CHANNEL, 0);

	/* Loop forever blinking the LED */
    int num = 0;

	while (1) {
        xil_printf("LED %d\r\n", num);
		/* Set the LED to ON */
		XGpio_DiscreteWrite(&Gpio, GPIO_CHANNEL, num & 0x7);

		/* Wait a small amount of time so the LED is visible */
		for (Delay = 0; Delay < LED_DELAY; Delay++);

		num++;

		if(num > 7){
			num = 0;
		}
	}

}
