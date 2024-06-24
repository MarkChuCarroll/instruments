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

/**
 * We want the body to be hollow. So what we do is create
 * one copy of the body  form, and then a second scaled version that's a bit
 * smaller - and we subtract the smaller one from the larger.
 */
module body(size, thickness) {
  // I want a a teardrop shaped body. SCAD can do that that by making two
  // cylinders with offset centers, and then taking their hull. We get
  // a bit of slant by making the larger cylinder actually a bit conic,
  // but square up at the heel because the smaller is a true cylinder.
  // Then we round the edges by using minkowski sum with a little sphere.
  module body_form(length, thickness) {
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

  difference() {
    body_form(size, thickness);
    translate([ 3, 3, 3 ]) {
      scale([ 0.9, 0.9, 0.9 ]) { body_form(size, thickness); }
    }
    translate([ size / 2, -size / 2, -thickness / 2 ]) {
      scale([ 1.3, 1.0, 1.0 ]) { cylinder(thickness, size / 4, size / 4); }
    }
  }
}

/*
 * For creating the neck, it'll make things easier to start
 * with a half-cylinder.
 */
module half_cylinder(radius, length) {
  difference() {
    rotate([ 0, 90, 0 ]) { cylinder(length, radius, radius); }
    translate([ 0, -radius, -radius ]) {
      cube([ length * 3, radius * 2, radius ]);
    }
  }
}

// The nut at the top of the neck. The height of the nut might need
// to be tweaked to adjust the string action.
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
          string_notch(width = 2, depth = 2, elev = 8);
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
  module oct(diam) {
    intersection() {
      square([ diam, diam ], center = true);
      rotate([ 0, 0, 45 ]) square([ diam, diam ], center = true);
    }
  }
  module head_shape(x, y, z) {
    rotate([ 0, 0, 90 ]) {
      linear_extrude(z) {
        //                minkowski(1)                {
        scale([ 1.0, 1.0, 1.0 ]) {
          oct(x);
          translate([ 0, 3 * x / 4, 0 ]) { oct(x); }
        }
      }
    }

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

