from collections import defaultdict
import os
import sys

piton_dir = os.environ.get('PITON_ROOT', "")
if piton_dir == "":
    raise Exception("PITON_ROOT must be defined")

sys.path.append(os.path.join(piton_dir,
                             "piton/tools/bin"))

from piton_common import *

# Number of ports necessary for Depth-First
MAX_PORT = 7

# Indentation size
TAB = " "*4

# System Configuration
chip_infos = {}

# Define Virtual Channels Constants
# NOTE: The values should not be modified for now as the ProNoC router does not
# support that Z_MIN_VC = 2 when using a single VC on the interposer. Z- must
# have the VC index 0 (i.e. a one-hot encoded value of 1).
Z_MIN_VC  = 1 # 2'd01
Z_PLUS_VC = 2 # 2'd10
Z_MIN_VC_IDX  = Z_MIN_VC  - 1
Z_PLUS_VC_IDX = Z_PLUS_VC - 1


# Load system configuration from the caller
def load_chip_infos(piton_chip_infos):
    global chip_infos
    chip_infos = piton_chip_infos


# Open and write the code in a specific file
def write_in_file(path_to_file, content):
    filename, ext = os.path.splitext(os.path.basename(path_to_file))
    header = f"// {filename}{ext} -- auto-generated\n"

    with open(path_to_file, 'w') as output_fh:
        output_fh.write(header + content)
    print(f"[info] Create {path_to_file}")


# Bulk generation of all multimesh files
def generate_pronoc_multimesh(out_dir):
    multimesh_rtl_file = os.path.join(out_dir, "multi_mesh.sv")
    noc_param_file = os.path.join(out_dir, "noc_localparam.v")
    multimesh_routing_file = os.path.join(out_dir, "multi_mesh_routing.sv")
    intercluster_routing_table = os.path.join(out_dir, "multi_mesh_icr.sv")
    rtl_intercluster_channels = ""
    rtl_cluster_instant = ""
    rtl_io_assign = ""
    rtl_cluster_localparam = ""
    rtl_vertical_links_assign = ""

    print(f"[info] Generating topology file in {multimesh_rtl_file}")

    for chip_name, chip_info in chip_infos.items():
        print(f"\t[info] Add CLUSTER_{chip_name} instantiation")
        rtl_io_assign += gen_multi_mesh_io_assign(chip_name)
        rtl_intercluster_channels += gen_io_name_per_cluster(chip_name)
        rtl_cluster_localparam += gen_multi_mesh_cluster_localparam(chip_info)
        rtl_cluster_instant += gen_multi_mesh_cluster_instant(chip_name)

    v_links, _, v_err, grounded_signals = gen_multi_mesh_vertical_link_assign()
    rtl_vertical_links_assign += v_links

    rtl_code = gen_multi_mesh_topology_rtl(rtl_cluster_instant, rtl_io_assign,
                                           rtl_vertical_links_assign, v_err,
                                           grounded_signals)
    write_in_file(multimesh_rtl_file, rtl_code)

    rtl_code = gen_noc_localparam()
    rtl_code += rtl_cluster_localparam
    rtl_code += f"""
{TAB}typedef struct packed {{
{TAB}{TAB}logic [CLUSTER_IDw-1:0] Cmin, Cmax;
{TAB}{TAB}multimesh_router_addr_t endp_addr;
{TAB}{TAB}bit valid;
{TAB}}} cluster_hid_entry_t;

{TAB}localparam [V-1:0]
{TAB}{TAB}Z_PLUS_VC = {Z_PLUS_VC},
{TAB}{TAB}Z_MIN_VC  = {Z_MIN_VC};

{TAB}localparam
{TAB}{TAB}Z_PLUS_VC_IDX = {Z_PLUS_VC_IDX},
{TAB}{TAB}Z_MIN_VC_IDX  = {Z_MIN_VC_IDX};

`ifdef DYNAMIC_CLUSTER_INIT
{TAB}localparam DYN_ICRT_MAX_ENTRY = 10;
{TAB}typedef struct packed {{
{TAB}{TAB}cluster_hid_entry_t data;
{TAB}{TAB}logic [$clog2(DYN_ICRT_MAX_ENTRY)-1:0] addr;
{TAB}{TAB}logic [CLUSTER_IDw-1:0] current_cluster_id;
{TAB}{TAB}bit down_sel;
{TAB}}} program_port_t;
`endif // DYNAMIC_CLUSTER_INIT
"""
    rtl_code += "`endif // NOC_LOCAL_PARAM\n"
    write_in_file(noc_param_file, rtl_code)
    rtl_code = create_routing_modules()
    write_in_file(multimesh_routing_file, rtl_code)
    rtl_code = create_inter_cluster_routing()
    write_in_file(intercluster_routing_table, rtl_code)


def gen_multi_mesh_io_assign(chip_name):
    CHIP = chip_name.upper()
    return f"""
{TAB}{TAB}for (int i = 0; i < CLUSTER_{CHIP}_NE; i++) begin
{TAB}{TAB}{TAB}CLUSTER_{chip_name}_endpoint_chan_in[i] = chan_in_all[CLUSTER_{CHIP}_EID_INIT+i];
{TAB}{TAB}{TAB}chan_out_all[CLUSTER_{CHIP}_EID_INIT+i]= CLUSTER_{chip_name}_endpoint_chan_out[i];
{TAB}{TAB}end
"""


def gen_io_name_per_cluster(chip_name):
    return f"""
{TAB}CLUSTER_{chip_name}_endpoint_chan_in,
{TAB}CLUSTER_{chip_name}_endpoint_chan_out,
"""


