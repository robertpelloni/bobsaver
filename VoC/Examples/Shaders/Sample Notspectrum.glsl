#version 420

// original https://www.shadertoy.com/view/7tcGWN

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TURN = acos(-1.) * 2.;
// random ints from 0 to 255
int rand[] = int[] (
244,    69,    224,    39,    208,    151,    201,    255,    189,    202,    157,    92,    206,    154,    199,    194,    232,    101,    216,    134,    62,    242,    163,    248,    140,    183,    120,    90,    215,    30,    211,    186,    150,    100,    57,    106,    118,    142,    61,    246,    11,    230,    141,    55,    147,    180,    27,    226,    99,    125,    122,    13,    2,    112,    192,    60,    137,    80,    198,    252,    94,    245,    162,    113,    24,    146,    49,    110,    253,    81,    10,    165,    109,    115,    218,    0,    254,    129,    71,    88,    187,    114,    176,    243,    7,    87,    45,    209,    23,    168,    103,    121,    93,    153,    22,    133,    34,    78,    241,    182,    221,    38,    136,    104,    18,    105,    164,    65,    91,    25,    132,    119,    174,    173,    15,    170,    29,    37,    212,    210,    44,    169,    181,    251,    4,    8,    229,    79,    32,    21,    203,    214,    75,    12,    225,    97,    40,    35,    28,    64,    231,    19,    185,    123,    236,    77,    238,    5,    128,    179,    127,    48,    72,    156,    190,    54,    124,    250,    205,    161,    228,    56,    158,    207,    148,    17,    95,    52,    111,    126,    36,    74,    197,    152,    160,    20,    219,    130,    66,    239,    240,    6,    108,    47,    116,    213,    237,    138,    70,    33,    26,    46,    96,    53,    41,    200,    59,    58,    135,    83,    235,    31,    131,    63,    42,    1,    149,    139,    247,    9,    159,    73,    98,    222,    68,    51,    67,    144,    82,    233,    177,    155,    178,    50,    143,    84,    184,    85,    217,    166,    193,    145,    89,    107,    172,    76,    117,    196,    86,    220,    3,    171,    223,    16,    167,    195,    191,    102,    14,    188,    227,    234,    204,    249,    43,    175
);
float thres(vec2 xyf, int t) {
    ivec2 xy = ivec2(xyf);
    
    return (0.5 + float(
        rand[
            (t + rand[
                ((xy.x >> 4) + xy.y + rand[
                    ((xy.y >> 4) + xy.x) & 255
                ]) & 255
            ]) & 255
        ]
    )) / 256.;
}

// fade function defined by ken perlin
#define fade(t) (t * t * t * (t * (t * 6. - 15.) + 10.))

// corner vector
vec2 cvec(vec2 uv, float time) {
  int x = int(mod(uv.x, 256.));
  int y = int(mod(uv.y, 256.));
  float n = (float(rand[(x + rand[y]) & 255]) / 255. + time) * TURN;
  return vec2(
      sin(n), cos(n)
  );
}
// perlin generator
float perlin(vec2 uv, float offset) {
  vec2 i = floor(uv);
  vec2 f = fract(uv);

  vec2 u = fade(f);
  offset = fract(offset);

  return
  mix(
    mix(
      dot( cvec(i + vec2(0.0,0.0), offset ), f - vec2(0.0,0.0) ),
      dot( cvec(i + vec2(1.0,0.0), offset ), f - vec2(1.0,0.0) ),
    u.x),
    mix(
      dot( cvec(i + vec2(0.0,1.0), offset ), f - vec2(0.0,1.0) ),
      dot( cvec(i + vec2(1.0,1.0), offset ), f - vec2(1.0,1.0) ),
    u.x),
  u.y);
}

#define HEX(x) vec3((ivec3(x) >> ivec3(16, 8, 0)) & 255) / 255.
vec3 color(float x){
    const int colorCount = 8;
    vec3[] c = vec3[](
        vec3(0),
        HEX(0xe020c0),
        HEX(0xf0e040),
        HEX(0xc0ff80),
        vec3(1),
        HEX(0xa0ffe0),
        HEX(0x7080F0),
        HEX(0x8000a0)
    );
    x *= float(colorCount);
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        fract(x)
    );
}

void main(void)
{
    float time = fract(time / 4.);
    // Scales pixel coordinates, so that
    // the center is distance 0 and
    // diagonals are distance 1
    vec2 uvR = 2. * gl_FragCoord.xy - resolution.xy;
    vec2 uv = uvR / length(resolution.xy);

    float lenSq = log(dot(uv, uv));
    float angle = atan(uv.y, uv.x) / TURN;
    
    float spiral = 
         lenSq * 0.3
       + angle * 1.
       + time * -3.
       + 0.08 * sin((time * 2. + lenSq * 0.5 + angle * 2.) * TURN)
       + 0.08 * sin((time * -1. + lenSq * 0.2 + angle * -4.) * TURN)
    ;
    const float STEPS = 32.;
    spiral += 0.2 * perlin(uv * 8., time);
    spiral *= STEPS;
    spiral = floor(spiral) + step(thres(gl_FragCoord.xy, frames), fract(spiral));
    spiral /= STEPS;

    // Time varying pixel color
    vec3 col = color(
        fract(spiral)
    );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
