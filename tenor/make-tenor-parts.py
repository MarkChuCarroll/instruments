from argparse import ArgumentParser
import subprocess
import os.path


parts = [
    "all",
    "neck_head",
    "neck_heel",
    "body_neck",
    "body_tail",
    "fb_head",
    "fb_heel",
    "bridge",
    "nut",
]


def main():
    ap = ArgumentParser("tenor-maker")
    ap.add_argument(
        "--prefix", type=str, help="prefix for the names of the output files"
    )
    ap.add_argument(
        "--model", type=str, help="path of the OpenSCAD model file", required=True
    )
    ap.add_argument(
        "--part", choices=parts, help=f"Then name of the part to create; one of {parts}"
    )

    opts = ap.parse_args()
    if opts.prefix is None:
        prefix = os.path.splitext(os.path.basename(opts.model))[0]
    else:
        prefix = opts.prefix

    if opts.part is not None:
        idx = parts.index(opts.part)
        print(f"Generating {prefix}-{parts[idx]}.stl")
        subprocess.check_call(
            [
                "openscad",
                "-DAUTO=true",
                f"-Dmake_part={idx}",
                "-o",
                f"{prefix}-{parts[idx]}.stl",
                opts.model,
            ]
        )
    else:
        for i in range(1, 9):
            print(f"Generating {prefix}-{parts[i]}.stl")
            subprocess.check_call(
                [
                    "openscad",
                    "-DAUTO=true",
                    f"-Dmake_part={i}",
                    "-o",
                    f"{prefix}-{parts[i]}.stl",
                    opts.model,
                ]
            )


if __name__ == "__main__":
    main()
