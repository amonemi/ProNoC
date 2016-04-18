#ifndef LCD_H
	#define        LCD_H

	#define        lcd_set_8_bit_1_line() 		lcd_wr_cmd_func(0x30)
	#define        lcd_set_8_bit_2_line()		lcd_wr_cmd_func(0x38)
	#define        lcd_set_4_bit_1_line() 		lcd_wr_cmd_func(0x20)
	#define        lcd_set_4_bit_3_line()		lcd_wr_cmd_func(0x28)
	#define        lcd_entry_mode()			lcd_wr_cmd_func(0x06)
//(clearing display without clearing ddram content)
	#define        lcd_dsply_off_cursor_off() 	lcd_wr_cmd_func(0x08)
	#define        lcd_dsply_on_cursor_on()		lcd_wr_cmd_func(0x0e)
	#define        lcd_dsply_on_cursor_off()	lcd_wr_cmd_func(0x0c)
	#define        lcd_dsply_on_cursor_blink()	lcd_wr_cmd_func(0x0f)
	#define        lcd_shift_dsply_left() 		lcd_wr_cmd_func(0x18)
	#define        lcd_shift_dsply_right()	 	lcd_wr_cmd_func(0x1c)
	#define        lcd_shift_cursor_left() 		lcd_wr_cmd_func(0x10)
	#define        lcd_shift_cursor_right()		lcd_wr_cmd_func(0x14)
//(also clear ddram content)
	#define        lcd_clr_dsply()			lcd_wr_cmd_func(0x01)
	#define	       lcd_line1()       		lcd_wr_cmd_func(0x80) //< address offset for 1st line in 2-line display mode
   	#define	       lcd_line2()       		lcd_wr_cmd_func(0xc0)  ///< address offset for 2nd line in 2-line display mode
	



void lcd_wait(){
	unsigned int volatile num=20000;	
	while (num>0){ 
		num--;
		asm volatile ("nop");
	}
	return;
}


inline void lcd_wr_cmd_func( char data){
	LCD_WR_CMD= data;
	lcd_wait();
}

inline void lcd_wr_data_func( char data){
	LCD_WR_DATA=data;
	lcd_wait();
}






void lcd_init()
{
  lcd_set_8_bit_2_line();
  lcd_dsply_on_cursor_off();
  lcd_clr_dsply();
  lcd_entry_mode();
  lcd_line1();
}

//-------------------------------------------------------------------------
void lcd_show_text(char* Text, unsigned char length)
{
  int i;
  for(i=0;i<length;i++) lcd_wr_data_func(Text[i]); 
}


//-------------------------------------------------------------------------
void lcd_test()
{
  char Text1[17] = "LCD 2x16 test";
  char Text2[17] = "  ProNoC SoC    ";
  //  Initial LCD
  lcd_init();
  //  Show Text to LCD
  lcd_show_text(Text1,13);
  //  Change Line2
  lcd_line2();
  //  Show Text to LCD
  lcd_show_text(Text2,16);
}
//-------------------------------------------------------------------------

#endif
