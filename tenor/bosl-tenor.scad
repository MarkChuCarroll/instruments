//
// Copyright 2024 Mark C. Chu-Carroll
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this model except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

include <BOSL2/std.scad>

/**
 * The body is teardrop shaped. It's built by setting up two
 * cylinders, one smaller than teh other, with offset centers,
 * and then taking their hull. We add a bit of slant by making
 * the larger cylinder actually a bit conic, but square up at
 * the heel because the smaller is a true cylinder.
 * Then we round the edges by using minkowski sum with a little sphere.
 */
module body_shape(length, thickness) {
  // Anchoris the body top where the neck meets the body.
  //  translate([ 130, 0, -5 ])
  minkowski() {
    hull() {
      scale([ 1.3, 1, 1 ]) { cylinder(thickness, length, length * 3 / 4); }
      translate([ length, 0, 0 ]) {
        cylinder(thickness, length / 2, length / 2);
      }
    }
    sphere(10, $fn = 40);
  }
}

/**
 * We want the body to be hollow. So what we do is create
 * one copy of the body  form, and then a second scaled version that's a bit
 * smaller - and we subtract the smaller one from the larger.
 */
module body(size, thickness, split = false) {
  /**
   * The screwblock is a section matching the back end of the neck's heel
   * block, which has holes and hex-nute slots to allow the neck to be
   * securely bolted on to the body.
   */
  module screwblock(radius, length, thickness) {
    /*
     * I want to put cutouts for hex nuts into the screw block.
     * For an m4 hex nut, the size flat-to-flat is 7mm.
     * So the rough outer radius of the hexnut is 5mm.
     */
    module hexnut_slot() {
      rotate([ 90, 0, 0 ]) {
        rotate([ 0, 0, 30 ]) {
          union() {
            translate([ 0, 0, 20 ]) {
              cylinder(40, 2.4, 2.4, center = true, $fn = 20);
            }
            linear_extrude(height = 3) { circle(5, $fn = 6); }
          }
        }
      }
    }
    translate([ size * 1.2 + 4, 0, thickness * 0.8 ]) rotate([ 0, 180, 90 ]) {
      difference() {
        linear_extrude(thickness, scale = [ 1.5, 1 ], center = false) {
          translate([ -radius, 0, 0 ]) { square([ radius * 2, length / 2 ]); }
        }
        translate([ 0, length / 2, 8 ]) hexnut_slot();
        translate([ 0, length / 2, 20 ]) hexnut_slot();
      }
    }
  }

  union() {
    difference() {
      body_shape(size, thickness);
      scale([ 0.9, 0.9, 0.8 ]) { body_shape(size, thickness); }

      move([ size / 2, -size / 2, -thickness * 2 ]) {
        scale([ 1.4, 1.0, 1.0 ]) { cylinder(size, size / 4, size / 4); }
      }

      if (split) {
        translate([ 0, 0, -20 ])
            neck(100, neck_length_mm - neck_offset, neck_width, neck_thickness,
                 18 * 25.4, true);
      }
    }
    if (split) {
      screwblock(neck_width * 2 / 6, 50, 45);
    }


    up(thickness / 3) left(size * 1.2) tapered_tailpiece(
        neck_width, neck_width / 4, neck_width / 2, neck_width / 6);


// internal bracing
down(8) color("#ff0000")  prismoid([10,170], [10,120], 8);
zrot(90) down(8) color("#ff0000")  prismoid([10,200], [10,150], 8);
}

}

/*
 * The neck gets pretty complicated.
 * We start with a half cylinder of the right length. To get the cross
 * section that we want, we then stretch its width by 1.3, and its
 * height and 1.2.
 *
 * Then we add the head. It'll probably get tweaked a bit to make it
 * prettier, but for now, it's a box set at a 20 degree declination
 * from the next, rounded at the back.
 *
 * Next, we add a heel, which I moved into another module.
 *
 * After the heel, we'll add the nut up at the top of the neck.
 *
 * Right next to the nut will be the fingerboard, with fret slots. (I
 * strongly prefer real  metal frets, so I'm just using slots, not
 * creating printed frets.
 */