def gen_multi_mesh_cluster_localparam(chip_info):
    CHIP = chip_info._name.upper()
    return f"""
{TAB}/****************
{TAB}* CLUSTER_{CHIP} localparams
{TAB}****************/
{TAB}localparam
{TAB}{TAB}CLUSTER_{CHIP}_NX = {chip_info._dim_x},
{TAB}{TAB}CLUSTER_{CHIP}_NY = {chip_info._dim_y},
{TAB}{TAB}CLUSTER_{CHIP}_NZ = {chip_info._dim_z},
{TAB}{TAB}CLUSTER_{CHIP}_MAX_P = {MAX_PORT},
{TAB}{TAB}// Only used in standalone mode (w/o OpenPiton)
{TAB}{TAB}CLUSTER_{CHIP}_RID_INIT = {chip_info._chip_offset_id},
{TAB}{TAB}// Only used in standalone mode (w/o OpenPiton)
{TAB}{TAB}CLUSTER_{CHIP}_EID_INIT = {chip_info._chip_offset_id},
{TAB}{TAB}// Only used in standalone mode (w/o OpenPiton)
{TAB}{TAB}CLUSTER_{CHIP}_NE = CLUSTER_{CHIP}_NX * CLUSTER_{CHIP}_NY * CLUSTER_{CHIP}_NZ,
{TAB}{TAB}// Only used in standalone mode (w/o OpenPiton)
{TAB}{TAB}CLUSTER_{CHIP}_NR = CLUSTER_{CHIP}_NE,
{TAB}{TAB}CLUSTER_{CHIP}_NVP = 2 * (CLUSTER_{CHIP}_NX * CLUSTER_{CHIP}_NY);
"""


def gen_multi_mesh_cluster_instant(chip_name):
    CHIP = chip_name.upper()
    return f"""
{TAB}smartflit_chanel_t CLUSTER_{chip_name}_endpoint_chan_in [CLUSTER_{CHIP}_NE-1:0];
{TAB}smartflit_chanel_t CLUSTER_{chip_name}_endpoint_chan_out[CLUSTER_{CHIP}_NE-1:0];
{TAB}smartflit_chanel_t CLUSTER_{chip_name}_inter_cluster_chan_in[CLUSTER_{CHIP}_NVP-1:0];
{TAB}smartflit_chanel_t CLUSTER_{chip_name}_inter_cluster_chan_out[CLUSTER_{CHIP}_NVP-1:0];
{TAB}router_event_t CLUSTER_{chip_name}_router_event[CLUSTER_{CHIP}_NR-1:0][CLUSTER_{CHIP}_MAX_P-1:0];

{TAB}mesh_cluster #(
{TAB}{TAB}.CLUSTER_ID({CHIP}_ID),
{TAB}{TAB}.RID_INIT(CLUSTER_{CHIP}_RID_INIT),
{TAB}{TAB}.CLUSTER_NX(CLUSTER_{CHIP}_NX),
{TAB}{TAB}.CLUSTER_NY(CLUSTER_{CHIP}_NY),
{TAB}{TAB}.CLUSTER_NZ(CLUSTER_{CHIP}_NZ),
{TAB}{TAB}.CLUSTER_NE(CLUSTER_{CHIP}_NE)
{TAB}) noc_{chip_name}(
{TAB}{TAB}.reset(reset),
{TAB}{TAB}.clk(clk),
{TAB}{TAB}.cluster_id({CHIP}_ID[CLUSTER_IDw-1:0]),
{TAB}{TAB}.endpoint_chan_in(CLUSTER_{chip_name}_endpoint_chan_in),
{TAB}{TAB}.endpoint_chan_out(CLUSTER_{chip_name}_endpoint_chan_out),
{TAB}{TAB}.inter_cluster_chan_in(CLUSTER_{chip_name}_inter_cluster_chan_in),
{TAB}{TAB}.inter_cluster_chan_out(CLUSTER_{chip_name}_inter_cluster_chan_out),
{TAB}{TAB}.router_event(CLUSTER_{chip_name}_router_event)
{TAB});

{TAB}assign router_event[CLUSTER_{CHIP}_RID_INIT +: CLUSTER_{CHIP}_NR] = CLUSTER_{chip_name}_router_event;
"""


def compute_vlink_idx(chip_info, lid, vdir_is_down):
    x, y, z = convert_local_id_to_xyz(chip_info, lid)
    dimx = chip_info._dim_x
    dimy = chip_info._dim_y
    dimz = chip_info._dim_z

    if z != 0 and z != dimz - 1:
        raise ValueError(f"Error: Inter-cluster connection at Z={z} is " + \
                          "invalid. It must be at either the first (0) " + \
                         f"or last ({dimz-1}) position in the Z dimension.")
    if z == 0 and dimz > 1 and not(vdir_is_down):
        raise ValueError("Error: Routers at the first Z layer (Z=0) can" + \
                         " only have a 'down' connection.")
    if z == dimz - 1 and dimz > 1 and vdir_is_down:
        raise ValueError(f"Error: Routers at the last Z layer (Z={dimz-1})" + \
                          "can only have an 'up' connection.")

    vp = (y * dimx) + x if vdir_is_down else \
                        (dimx * dimy) + (y * dimx) + x
    return vp


