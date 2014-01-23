/*********************************************************************
							
	File: parameter.v 
	
	Copyright (C) 2014  Alireza Monemi

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	
	Purpose:
	aeMB Ip core parameter defination 
	
	Info: monemi@fkegraduate.utm.my
*********************************************************************/



//slave device number  



`ifdef	ADD_BUS_LOCALPARAM

	localparam MASTER_NUM					=	2+NOC_EN;		//number of master port
	localparam SLAVE_NUM						=	RAM_EN + GPIO_EN	+ NOC_EN ;		//number of slave port
	
	localparam	ADDR_PERFIX		=	8;

	// addrees range  definition 

	localparam	RAM_ADDR_START	=	8'H00;		// 32'H00000000	to 32'H3FFFFFFF
	localparam	RAM_BK_NUM		=	8'H3F;	

	
	localparam	NOC_ADDR_START	=	8'H40	;		// 32'H40000000	to 32'H40FFFFFF
	localparam	NOC_BK_NUM		=	8'H01;
	
	localparam	GPIO_ADDR_START=	8'H41;		// 32'H41000000	to 32'H41FFFFFF
	localparam	GPIO_BK_NUM		=	8'H01		;	 
	
	
	

	// salve and master coonection port definition 


	localparam	RAM_ID			=	0;
	localparam	RAM_ID_E			=	0;
	
	localparam	NOC_S_ID			=	(	NOC_EN	) ? RAM_ID_E	+	1	:	255;
	localparam	NOC_S_ID_E		=	RAM_ID_E		+	NOC_EN;
	
	localparam	GPIO_ID			=	(	GPIO_EN	) ? NOC_S_ID_E	+	1	:	255;
	localparam	GPIO_ID_E		=	NOC_S_ID_E	+	GPIO_EN ;
		
		
	
	//master device number
	localparam	IWB_ID			=	0;
	localparam	IWB_ERR_EN		=	0;
	localparam  IWB_RTY_EN		=	0;
	
	
	localparam	DWB_ID			=	1;
	localparam	DWB_ERR_EN		=	0;
	localparam  DWB_RTY_EN		=	0;
	
	localparam	NOC_M_ID 		= (	NOC_EN	) ? 2	:	255;
	localparam	NOC_M_ID_E		=	2	+	NOC_EN;
	localparam	NOC_M_ERR_EN	=	0;
	localparam  NOC_M_RTY_EN	=	0;
	
	localparam	ERR_EN_ARRAY	=	(IWB_ERR_EN	<< IWB_ERR_EN)|
											(DWB_ERR_EN	<< DWB_ERR_EN)|
											((NOC_EN*NOC_M_ERR_EN)<< NOC_M_ID) ;
												
	localparam	RTY_EN_ARRAY	=	(IWB_RTY_EN	<< IWB_RTY_EN)|
											(DWB_RTY_EN	<< DWB_RTY_EN)|
											((NOC_EN&NOC_M_RTY_EN)<< NOC_M_ID) ;

	localparam	NI_BASE_ADDR	=	{NOC_ADDR_START,{32-ADDR_PERFIX{1'b0}}};
	`endif	
	
	
	

	