module neck(offset, length, width, thickness, scale, solid = false) {
  /*
   * For creating the neck, it'll make things easier to start
   * with a half-cylinder.
   */
  module half_cylinder(radius, length) {
    union() {
      difference() {
        rotate([ 0, 90, 0 ]) { cylinder(length, radius, radius); }
        translate([ 0, -radius, -radius ]) {
          cube([ length * 3, radius * 2, radius ]);
        }
      }
    }
  }

  module neck_blank(thickness, length) {
    scale([ 1, 1.3, 1.2 ]) { half_cylinder(thickness * 2 / 3, length); }
  }

  module trussrod_cutout(length, neckwidth) {
    union() {
      translate([ 0, -1 / 8 * 25.4, -20 ])
          cube([ length + 20, (1 / 4) * 25.4, 25.4 * (3 / 8) + 20 ]);

      translate([ length, 0, 0 ]) {
        rotate([ 0, 90, 0 ]) {
          scale([ 1, 1.5, 1 ]) cylinder(40, neckwidth / 6, neckwidth / 8);
        }
      }
    }
  }

  module heel(radius, length, thickness, drill = true) {
    translate([ radius, 0, thickness ]) difference() {
      rotate([ 180, 0, 0 ]) {
        difference() {
          linear_extrude(thickness, scale = [ 2.0, 1.5 ], center = false) {
            circle(radius) left(radius) square(radius * 2, thickness);
          }
          translate([ -5 * radius, -radius * 2, 0 ]) {
            cube([ radius * 4, radius * 4, thickness ]);
          }

          if (drill) {
            translate([ -20, 0, 8 ]) {
              rotate([ 0, 90, 0 ]) { cylinder(70, 2.4, 2.4, $fn = 20); }
            }
            translate([ 10, 0, 8 ]) {
              rotate([ 0, 90, 0 ]) { cylinder(30, 4, 4); }
            }

            translate([ -20, 0, 20 ]) {
              rotate([ 0, 90, 0 ]) { cylinder(70, 2.4, 2.4, $fn = 20); }
            }
            translate([ 12, 0, 20 ]) {
              rotate([ 0, 90, 0 ]) { cylinder(30, 4, 4); }
            }
          }
        }
      }
    }
  }

  /**
   * The headstock.
   *
   * This took a ton of time to get to the point where it looks
   * good, and it's also functional. It's basically shaped from
   * two overlapping octagons. It gets thicker and a bit faceted
   * as it comes close to the neck joint.
   */
  module headstock(length, width, thickness) {
    // Anchor point is the center edge of the round section where the
    // headstock meets the body.

    module oct(diam) {
      intersection() {
        square([ diam, diam ], center = true);
        rotate([ 0, 0, 45 ]) square([ diam, diam ], center = true);
      }
    }
    module head_shape(x, z) {
      rotate([ 0, 0, 90 ]) {
        union() {
          back(10) left(10) down(3) color("#ff00ff") mark(x / 4, 4);
          linear_extrude(z) {
            oct(x);
            translate([ 0, 3 * x / 4, 0 ]) { oct(x); }
          }
        }
      }
      // for the area where the head meets the neck joint,
      // we create one half of an octagon, and hull it
      // with a cylinder
      translate([ -x * 3 / 4, 0, 0 ]) {
        hull() {
          translate([ -x / 2, 0, thickness / 3 + thickness / 6 ])
              rotate([ 90, 0, 0 ]) cylinder(width * 1.2, thickness / 2.3,
                                            thickness / 2.3, center = true);

          linear_extrude(height = z) {
            difference() {
              oct(x);
              translate([ -x * 0.2, -x / 2 ]) square([ x, x ]);
            }
          }
        }
      }
    }

    translate([ -65, -23, -45 ]) union() {
      translate([ width * 3.4, width / 2.0, thickness * 2 + 3 ]) {
        rotate([ 0, -20, 0 ]) {
          difference() {  // create the basic head shape, and then drill holes
                          // into it for the tuners. The tuners that I'm using
                          // require 10mm holes.
            head_shape(width * 1.5, thickness / 2);
            // The x=5 here is totally pragmatic:  I thought it would be
            // -width/2, but in practice, that just wasn't the right location
            // - it wasn't centered properly, but adding a 5mm translation
            // fixed it.
            translate([ 5, 0, -5 ]) {
              translate([ 0, width / 3 ]) cylinder(30, 10, 10);
              translate([ 0, -width / 3 ]) cylinder(30, 10, 10);
            }
            translate([
              -width * 1, 0, -5
            ]) {  // And here, it's exactly as I expected.
              translate([ 0, width / 3 ]) cylinder(30, 10, 10);
              translate([ 0, -width / 3 ]) cylinder(30, 10, 10);
            }
          }
        }
      }
    }
  }