def gen_multi_mesh_vertical_link_assign(noc_id=0):
    is_connected = defaultdict(lambda: defaultdict(dict))

    for chip_name, chip_info in chip_infos.items():
        # Up and Down connections account for 2 * number of routers
        connections_num = chip_info.get_number_of_routers() * 2
        # Initialize the base 'connection' dictionary
        for i in range(connections_num):
            is_connected['OUT'][chip_name][i] = 0
            is_connected['IN'][chip_name][i]  = 0

    noc_adapters    = "`ifdef PITON_MULTICHIP\n"
    links_assign    = "`ifndef PITON_MULTICHIP\n"
    unconnected_err = ""

    for connections in iter_on_vertical_connections(chip_infos):
        (src_chip, src_endp, dst_chip, dst_endp, src_dir_is_down) = connections
        src_chip_info = chip_infos[src_chip]
        # Compute the src vlink idx in the bunch of wires
        src_vp = compute_vlink_idx(src_chip_info, int(src_endp),
                                   src_dir_is_down)
        # "Z+" credits are released on index Z_PLUS_VC_IDX
        # "Z-" credits are released on Z_MIN_VC_IDX
        credit_idx = Z_MIN_VC_IDX if src_dir_is_down else Z_PLUS_VC_IDX

        dst_dir_is_down = not src_dir_is_down
        dst_chip_info = chip_infos[dst_chip]
        # Compute the dst vlink idx in the bunch of wires
        dst_vp = compute_vlink_idx(dst_chip_info, int(dst_endp),
                                   dst_dir_is_down)

        src_dir = "down" if src_dir_is_down else "up"
        dst_dir = "down" if dst_dir_is_down else "up"

        # Used with OpenPiton
        noc_adapters += f"""\
{TAB}{TAB}noc{noc_id}_inter_chip_adapter_{src_chip}_{dst_chip} {src_chip}_{dst_chip}_noc_adapter_{src_endp}_{dst_endp}(
{TAB}{TAB}{TAB}.clk(clk),
{TAB}{TAB}{TAB}.rst_n(rst_n),

{TAB}{TAB}{TAB}.flit_wr_i(CLUSTER_{src_chip}_inter_cluster_chan_out[{src_vp}].flit_chanel.flit_wr),
{TAB}{TAB}{TAB}.flit_data_i(CLUSTER_{src_chip}_inter_cluster_chan_out[{src_vp}].flit_chanel.flit),
{TAB}{TAB}{TAB}.flit_wr_o(CLUSTER_{dst_chip}_inter_cluster_chan_in[{dst_vp}].flit_chanel.flit_wr),
{TAB}{TAB}{TAB}.flit_data_o(CLUSTER_{dst_chip}_inter_cluster_chan_in[{dst_vp}].flit_chanel.flit),

{TAB}{TAB}{TAB}.downstream_credit_i(CLUSTER_{dst_chip}_inter_cluster_chan_out[{dst_vp}].flit_chanel.credit[{credit_idx}]),
{TAB}{TAB}{TAB}.upstream_credit_o(CLUSTER_{src_chip}_inter_cluster_chan_in[{src_vp}].flit_chanel.credit[{credit_idx}]),

{TAB}{TAB}{TAB}.downstream_ctrl_i(CLUSTER_{dst_chip}_inter_cluster_chan_out[{dst_vp}].ctrl_chanel),
{TAB}{TAB}{TAB}.upstream_ctrl_o(CLUSTER_{src_chip}_inter_cluster_chan_in[{src_vp}].ctrl_chanel)
{TAB}{TAB});
{TAB}{TAB}assign CLUSTER_{src_chip}_inter_cluster_chan_in[{src_vp}].flit_chanel.credit[{int(not(credit_idx))}] = 1'b0;\n
"""
        # Used in standalone mode
        links_assign += f"""\
{TAB}{TAB}// {src_chip}[{src_endp}] dir {src_dir} to {dst_chip}[{dst_endp}] dir {dst_dir}
{TAB}{TAB}CLUSTER_{dst_chip}_inter_cluster_chan_in[{dst_vp}].flit_chanel.flit_wr = CLUSTER_{src_chip}_inter_cluster_chan_out[{src_vp}].flit_chanel.flit_wr;
{TAB}{TAB}CLUSTER_{dst_chip}_inter_cluster_chan_in[{dst_vp}].flit_chanel.flit = CLUSTER_{src_chip}_inter_cluster_chan_out[{src_vp}].flit_chanel.flit;
{TAB}{TAB}CLUSTER_{src_chip}_inter_cluster_chan_in[{src_vp}].flit_chanel.credit = CLUSTER_{dst_chip}_inter_cluster_chan_out[{dst_vp}].flit_chanel.credit;
{TAB}{TAB}CLUSTER_{src_chip}_inter_cluster_chan_in[{src_vp}].ctrl_chanel = CLUSTER_{dst_chip}_inter_cluster_chan_out[{dst_vp}].ctrl_chanel;
"""
        is_connected['OUT'][dst_chip][dst_vp] = 1
        is_connected['IN'][src_chip][src_vp]  = 1

    noc_adapters += "`endif // PITON_MULTICHIP\n"
    links_assign += "`endif // PITON_MULTICHIP\n"

    links_assign += f"\n{TAB}{TAB}// Tie to the ground unconnected vertical ports\n"

    out_connections = is_connected['OUT']
    in_connections  = is_connected['IN']
    # NOTE: Veloce place and route doesn't like the grounding...
    links_assign += "`ifndef VELOCE_EMULATION\n"
    for dst_chip in sorted(out_connections.keys()):
        for dst_vp in sorted(out_connections[dst_chip].keys()):
            # Output vertical links are not assigned and their associated input
            # control channel is not used
            if out_connections[dst_chip][dst_vp] == 0 and \
               in_connections[dst_chip][dst_vp] == 0:
                links_assign += f"""\
{TAB}{TAB}CLUSTER_{dst_chip}_inter_cluster_chan_in[{dst_vp}] = is_grounded_{dst_chip};
"""
    links_assign += "`endif // VELOCE_EMULATION\n"

    for src_chip in sorted(in_connections.keys()):
        for src_vp in sorted(in_connections[src_chip].keys()):
            # Output vertical links are not assigned
            if in_connections[src_chip][src_vp] == 0:
                unconnected_err += f"""\
{TAB}{TAB}if (CLUSTER_{src_chip}_inter_cluster_chan_out[{src_vp}].flit_chanel.flit_wr) begin
{TAB}{TAB}{TAB}`ERROR_UNCNT(\"{src_chip}\",{src_vp})
{TAB}{TAB}end
"""

    grounded_signals = ""
    for dst_chip in sorted(out_connections.keys()):
        grounded_signals += f"{TAB}smartflit_chanel_t is_grounded_{dst_chip} = {{SMARTFLIT_CHANEL_w{{1'b0}}}};\n"

    return (links_assign, noc_adapters, unconnected_err, grounded_signals)


