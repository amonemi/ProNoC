grep -rl 'flit_in_we' ./ | xargs sed -i 's/flit_in_we/flit_in_wr/g'
grep -rl 'flit_out_we' ./ | xargs sed -i 's/flit_out_we/flit_out_wr/g'
