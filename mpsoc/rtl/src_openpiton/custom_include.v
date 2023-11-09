
//get new x according to concentration
function integer get_pronoc_X;
    input integer piton_nx;  // openpiton x
    input integer piton_ny;  // openpiton y
    input integer concent;   //concentration value
    input integer dim_max_diff; // max allowable diff between pronoc_x and pronoc_y
	integer min , x , y, size, diff;
    begin  
        if  (concent == 1) get_pronoc_X = piton_nx;
        else begin 
            get_pronoc_X = 0;    
            min = piton_nx * piton_ny * concent * 2;
            for (x = 1; x <= piton_nx; x=x+1) begin
                for (y = 1; y<=piton_ny; y=y+1) begin
                    size = x * y * concent;
                    diff = (x<y) ? y - x : x - y;
                    if ( size >= (piton_nx * piton_ny) && diff <= dim_max_diff &&  size < min ) begin
                        min = size; 
                        get_pronoc_X = x;								
                    end
                end
            end
        end
    end
endfunction

//get new x according to concentration
function integer get_pronoc_Y;
    input integer piton_nx;  // openpiton x
    input integer piton_ny;  // openpiton y
    input integer concent;   //concentration value
    input integer dim_max_diff; // max allowable diff between pronoc_x and pronoc_y
	integer min , x , y, size, diff;
    begin
        if  (concent == 1) get_pronoc_Y = piton_ny;
        else begin    
            get_pronoc_Y = 0;    
            min = piton_nx * piton_ny * concent *2;
            for (x = 1; x <= piton_nx; x=x+1) begin
                for (y = 1; y<=piton_ny; y=y+1) begin
                    size = x * y * concent;
                    diff = (x<y) ? y - x : x - y;
                    if ( size >= (piton_nx * piton_ny) && diff <= dim_max_diff &&  size < min ) begin
                        min = size; 
                        get_pronoc_Y = y;								
                    end
                end
            end
        end
    end
endfunction