def gen_noc_localparam():
    rtl = ""

    # Generate both Buffer Depth and Payload Size Selection
    #
    # The goal is to generate a Verilog-string like this:
    # (NOC_CHIP_ID == 0) ?
    #   (NOC_ID == "N1") ? `PITON_CHIPA_NOC1_BUFFER_SIZE :
    #   (NOC_ID == "N2") ? `PITON_CHIPA_NOC2_BUFFER_SIZE :
    #                      `PITON_CHIPA_NOC3_BUFFER_SIZE
    # : (NOC_CHIP_ID == 1) ?
    #   (NOC_ID == "N1") ? `PITON_CHIPB_NOC1_BUFFER_SIZE :
    #   (NOC_ID == "N2") ? `PITON_CHIPB_NOC2_BUFFER_SIZE :
    #                      `PITON_CHIPA_NOC3_BUFFER_SIZE
    # : (NOC_CHIP_ID == 2) ?
    # ...
    # so the NoC select the appropriate buffer depth (B) and payload size
    # (Fpay)

    template_buffer_sel = \
        '(NOC_ID == "N1") ? `PITON__CHIP__NOC1_BUFFER_SIZE : ' + \
        '(NOC_ID == "N2") ? `PITON__CHIP__NOC2_BUFFER_SIZE : ' + \
                           '`PITON__CHIP__NOC3_BUFFER_SIZE'

    template_width_sel = \
        '(NOC_ID == "N1") ? `PITON__CHIP__NOC1_WIDTH : ' + \
        '(NOC_ID == "N2") ? `PITON__CHIP__NOC2_WIDTH : ' + \
                           '`PITON__CHIP__NOC3_WIDTH'

    buffer_sel = ""
    width_sel  = ""
    noc1_buffer_depths = []
    noc2_buffer_depths = []
    noc3_buffer_depths = []
    nb_routers = 0
    min_vc = None
    max_vc = None

    for i, (chip_name, chip_info) in enumerate(chip_infos.items()):
        CHIPID = chip_info._chipid
        CHIPNAME = chip_name.upper()

        # Not the last chip
        if i < len(chip_infos.items()) - 1:
            buffer_sel += f"(NOC_CHIP_ID == {CHIPID}) ? "
            width_sel  += f"(NOC_CHIP_ID == {CHIPID}) ? "

        buffer_sel += template_buffer_sel.replace("_CHIP_", CHIPNAME)
        width_sel  += template_width_sel.replace("_CHIP_", CHIPNAME)

        if i < len(chip_infos.items()) - 1:
            buffer_sel += " : "
            width_sel  += " : "

        noc1_buffer_depths.append(chip_info.retrieve_noc_buffers_depth()[0])
        noc2_buffer_depths.append(chip_info.retrieve_noc_buffers_depth()[1])
        noc3_buffer_depths.append(chip_info.retrieve_noc_buffers_depth()[2])

        nb_routers += chip_info.get_number_of_routers()

        min_vc = chip_info._nb_virtual_channels if min_vc is None else \
                  min(min_vc, chip_info._nb_virtual_channels)
        max_vc = chip_info._nb_virtual_channels if max_vc is None else \
                  max(max_vc, chip_info._nb_virtual_channels)

    # Use ProNoC's LB parameter as the maximal buffer value in the 3.5D
    # topology for a given physical NoC.
    # Compute the maximal buffer depth across all chips for any NoC channel.
    # This is used to compute the width of both the credit and credit
    # initialization channels, for the whole system.
    LB = \
        f'(NOC_ID == "N1") ? {max(noc1_buffer_depths)} : ' + \
        f'(NOC_ID == "N2") ? {max(noc2_buffer_depths)} : ' + \
                           f'{max(noc3_buffer_depths)}'

    # Name of the ProNoC multi-chip topology
    # This topology supports multiple clusters of 2D-meshes, interconnected
    # vertically
    topology = "MULTI_MESH"

    # Dictionary representing the main noc_localparam attributes
    param_attribs = {
        'TOPOLOGY': f'"{topology}"',
        'T1': nb_routers,
        'T3': 1,
        'T4': 1,
        'V' : 2,
        'ROUTE_MODE': '\"CONVENTIONAL\"',
        'B': "PRESEL_B",
        'LB': "PRESEL_LB",
        'Fpay': "PRESEL_Fpay",
        'ROUTE_NAME': '\"DEPTH_FIRST\"',
        'PCK_TYPE': '\"MULTI_FLIT\"',
        'MIN_PCK_SIZE': 1,
        'HDR_OPTION_WIDTH': 0,
        'BYTE_EN': 0,
        'SSA_EN': '\"NO\"',
        "SMART_MAX": 0,
        "CONGESTION_INDEX": 3,
        "ESCAP_VC_MASK": "2'b01",
        "VC_REALLOCATION_TYPE": '\"NONATOMIC\"',
        "COMBINATION_TYPE": '\"COMB_NONSPEC\"',
        "MUX_TYPE": '\"BINARY\"',
        "C": 0,
        "CLASS_SETTING": "{V{1'b1}}",
        "DEBUG_EN": 1,
        "ADD_PIPREG_AFTER_CROSSBAR": "1'b0",
        "FIRST_ARBITER_EXT_P_EN": 1,
        "SWA_ARBITER_TYPE": '\"RRA\"',
        "WEIGHTw": 4,
        'SELF_LOOP_EN': 1,
        "AVC_ATOMIC_EN": 0,
        "MAX_PCK_NUM": 1000000000,
        "MAX_PCK_SIZ": 16383,
        "MAX_SIM_CLKs": 1000000000,
        "TIMSTMP_FIFO_NUM": 16,
        "CVw": "(C==0)? V : C * V",
        "CAST_TYPE": '\"UNICAST\"',
        "MCAST_ENDP_LIST": "'b1111"
    }

    param_attribs['MAX_ROUTER'] = nb_routers
    param_attribs['MAX_PORT'] = MAX_PORT

    hetero_vc_enabled = min_vc != max_vc or max_vc < 2
    param_attribs['HETERO_VC'] = int(hetero_vc_enabled)
    hetero_vc = f"""'{{
{TAB}{TAB}// VC chip local_id global_id
"""
    for chip_name, chip_info in chip_infos.items():
        nr = chip_info.get_number_of_routers()
        rid_int = chip_info._chip_offset_id
        r = 0
        v = chip_info._nb_virtual_channels
        for n in range(rid_int, rid_int + nr):
            ports = range(int(param_attribs['MAX_PORT']))
            hetero_vc += f"{TAB}{TAB}// {chip_name}: r{r} R{n}\n"
            hetero_vc += TAB*2 + "'{"
            for port in ports:
                if hetero_vc_enabled:
                    hetero_vc += str(v)
                else:
                    hetero_vc += "0"
                if port != ports[-1]:
                    hetero_vc += ", "
            if n < nb_routers-1:
                hetero_vc += "},\n"
            else:
                hetero_vc += "}\n"
            r += 1
    hetero_vc += f"{TAB}}}"
    param_attribs['int VC_CONFIG_TABLE[MAX_ROUTER][MAX_PORT]'] = hetero_vc

    rtl +=f"""
`ifdef NOC_LOCAL_PARAM

{TAB}/*************************************
{TAB}*   ProNoC localparams
{TAB}*************************************/

{TAB}// NOTE: values modified automatically by phy_noc.pl
{TAB}localparam NOC_ID = 0;
{TAB}localparam NOC_CHIP_ID = 0;

`ifdef PITON_PRONOC
{TAB}// OpenPiton header
{TAB}`include "define.tmp.h"

{TAB}localparam PRESEL_B = {buffer_sel};
{TAB}localparam PRESEL_LB = {LB};
{TAB}localparam PRESEL_Fpay = {width_sel};
`else
{TAB}// ProNoC Standalone settings
{TAB}localparam PRESEL_B = 4;
{TAB}localparam PRESEL_LB = 4;
{TAB}localparam PRESEL_Fpay = 64;
`endif // PITON_PRONOC
"""
    # Generate the list of localparam attributes
    for p in param_attribs.keys():
        rtl += f"{TAB}localparam {p} = {param_attribs[p]};\n"

    lines = []
    MAX_CHIP_X = 0
    MAX_CHIP_Y = 0
    MAX_CHIP_Z = 0
    for chip_name, chip_info in chip_infos.items():
        lines.append(f"{TAB}{TAB}{chip_name.upper()}_ID = {chip_info._chipid},\n")
        MAX_CHIP_X = max(MAX_CHIP_X, chip_info._dim_x)
        MAX_CHIP_Y = max(MAX_CHIP_Y, chip_info._dim_y)
        MAX_CHIP_Z = max(MAX_CHIP_Z, chip_info._dim_z)

    rtl += f"""
{TAB}/*************************************
{TAB}*   multimesh localparams
{TAB}*************************************/
{TAB}localparam
{"".join(lines)}
{TAB}{TAB}MAX_RID = T1,
{TAB}{TAB}RIDw = $clog2(MAX_RID),
{TAB}{TAB}CLUSTER_NUM = {len(chip_infos.items())},
{TAB}{TAB}CLUSTER_IDw = (CLUSTER_NUM == 1) ? 1 : $clog2(CLUSTER_NUM),
{TAB}{TAB}CLUSTER_MAX_X = {str(MAX_CHIP_X)},
{TAB}{TAB}CLUSTER_Xw = (CLUSTER_MAX_X == 1)? 1 : $clog2(CLUSTER_MAX_X),
{TAB}{TAB}CLUSTER_MAX_Y = {str(MAX_CHIP_Y)},
{TAB}{TAB}CLUSTER_Yw = (CLUSTER_MAX_Y == 1)? 1 : $clog2(CLUSTER_MAX_Y),
{TAB}{TAB}CLUSTER_MAX_Z = {str(MAX_CHIP_Z)},
{TAB}{TAB}CLUSTER_Zw = (CLUSTER_MAX_Z == 1)? 1 : $clog2(CLUSTER_MAX_Z);

{TAB}typedef struct packed {{
{TAB}{TAB}logic [CLUSTER_IDw-1:0] c;
{TAB}{TAB}logic [CLUSTER_Zw-1 :0] z;
{TAB}{TAB}logic [CLUSTER_Yw-1 :0] y;
{TAB}{TAB}logic [CLUSTER_Xw-1 :0] x;
{TAB}}} multimesh_router_addr_t;
{TAB}localparam T2 = $bits(multimesh_router_addr_t);
"""
    return rtl


