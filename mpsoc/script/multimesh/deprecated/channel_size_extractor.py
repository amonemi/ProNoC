import argparse
import subprocess
import os

from pyslang import ScriptSession


PRONOC_CHANNEL_WIDTH_NAME = "SMARTFLIT_CHANEL_w"

def preprocess_pronoc_pkg(pyslang_opts):
    result = subprocess.run(['python', os.path.join(os.environ["DV_ROOT"],
                                                    "tools/bin/",
                                                    'pyslang_preprocess.py')] \
                             + pyslang_opts, capture_output=True, text=True)
    return result.stdout

def evaluate_pronoc_channel_size(noc_pkg, noc_id):
    session = ScriptSession()
    # Seg-fault turnaround: add a final ";" right after package definition
    session.eval(noc_pkg + ";")
    look_for = f"pronoc_pkg_N{noc_id}::{PRONOC_CHANNEL_WIDTH_NAME}_N{noc_id}"
    result = session.eval(f"{look_for}")
    if str(result) == "<unset>":
        raise Exception(f"Error: cannot retrieve {look_for}")
    print(result, end='')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=f"Retrieve the channel" + \
                                     f" size ({PRONOC_CHANNEL_WIDTH_NAME})"+ \
                                     " of a ProNoC SystemVerilog Package")
    parser.add_argument('noc_id', type=int, help='Network-on-Chip ID')
    parser.add_argument('pyslang_params', nargs=argparse.REMAINDER,
                        help='A series of parameters passed to pyslang for' + \
                             ' pre-processing')
    args = parser.parse_args()

    # Call Pyslang pre-processor on ProNoC NoC PKG
    preprocessed_src = preprocess_pronoc_pkg(args.pyslang_params)
    # Evaluate the ProNoC channel size of the PKG
    evaluate_pronoc_channel_size(preprocessed_src, args.noc_id)

