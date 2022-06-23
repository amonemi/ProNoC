import pronoc_pkg::*; 


package dpi_int_pkg;


 typedef struct packed {
     logic [pronoc_pkg::NEw-1 : 0] dest  ;
     logic [pronoc_pkg::PCK_SIZw-1 : 0] size  ;
     logic [pronoc_pkg::NEw-1 : 0] src   ;
     logic [31:0]      id    ;
     logic             valid ;
 } req_t;  

 typedef struct packed {
     logic [31:0]      id    ;
     logic             valid ;
 } deliver_t;  

endpackage