def gen_multi_mesh_topology_rtl(rtl_cluster_instant, rtl_io_assign,
                                rtl_vertical_links_assign, v_err,
                                grounded_signals):
    return f"""
`include "pronoc_def.v"

module multi_mesh
{TAB}import pronoc_pkg::*;
(
{TAB}input  logic clk,
{TAB}input  logic reset,
{TAB}input  smartflit_chanel_t chan_in_all[NE-1:0],
{TAB}output smartflit_chanel_t chan_out_all[NE-1:0],
{TAB}output router_event_t router_event[NR-1:0][MAX_P-1:0]
);

{TAB}// Unused Input channels are connected to ground
{grounded_signals}
{rtl_cluster_instant}

{TAB}// Chiplet interconnect
{TAB}always_comb begin
{rtl_io_assign}
{rtl_vertical_links_assign}
{TAB}end

`define ERROR_UNCNT(cluster, port) \\
{TAB}$display("Error: A flit was injected into an unconnected NoC router port."); \\
{TAB}$display("Cluster: %s, Port: %0d", cluster, port); \\
{TAB}$display("Simulation will terminate due to this unexpected behavior."); \\
{TAB}$finish;

`ifdef SIMULATION
{TAB}always @(posedge clk) begin
{v_err}
{TAB}end
`endif

endmodule
"""


