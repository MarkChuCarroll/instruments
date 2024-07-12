from argparse import ArgumentParser
import subprocess


parts = ["all", "neck_head", "neck_heel", "body_neck", "body_tail",
         "fb_head", "fb_heel", "bridge"]


def main():
    ap = ArgumentParser("tenor-maker")
    ap.add_argument("--prefix", default="tenor-parts")

    opts = ap.parse_args()

    for i in range(1, 8):
        print(f"Generating {opts.prefix}-{parts[i]}.stl")
        subprocess.check_call(["openscad", "-DAUTO=true", f"-Dmake_part={i}", "-o", f"{opts.prefix}-{parts[i]}.stl", "tenor/bosl-tenor.scad"])


if __name__ == "__main__":
    main()