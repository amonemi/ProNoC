`include "pronoc_def.v"
/**********************************************************************
**    File:  mesh_torus_noc_top.v
**    
**    Copyright (C) 2014-2017  Alireza Monemi
**    
**    This file is part of ProNoC 
**
**    ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**    you can redistribute it and/or modify it under the terms of the GNU
**    Lesser General Public License as published by the Free Software Foundation,
**    either version 2 of the License, or (at your option) any later version.
**
**     ProNoC is distributed in the hope that it will be useful, but WITHOUT
**     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**     or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**     Public License for more details.
**
**     You should have received a copy of the GNU Lesser General Public
**     License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**    Description: 
**    the NoC top module. It generate one of the mesh, torus, ring, or line  topologies by 
**    connecting routers  
**
**************************************************************/

module mesh_torus_noc_top  (
    reset,
    clk,
    chan_in_all,
    chan_out_all,
    router_event
);
    
     import pronoc_pkg::*;

    input   clk,reset;
    //Endpoints ports 
    input   smartflit_chanel_t chan_in_all  [NE-1 : 0];
    output  smartflit_chanel_t chan_out_all [NE-1 : 0];
    
    //Events
    output  router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
    
    //all routers port 
    smartflit_chanel_t    router_chan_in   [NR-1 :0][MAX_P-1 : 0];
    smartflit_chanel_t    router_chan_out  [NR-1 :0][MAX_P-1 : 0];
    
    router_config_t router_config_in [NR-1 :0];
    
    //Unused Input channels are connected to ground
    smartflit_chanel_t is_grounded;
    assign  is_grounded= {SMARTFLIT_CHANEL_w{1'b0}};   
    
    genvar x,y,l;
    generate 
    if( IS_RING | IS_LINE) begin : ring_line 
        for  (x=0;   x<NX; x=x+1) begin :R_
            localparam RID =  x;
            assign router_config_in[x].router_addr = RID[RAw-1: 0];
            assign router_config_in[x].router_id = RID[NRw-1: 0];
            router_top #(
                .ROUTER_ID(RID),
                .P (MAX_P)
            ) the_router (
                .router_config_in(router_config_in[RID]),
                .chan_in(router_chan_in [RID]), 
                .chan_out(router_chan_out[RID]), 
                .router_event(router_event[RID]),
                .clk(clk), 
                .reset(reset)
            );
            
            assign router_chan_in[x][FORWARD] = 
                (x < NX-1) ?  router_chan_out[x+1][BACKWARD] : 
                (IS_LINE) ?   is_grounded : router_chan_out[0][BACKWARD];
            
            assign router_chan_in[x][BACKWARD] = 
                (x > 0) ? router_chan_out[x-1][FORWARD] : 
                (IS_LINE) ? is_grounded : router_chan_out[NX-1][FORWARD];
            
            // connect other local ports
            for  (l=0;   l<NL; l=l+1) begin :locals
                    localparam ENDPID = fmesh_endp_id(x,0,l); 
                    localparam LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
                    assign router_chan_in[x][LOCALP]= chan_in_all [ENDPID];
                    assign chan_out_all [ENDPID] = router_chan_out[x][LOCALP];
            end// locals
        end//x    
        
    end else begin :mesh_torus
        for (y=0; y<NY; y=y+1) begin: Y_
            for (x=0; x<NX; x=x+1) begin :X_
                localparam R_ADDR = (y<<NXw) + x;
                localparam RID = (y * NX) + x;
                //FMESH IDs
                localparam EAST_ID = NX*NY*NL + 2*NX + NY +y;
                localparam NORTH_ID = NX*NY*NL + x; 
                localparam WEST_ID = NX*NY*NL +2*NX + y;
                localparam SOUTH_ID = NX*NY*NL + NX + x;  
                
                assign router_config_in[RID].router_addr = R_ADDR[RAw-1 :0];
                assign router_config_in[RID].router_id = RID[NRw-1: 0];
                
                router_top #(
                    .ROUTER_ID(RID),
                    .P(MAX_P)
                ) the_router (
                    .router_config_in(router_config_in[RID]), 
                    .chan_in(router_chan_in [RID]), 
                    .chan_out(router_chan_out[RID]), 
                    .router_event(router_event[RID]),
                    .clk(clk), 
                    .reset(reset)
                );
                /*
                in [x,y][east] <------  out [x+1 ,y  ][west] ;
                in [x,y][north] <------ out [x   ,y-1][south] ;
                in [x,y][west] <------  out [x-1 ,y  ][east] ;
                in [x,y][south] <------ out [x   ,y+1][north] ;
                 */
                assign router_chan_in[fmesh_router_id(x, y)][EAST] = 
                    (x < NX-1) ? router_chan_out[fmesh_router_id(x+1, y)][WEST] : //not_last_x
                    (IS_MESH)  ? is_grounded :                     //last_x_mesh
                    (IS_TORUS) ? router_chan_out[fmesh_router_id(0, y)][WEST] :   //last_x_torus
                                 chan_in_all[EAST_ID];                            //last_x_fmesh
                assign router_chan_in[fmesh_router_id(x, y)][NORTH] = 
                    (y > 0  ) ? router_chan_out[fmesh_router_id(x, y-1)][SOUTH] :  //not_first_y
                    (IS_MESH) ? is_grounded :                       //first_y_mesh
                    (IS_TORUS)? router_chan_out[fmesh_router_id(x, NY-1)][SOUTH] : //first_y_torus
                                chan_in_all[NORTH_ID];                            //first_y_fmesh
                assign router_chan_in[fmesh_router_id(x, y)][WEST] = 
                    (x > 0)   ? router_chan_out[fmesh_router_id(x-1, y)][EAST] :  //not_first_x
                    (IS_MESH) ? is_grounded :                      //first_x_mesh
                    (IS_TORUS)? router_chan_out[fmesh_router_id(NX-1, y)][EAST] : //first_x_torus
                                chan_in_all[WEST_ID];                             //first_x_fmesh
                assign router_chan_in[fmesh_router_id(x, y)][SOUTH] = 
                    (y < NY-1)? router_chan_out[fmesh_router_id(x, y+1)][NORTH] : //not_last_y
                    (IS_MESH)?  is_grounded :                      //last_y_mesh
                    (IS_TORUS)? router_chan_out[fmesh_router_id(x, 0)][NORTH] :   //last_y_torus
                                chan_in_all[SOUTH_ID];                   //last_y_fmesh
                if(IS_FMESH) begin :fmesh //connect to endpoints
                    if(x == NX-1)  assign chan_out_all [EAST_ID] = router_chan_out [fmesh_router_id(x,y)][EAST];
                    if(y ==0 )     assign chan_out_all [NORTH_ID] = router_chan_out [fmesh_router_id(x,y)][NORTH];
                    if (x ==0 )    assign chan_out_all [WEST_ID] = router_chan_out[fmesh_router_id(x, y)][WEST];
                    if(y == NY-1 ) assign chan_out_all [SOUTH_ID] = router_chan_out[fmesh_router_id(x, y)][SOUTH];
                end
                // endpoint(s) connection
                // connect other local ports
                for  (l=0;   l<NL; l=l+1) begin :locals
                    localparam ENDPID = fmesh_endp_id(x,y,l); 
                    localparam LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the end  
                    localparam ENDP_ADDR = {l,R_ADDR[RAw-1: 0]};
                    assign router_chan_in [fmesh_router_id(x,y)][LOCALP] =    chan_in_all [ENDPID];
                    assign chan_out_all [ENDPID] = router_chan_out [fmesh_router_id(x,y)][LOCALP];            
                    assign router_config_in[RID].endp_addrs[(l+1)*EAw -1 :  l*EAw] = ENDP_ADDR[EAw-1:0];
                    assign router_config_in[RID].endp_ids[(l+1)*NEw -1 :  l*NEw] =ENDPID[NEw-1:0];
                end// locals                 
            end //y
        end //x
    end// mesh_torus        
    endgenerate
endmodule