def create_routing_modules():
    rtl = multimesh_address_encoder()
    rtl += multimesh_address_decoder()
    return rtl


def multimesh_address_decoder():
    lines = ""
    for chip_name, _ in chip_infos.items():
        CHIP = chip_name.upper()
        lines += f"""
{TAB}{TAB}for (int z=0; z<CLUSTER_{CHIP}_NZ; z=z+1) begin: {CHIP}Z_
{TAB}{TAB}{TAB}for (int y=0; y<CLUSTER_{CHIP}_NY; y=y+1) begin: {CHIP}Y_
{TAB}{TAB}{TAB}{TAB}for (int x=0; x<CLUSTER_{CHIP}_NX; x=x+1) begin: {CHIP}X_
{TAB}{TAB}{TAB}{TAB}{TAB}multimesh_router_addr_t CODED;
{TAB}{TAB}{TAB}{TAB}{TAB}CODED.x = x;
{TAB}{TAB}{TAB}{TAB}{TAB}CODED.y = y;
{TAB}{TAB}{TAB}{TAB}{TAB}CODED.z = z;
{TAB}{TAB}{TAB}{TAB}{TAB}CODED.c = {CHIP}_ID;
{TAB}{TAB}{TAB}{TAB}{TAB}addr_table[CODED] = (z * (CLUSTER_{CHIP}_NY * CLUSTER_{CHIP}_NY) + (y * CLUSTER_{CHIP}_NX) + x) + CLUSTER_{CHIP}_RID_INIT;
{TAB}{TAB}{TAB}{TAB}end
{TAB}{TAB}{TAB}end
{TAB}{TAB}end
"""

    return f"""
module multimesh_address_decoder
{TAB}import pronoc_pkg::*;
(
{TAB}output [RIDw-1:0] rid_out,
{TAB}input multimesh_router_addr_t addr_st_i
);

{TAB}localparam BITS = $bits(multimesh_router_addr_t);
{TAB}logic [RIDw-1:0] addr_table[2**BITS-1:0];
{TAB}always_comb begin
{lines}
{TAB}end
{TAB}assign rid_out = addr_table[addr_st_i];
endmodule
"""


def multimesh_address_encoder():
    lines = ""
    for chip_name, _ in chip_infos.items():
        CHIP = chip_name.upper()
        lines += f"""
{TAB}{TAB}for (z = 0; z < CLUSTER_{CHIP}_NZ; z = z + 1) begin: {CHIP}Z_
{TAB}{TAB}{TAB}for (y = 0; y < CLUSTER_{CHIP}_NY; y = y + 1) begin: {CHIP}Y_
{TAB}{TAB}{TAB}{TAB}for (x = 0; x < CLUSTER_{CHIP}_NX; x = x + 1) begin: {CHIP}X_
{TAB}{TAB}{TAB}{TAB}{TAB}localparam RID = (z * (CLUSTER_{CHIP}_NY * CLUSTER_{CHIP}_NY) + (y * CLUSTER_{CHIP}_NX) + x) + CLUSTER_{CHIP}_RID_INIT;
{TAB}{TAB}{TAB}{TAB}{TAB}assign addr_table[RID].x = x;
{TAB}{TAB}{TAB}{TAB}{TAB}assign addr_table[RID].y = y;
{TAB}{TAB}{TAB}{TAB}{TAB}assign addr_table[RID].z = z;
{TAB}{TAB}{TAB}{TAB}{TAB}assign addr_table[RID].c = {CHIP}_ID;
{TAB}{TAB}{TAB}{TAB}end
{TAB}{TAB}{TAB}end
{TAB}{TAB}end
"""

    return f"""
`include "pronoc_def.v"

module multimesh_address_encoder
{TAB}import pronoc_pkg::*;
(
{TAB}input  logic [RIDw-1:0] rid_in,
{TAB}output multimesh_router_addr_t addr_st_o
);

{TAB}multimesh_router_addr_t addr_table[MAX_RID];
{TAB}genvar x,y,z;
{TAB}generate
{lines}
{TAB}endgenerate

{TAB}assign addr_st_o = addr_table[rid_in];
endmodule
"""