  translate([ 100, 0, 0 ]) union() {
    difference() {
      // First, we have main body of the neck, joined with the headstock and
      // heel.
      union() {
        neck_blank(thickness, length);
        translate([ length - 10, 0, 14 ]) headstock(length, width, thickness);
        heel(width / 3, 50, 50, !solid);
      }

      if (!solid) {
        // Then we cut in the slot for the truss rod, along with a matching
        // cutout in the headstock for truss-rod access.
        trussrod_cutout(length, width);
      }
    }
  }
}

/**
 * The nut at the top of the neck. The height of the nut might need
 * to be tweaked to adjust the string action.
 */
module nut(width, height, thickness, offset) {
  module string_notch(width, depth, elev) {
    translate([ 10, 0, -elev ]) {
      rotate([ -90, 0, 90 ]) {
        linear_extrude(20) {
          polygon([ [ -width / 2, 0 ], [ width / 2, 0 ], [ 0, -depth ] ],
                  [[ 0, 1, 2 ]]);
        }
      }
    }
  }

  translate([ 0, width / 2, 0 ]) {
    difference() {
      rotate([ 0, 180, 180 ]) {
        linear_extrude(thickness, scale = [ 0.7, 1.0 ]) {
          square([ height, width ]);
        }
      }

      // String notches
      dist = (width - 2 * offset) / 3;
      for (str = [0:3]) {
        translate([ 0, -offset - (dist * str), 0 ]) {
          string_notch(width = 2, depth = 3, elev = 10);
        }
      }
    }
  }
}

/**
 * The fingerboard, with fret slots cut into it. Personally,
 * I prefer to use real metal fret wire for frets, so instead of
 * shaping frets into the pattern, I cut out slots to insert fret
 * wire.
 */
module fingerboard(length, width, scale, num_frets) {
  // given a scale length L, fret N is positioned
  // L/(2^1/12) from the bridge.
  C = 2 ^ (1 / 12);
  function fret_position(L, n) = L / (C ^ n);
  function fret_distance(L, n) = fret_position(L, n);
  color("#0000ff") {
    difference() {
      cube([ length, width, 4 ]);

      for (i = [1:num_frets]) {
        translate([ fret_distance(length + 100, i) - 100, -width / 2, -2 ]) {
          cube([ 1, 100, 4 ]);
        }
      }
    }
  }
}

module tapered_tailpiece(width, thickness, depth, border) {
  difference() {
    minkowski() {
      rotate([ -90, 0, 90 ]) linear_extrude(depth, scale = [ 0.8, 0.6 ])
          square([ width, thickness ], center = true);
      // cube([ depth, width, 10 ], center = true);
      sphere(depth / 10);
    }
    hole_zone = width - 2 * border;
    hole_sep = hole_zone / 3;
    for (s = [0:3]) {
      pos = (-hole_zone / 2) + (s * hole_sep);
      translate([ -(depth * 3 / 4), pos, -20 ]) { cylinder(40, 2, 2); }
      translate([ -depth - 2, pos, -20 ]) { cylinder(40, 2, 2); }
    }
  }
}

module bridge(width, height) {
  translate([ 0, 0, -height * 2 ]) {
    difference() {
      union() {
        linear_extrude(height, scale = [ 3, 1.3 ], center = false) {
          square([ 2, neck_width ], center = true);
        }
        up(height / 2)
            prismoid(size1 = [ 2, 2 ], size2 = [ 15, 2 ], height = height / 2);
        fwd(width / 2.2) up(height / 2)
            prismoid(size1 = [ 2, 2 ], size2 = [ 15, 2 ], height = height / 2);

        back(width / 2.2) up(height / 2)
            prismoid(size1 = [ 2, 2 ], size2 = [ 15, 2 ], height = height / 2);
      }

      edge = width / 5;
      dist = (width - 2 * edge) / 3;
      for (n = [0:3]) {
        back(width / 2 - (edge + n * dist)) prismoid([ 5, 1.5 ], [ 5, .75 ], 1);
      }
      fwd(width / 4) up(height) zrot(90) yrot(180)
          prismoid([ width / 3, height / 2 ], [ width / 8, height / 2 ], 10);
      back(width / 4) up(height) zrot(90) yrot(180)
          prismoid([ width / 3, height / 2 ], [ width / 8, height / 2 ], 10);
    }
  }
}

