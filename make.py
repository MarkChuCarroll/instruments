from argparse import ArgumentParser
import subprocess


parts = ["neck_head", "neck_heel", "body_neck", "body_tail",
         "fb_head", "fb_heel", "bridge"]


def main():
    ap = ArgumentParser("tenor-maker")
    ap.add_argument("--prefix", default="tenor-parts")

    opts = ap.parse_args()

    for i in range(1, 8):
        print(f"Generating {opts.prefix}-{parts[i]}.stl")
        subprocess.check_call(f"openscad", "-DAUTO=true", "-Dmake_part={i}", "-o", f"{opts.prefix}-{parts[i]}.stl" "bosl-tenor.scad")