def create_inter_cluster_routing():
    not_dynamic = ""
    static_icr_modules = ""
    cond_statement = "if"

    for chip_name, chip_info in chip_infos.items():
        CHIP = chip_name.upper()
        not_dynamic += f"""\
    {cond_statement} (CLUSTER_ID == {CHIP}_ID) begin
{TAB}{TAB}hard_coded_icr_{chip_name} #(
{TAB}{TAB}{TAB}.CLUSTER_ID(CLUSTER_ID),
{TAB}{TAB}{TAB}.RID(RID)
{TAB}{TAB}) icr_comb(
{TAB}{TAB}{TAB}.dest_address(dest_address),
{TAB}{TAB}{TAB}.local_cluster_endp_addr(local_cluster_endp_addr),
{TAB}{TAB}{TAB}.up_dir_sel(up_dir_sel)
{TAB}{TAB});
"""
        cond_statement = "else if"
        static_icr_modules += f"""
module hard_coded_icr_{chip_name}
{TAB}import pronoc_pkg::*;
#(
{TAB}parameter CLUSTER_ID = 0,
{TAB}parameter RID = 0
)(
{TAB}input multimesh_router_addr_t dest_address,
{TAB}output multimesh_router_addr_t local_cluster_endp_addr,
{TAB}output logic up_dir_sel
);

{TAB}localparam unsigned [CLUSTER_IDw-1:0] current_cluster_id = CLUSTER_ID;
{TAB}typedef struct packed {{
{TAB}{TAB}logic [CLUSTER_IDw-1:0] Cmin, Cmax;
{TAB}{TAB}multimesh_router_addr_t endp_addr;
{TAB}{TAB}bit valid;
{TAB}}} cluster_hid_entry_t;
{TAB}multimesh_router_addr_t
{TAB}{TAB}local_cluster_endp_addr_up_dir,
{TAB}{TAB}local_cluster_endp_addr_down_dir;
"""
        no_down_chip = int(not chip_info.has_down_chip())
        static_icr_modules += f"{TAB}localparam NO_DOWNLINK = {no_down_chip};\n"

        up_clusters = chip_info._chipid_up_to_destchip.keys()
        if len(up_clusters) > 0:
            static_icr_modules += f"{TAB}localparam MAX_ENTRY_{CHIP} = {len(up_clusters)};\n"
            static_icr_modules += f"{TAB}cluster_hid_entry_t address_table[MAX_ENTRY_{CHIP}];\n"
            static_icr_modules += f"{TAB}multimesh_router_addr_t endp_addr_array[MAX_ENTRY_{CHIP}];\n"
            static_icr_modules += f"{TAB}wire [CLUSTER_IDw-1:0] Cmax_array_{chip_name}[MAX_ENTRY_{CHIP}];\n"
            static_icr_modules += f"{TAB}wire [CLUSTER_IDw-1:0] Cmin_array_{chip_name}[MAX_ENTRY_{CHIP}];\n"
            i = 0
            for c_min_id, c_max_id in up_clusters:
                static_icr_modules += f"{TAB}assign Cmax_array_{chip_name}[{i}] = {c_max_id};\n"
                static_icr_modules += f"{TAB}assign Cmin_array_{chip_name}[{i}] = {c_min_id};\n"
                i += 1
        else:
            static_icr_modules += f"{TAB}{TAB}// There are no upper chiplet. Select between local and down chiplet\n"
        static_icr_modules += f"{TAB}generate \n{TAB}{TAB}case (RID)\n"

        for rid in range(chip_info.get_number_of_routers()):
            static_icr_modules += f"{TAB}{TAB}{rid}: begin\n"
            i = 0
            for (_, _), upper_chip in chip_info._chipid_up_to_destchip.items():
                ldest = chip_info._destchip_up_to_ldst[upper_chip, rid]
                x, y, z = convert_local_id_to_xyz(chip_info, ldest)
                static_icr_modules += f"{TAB}{TAB}{TAB}/* T:{upper_chip}, R:{ldest} */\n"
                static_icr_modules += f"{TAB}{TAB}{TAB}assign endp_addr_array[{i}] = '{{x:{x}, y:{y}, z:{z}, c:{CHIP}_ID}};\n"
                i += 1
            if not no_down_chip:
                ldest = chip_info._destchip_down_to_ldst[rid]
                x, y, z = convert_local_id_to_xyz(chip_info, ldest)
                down_cluster = chip_info._destchip_down
                static_icr_modules += f"{TAB}{TAB}{TAB}/* T:{down_cluster}, R:{ldest} */\n"
                static_icr_modules += f"{TAB}{TAB}{TAB}assign local_cluster_endp_addr_down_dir = '{{x:{x}, y:{y}, z:{z}, c:{CHIP}_ID}};\n"
            static_icr_modules += f"{TAB}{TAB}end //{rid}\n"
        static_icr_modules += f"{TAB}{TAB}endcase\n{TAB}endgenerate\n"

        if len(up_clusters) > 0:
            static_icr_modules += f"""
{TAB}always_comb begin
{TAB}{TAB}local_cluster_endp_addr_up_dir = 0;
{TAB}{TAB}up_dir_sel = 1'b0;
{TAB}{TAB}for (int i = 0; i < MAX_ENTRY_{CHIP}; i++) begin
{TAB}{TAB}{TAB}if (Cmin_array_{chip_name}[i] <= dest_address.c &&
{TAB}{TAB}{TAB}    dest_address.c <= Cmax_array_{chip_name}[i]) begin
{TAB}{TAB}{TAB}{TAB}local_cluster_endp_addr_up_dir = endp_addr_array[i];
{TAB}{TAB}{TAB}{TAB}up_dir_sel = 1'b1;
{TAB}{TAB}{TAB}end
{TAB}{TAB}end
{TAB}end
"""
        else:
            static_icr_modules += f"""
{TAB}always_comb begin
{TAB}{TAB}local_cluster_endp_addr_up_dir = 0;
{TAB}{TAB}up_dir_sel = 1'b0;
{TAB}end
"""
        not_dynamic += f"{TAB}end\n"
        static_icr_modules += f"""
{TAB}assign local_cluster_endp_addr =
{TAB}{TAB}(dest_address.c == current_cluster_id) ? dest_address :
{TAB}{TAB}(up_dir_sel) ? local_cluster_endp_addr_up_dir :
{TAB}{TAB}local_cluster_endp_addr_down_dir;
endmodule
"""
    rtl = f"""
`include "pronoc_def.v"
module global_id_to_local_cluster_endp
{TAB}import pronoc_pkg::*;
#(
`ifndef DYNAMIC_CLUSTER_INIT
{TAB}parameter CLUSTER_ID = 0,
{TAB}parameter RID = 0
`endif
)(
`ifdef DYNAMIC_CLUSTER_INIT
{TAB}input  cluster_hid_entry_t     address_table[DYN_ICRT_MAX_ENTRY],
{TAB}input  multimesh_router_addr_t local_cluster_endp_addr_down_dir,
{TAB}input  logic [CLUSTER_IDw-1:0] current_cluster_id,
`endif
{TAB}input  multimesh_router_addr_t dest_address,
{TAB}output multimesh_router_addr_t local_cluster_endp_addr,
{TAB}output logic up_dir_sel
);

`ifndef DYNAMIC_CLUSTER_INIT
{TAB}generate
{not_dynamic}
{TAB}endgenerate
`else
{TAB}dynamic_icr icr(
{TAB}{TAB}.dest_address(dest_address),
{TAB}{TAB}.local_cluster_endp_addr(local_cluster_endp_addr),
{TAB}{TAB}.local_cluster_endp_addr_down_dir(local_cluster_endp_addr_down_dir),
{TAB}{TAB}.current_cluster_id(current_cluster_id),
{TAB}{TAB}.address_table(address_table),
{TAB}{TAB}.up_dir_sel(up_dir_sel)
{TAB});
`endif
endmodule

`ifdef DYNAMIC_CLUSTER_INIT
module dynamic_icr
{TAB}import pronoc_pkg::*;
(
{TAB}input  multimesh_router_addr_t dest_address,
{TAB}output multimesh_router_addr_t local_cluster_endp_addr,
{TAB}input  multimesh_router_addr_t local_cluster_endp_addr_down_dir,
{TAB}input  logic [CLUSTER_IDw-1:0] current_cluster_id,
{TAB}input  cluster_hid_entry_t     address_table[DYN_ICRT_MAX_ENTRY],
{TAB}output logic                   up_dir_sel
);

{TAB}multimesh_router_addr_t local_cluster_endp_addr_up_dir;

{TAB}always_comb begin
{TAB}{TAB}local_cluster_endp_addr_up_dir = 0;
{TAB}{TAB}up_dir_sel = 1'b0;
{TAB}{TAB}for (int i = 0; i < DYN_ICRT_MAX_ENTRY; i++) begin
{TAB}{TAB}{TAB}if (address_table[i].valid) begin
{TAB}{TAB}{TAB}{TAB}if (address_table[i].Cmin <= dest_address.c &&
{TAB}{TAB}{TAB}{TAB}    dest_address.c < address_table[i].Cmax) begin
{TAB}{TAB}{TAB}{TAB}{TAB}local_cluster_endp_addr_up_dir = address_table[i].endp_addr;
{TAB}{TAB}{TAB}{TAB}{TAB}up_dir_sel = 1'b1;
{TAB}{TAB}{TAB}{TAB}end
{TAB}{TAB}{TAB}end
{TAB}{TAB}end
{TAB}end

{TAB}assign local_cluster_endp_addr =
{TAB}{TAB}(dest_address.c == current_cluster_id) ? dest_address :
{TAB}{TAB}(up_dir_sel) ? local_cluster_endp_addr_up_dir :
{TAB}{TAB}local_cluster_endp_addr_down_dir;
endmodule

module dynamic_hids_per_router
{TAB}import pronoc_pkg::*;
(
{TAB}input  logic clk,
{TAB}input  logic reset,
{TAB}output multimesh_router_addr_t local_cluster_endp_addr_down_dir,
{TAB}output logic [CLUSTER_IDw-1:0] current_cluster_id,
{TAB}output cluster_hid_entry_t address_table[DYN_ICRT_MAX_ENTRY],
{TAB}input  program_port_t program_port
);

{TAB}always_ff @(posedge clk or posedge reset) begin
{TAB}{TAB}if (reset) begin
{TAB}{TAB}{TAB}local_cluster_endp_addr_down_dir = 0;
{TAB}{TAB}{TAB}foreach (address_table[i]) begin
{TAB}{TAB}{TAB}{TAB}address_table[i].valid <= 1'b0;
{TAB}{TAB}{TAB}{TAB}current_cluster_id <= 0;
{TAB}{TAB}{TAB}end
{TAB}{TAB}end else begin
{TAB}{TAB}{TAB}if (program_port.data.valid) begin
{TAB}{TAB}{TAB}{TAB}if (!program_port.down_sel) begin
{TAB}{TAB}{TAB}{TAB}{TAB}address_table[program_port.addr] <= program_port.data;
{TAB}{TAB}{TAB}{TAB}{TAB}current_cluster_id <= program_port.current_cluster_id;
{TAB}{TAB}{TAB}{TAB}end else begin
{TAB}{TAB}{TAB}{TAB}{TAB}local_cluster_endp_addr_down_dir = program_port.data.endp_addr;
{TAB}{TAB}{TAB}{TAB}end
{TAB}{TAB}{TAB}end
{TAB}{TAB}end
{TAB}end
endmodule

`else
{static_icr_modules}
`endif
"""
    return rtl