module tenor_guitar(size = 80, separated = false, make_body = true,
                    make_fingerboard = true, make_neck = true,
                    make_bridge = true) {
  fingerboard_layout_offset = separated ? -200 : 0;
  neck_layout_offset = separated ? -400 : 0;
  union() {
    if (make_body) {
      body(size, size * 3 / 8, separated);
    }
    if (make_neck) {
      fwd(neck_layout_offset) translate([ 0, 0, -18 ]) {
        neck(100, neck_length_mm - neck_offset, neck_width, neck_thickness,
             18 * 25.4);
      }
      left(neck_length_mm + 100) back(400)
          translate([ neck_length_mm - 4, 0, -15 ])
              nut(neck_width, neck_width / 9, neck_width / 5, neck_width / 9);
    }

    if (make_fingerboard) {
      fwd(fingerboard_layout_offset) translate([ 100, -neck_width / 2, -22 ])
          color("#00FFFF") fingerboard(neck_length_mm - neck_offset - 4,
                                       neck_width, 18 * 25.4, 20);
    }

    if (make_bridge) {
      fwd(fingerboard_layout_offset) translate([ -size / 2, 0, 5 ]) {
        bridge(neck_width, 17);
      }
    }
  }
}

// My maker's mark.
module mark(size, thickness) {
  w = size;
  h = 6 * size / 5;

  line = w / 12;

  // Left leg of the M
  union() {
    cube([ line, h, thickness ]);
    cube([ w / 4, line, thickness ]);
  }

  union() {
    zrot(180) right(-w / 4) fwd(h) {
      cube([ line, h * 3 / 4, thickness ]);
      cube([ w / 8, line, thickness ]);
    }
  }

  // Right leg
  right(w) union() {
    cube([ line, h, thickness ]);
    left(w / 4 - line) cube([ w / 4, line, thickness ]);
  }
  right(3 * w / 4 - line) union() {
    right(w / 8 + line / 2) zrot(180) fwd(h) xflip() {
      cube([ line, h * 3 / 4, thickness ]);
      cube([ w / 8, line, thickness ]);
    }
  }

  // center V
  right(w / 2 + line / 2) back(h / 2.1) scale([ 1, 1.2, 1 ]) {
    zrot(-135) {
      union() {
        cube([ w / 2.2, line, thickness ]);
        cube([ line, w / 2.2, thickness ]);
      }
    }
  }

  // Left C
  cheight = h / 2.5;
  up(thickness / 2) back(h * 3 / 4) right(w / 4 + line) yrot(90) zrot(90) {
    difference() {
      prismoid([ cheight / 1.5, thickness ], [ cheight, thickness ], w / 5);
      up(w / 12) prismoid([ cheight / 3, thickness ],
                          [ cheight / 2, thickness ], w / 10);
    }
  }

  // Right C
  up(thickness / 2) back(h * 3 / 4) right(w * 3 / 4 - 2 * line) yrot(90)
      zrot(90) difference() {
    difference() {
      prismoid([ cheight / 1.5, thickness ], [ cheight, thickness ], w / 5);
      up(w / 12) prismoid([ cheight / 3, thickness ],
                          [ cheight / 2, thickness ], w / thickness);
    }
  }
}

/**
 * I want a scale length of about 18 inches.
 * The bridge should be about 3 inches from the tail - so the
 * body from bridge to neck will be about 5 3/4 inches, leaving us a
 * neck length of 12 1/4 inches.
 */
neck_length_mm = 18 * 25.4;
neck_offset = 100;
neck_thickness = 30;
neck_width = 50;

tenor_guitar(80, separated = true,

make_fingerboard=false, make_neck=false, make_bridge=false
);