  union() {
    translate([ width * 3.4, width / 2.0, thickness * 2 + 3 ]) {
      rotate([ 0, -20, 0 ]) {
        difference() {  // create the basic head shape, and then drill holes
                        // into it for the tuners. The tuners that I'm using
                        // require 10mm holes.
          head_shape(width * 2, width * 0.6, thickness / 2);
          // The x=5 here is totally pragmatic:  I thought it would be
          // -width/2, but in practice, that just wasn't the right location - it
          // wasn't centered properly, but adding a 5mm translation fixed it.
          translate([ 5, 0, -5 ]) {
            translate([ 0, width / 2 ]) cylinder(30, 10, 10);
            translate([ 0, -width / 2 ]) cylinder(30, 10, 10);
          }
          translate([
            -width * 1.5, 0, -5
          ]) {  // And here, it's exactly as I expected.
            translate([ 0, width / 2 ]) cylinder(30, 10, 10);
            translate([ 0, -width / 2 ]) cylinder(30, 10, 10);
          }
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

module neck_blank(thickness, length) {
  scale([ 1, 1.3, 1.2 ]) { half_cylinder(thickness * 2 / 3, length); }
}

module heel(radius, length, thickness) {
  difference() {
    rotate([ 0, 180, 90 ]) {
      difference() {
        linear_extrude(thickness, scale = [ 1.5, 2.0 ], center = false) {
          circle(radius);
          translate([ -radius, 0, 0 ]) { square(radius * 2, thickness); }
        }
        translate([ -radius * 2, radius * 2, 0 ]) {
          cube([ radius * 4, radius * 3, thickness ]);
        }
      }
    }
  }
}

module solid_neck(offset, length, width, thickness, scale) {
  union() {
    union() {
      neck_blank(thickness, length);
      translate([ 20, 0, 50 ]) heel(width * 2 / 6, 50, 50);
    }
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
module neck(offset, length, width, thickness, scale) {
  union() {
    difference() {
      // First, we have main body of the neck, joined with the headstock and
      // heel.
      union() {
        neck_blank(thickness, length);
        translate([ length - 40, -(width) * 0.5, -20 ])
            headstock(length, width, thickness);
        translate([ 20, 0, 50 ]) heel(width * 2 / 6, 50, 50);
      }

      // Then we cut in the slot for the truss rod, along with a matching
      // cutout in the headstock for truss-rod access.
      trussrod_cutout(length, width);
    }

    // and finally, we add the nut.
    translate([ length - 4, 0, 0 ])
        nut(width, width / 9, 2 * width / 9, width / 9);
  }
}

module tailpiece(width, thickness, depth, border) {
  translate([ -110, 0, 10 ]) {
    difference() {
      minkowski() {
        cube([ depth, width, 10 ], center = true);
        sphere(depth / 10);
      }
      hole_zone = width - 2 * border;
      hole_sep = hole_zone / 3;
      for (s = [0:3]) {
        pos = (-hole_zone / 2) + (s * hole_sep);
        translate([ -(depth / 3), pos, -20 ]) {
          cylinder(40, 2, 2);
          translate([ -depth / 4, 0, 0 ]) { cylinder(40, 2, 2); }
        }
      }
    }
  }
}

module assembled() {
  union() {
    body(80, 30);
    translate([ neck_offset, 0, -15 ]) {
      neck(100, neck_length_mm - neck_offset, neck_width, neck_thickness,
           18 * 25.4);
      translate([ -14, -neck_width / 2, -4 ]) color("#00FFFF") fingerboard(
          neck_length_mm - neck_offset + 10, neck_width, 18 * 25.4, 20);
    }
    translate([ -20, 0, -23 ]) {
      linear_extrude(23, scale = [ 3, 1.3 ], center = false)
          square([ 2, neck_width ], center = true);
    }
  }
  tailpiece(neck_width, neck_width / 4, neck_width / 2, neck_width / 6);
}

module pieces() {
  module separated_body() {
    // A section matching the back end of the neck's heel block, which can be
    // used for gluing the neck into the body. Eventually I want to put a hole
    // into the heel, and mount a matching hex-nut in the screwblock for a
    // bolt-on neck.
    module body_screwblock() {
      difference() {
        solid_neck(100, neck_length_mm - neck_offset, neck_width,
                   neck_thickness, 18 * 25.4);
        translate([ 10, -neck_width, 0 ]) {
          cube([
            neck_length_mm,
            neck_width * 2,
            neck_thickness * 2,
          ]);
        }
      }
    }

    union() {
      difference() {
        body(80, 30);
        translate([ neck_offset, 0, -15 ]) {
          solid_neck(100, neck_length_mm - neck_offset, neck_width,
                     neck_thickness, 18 * 25.4);
        }
      }
      translate([ 60, 0, -10 ]) color("#ff0000") body_screwblock();
      tailpiece(neck_width, neck_width / 4, neck_width / 2, neck_width / 6);
    }
  }

  separated_body();
  translate([ 0, 200, 0 ]) {
    neck(100, neck_length_mm - neck_offset, neck_width, neck_thickness,
         18 * 25.4);
  }
  translate([ 0, 400, 0 ]) {
    fingerboard(neck_length_mm - neck_offset + 10, neck_width, 18 * 25.4, 20);
  }
}

// I want a scale length of about 18 inches.
// The bridge should be about 3 inches from the tail - so body_form
// from bridge to neck will be about 5 3/4 inches, leaving us a
// neck length of 12 1/4 inches.
neck_length_mm = 18 * 25.4;
neck_offset = 100;
neck_thickness = 30;
neck_width = 50;
assembled();
translate([ 0, 200, 0 ]) pieces();