`include "pronoc_def.v"



package dpi_int_pkg;

parameter NOC_ID=0;

`NOC_CONF

 typedef struct packed {
     logic [NEw-1 : 0] dest  ;
     logic [PCK_SIZw-1 : 0] size  ;
     logic [NEw-1 : 0] src   ;
     logic [31:0]      id    ;
     logic             valid ;
 } req_t;  

 typedef struct packed {
     logic [31:0]      id    ;
     logic             valid ;
 } deliver_t;  

endpackage
