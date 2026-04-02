#version 420

// original https://www.shadertoy.com/view/NddGzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*****************************************
 * Pseudo-Super-Hexagon (ver: 1.1, 2020) *
 *    shader by PDKL95                   *
 *                                       *
 * (with apologies to Terry Cavanagh)    *
 *****************************************/

#define TAU 6.283185307179586

#define NSEC 6*
#define SPINRATE 3.0
#define DEPTHRATE 10.0
#define DEPTHSCALE 10.0
#define INNERWALLSIZE 0.01
#define INNERRADIUS 0.2
#define INNERBEATSIZE 0.01
#define INNERBEATRATE 6.0

#define COLORSPEED 1.8

#define COLOR_1_FG  vec3(0.96, 0.96, 0.96)
#define COLOR_1_BG1 vec3(0.67, 0.67, 0.67)
#define COLOR_1_BG2 vec3(0.53, 0.53, 0.53)
#define COLOR_2_FG  vec3(0.93, 0.93, 0.93)
#define COLOR_2_BG1 vec3(0.44, 0.44, 0.44)
#define COLOR_2_BG2 vec3(0.35, 0.35, 0.35)

#define nsin(x) ((sin(x) + 1.0) / 2.0)

#define NUMWALLS 128

const int BIT_COUNT = 8;

int modi(int x, int y) {
    return x - y * (x / y);
}

int and(int a, int b) {
    int result = 0;
    int n = 1;

    for(int i = 0; i < BIT_COUNT; i++) {
        if ((modi(a, 2) == 1) && (modi(b, 2) == 1)) {
            result += n;
        }

        a = a / 2;
        b = b / 2;
        n = n * 2;

        if(!(a > 0 && b > 0)) {
            break;
        }
    }
    return result;
}

vec3 rgb2hsv(in vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(in vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rotate(in vec2 point, in float rads)
{
    float cs = cos(rads);
    float sn = sin(rads);
    return point * mat2(cs, -sn, sn, cs);
}

void main(void)
{
    float px = 1.0/resolution.y;
    float aspect = resolution.y/resolution.x;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 position = (uv * 2.0) - 1.0;

    if (aspect < 1.0) {
        aspect = 1.0/aspect;
        position.x *= aspect;
    } else {
        position.y *= aspect;
    }

    float spintime = time * SPINRATE;
    spintime = (0.4 * spintime) + sin(0.7 * spintime) + sin(0.2 * spintime);
    float spin = mod(spintime, TAU);

    float realdepth = time * DEPTHRATE;

    vec2 rposition = rotate(position, spin);

#if 0
    const mat3 proj_matrix = mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(    0.0, 3.0/4.0, 0.0),
        vec3(    0.0, 0.0, 0.5)
    );

    float r3d_theta_x = (TAU/12.0) * sin(time * 2.0);
    float r3d_sintx = sin(r3d_theta_x);
    float r3d_costx = cos(r3d_theta_x);
    mat3 rotx_matrix = mat3(
        vec3(1.0,        0.0,       0.0),
        vec3(0.0,  r3d_costx, r3d_sintx),
        vec3(0.0, -r3d_sintx, r3d_costx)
    );

    float r3d_theta_y = (TAU/16.0) * sin(time * 0.4);
    float r3d_sinty = sin(r3d_theta_y);
    float r3d_costy = cos(r3d_theta_y);
    mat3 roty_matrix = mat3(
        vec3( r3d_costy, 0.0, r3d_sinty),
        vec3(       0.0, 1.0,       0.0),
        vec3(-r3d_sinty, 0.0, r3d_costy)
    );

    vec3 pos3 = vec3(rposition.xy, 0.0);
    vec3 proj_pos = proj_matrix * pos3;
    float perspective_factor = proj_pos.z * 0.5 + 1.0;
    rposition = proj_pos.xy/perspective_factor;
#endif

    float r = length(rposition);
    float theta = atan(rposition.y, rposition.x);
    theta += TAU/2.0;
    float section = 6.0 * (theta/TAU);
    float zone = floor(section);
    float zonefrag = mod(section, 1.0);
    float odd  = mod(zone, 2.0);

    float color_fade = nsin(time * COLORSPEED);
    vec3 color_fg  = mix(COLOR_1_FG,  COLOR_2_FG,  color_fade);
    vec3 color_bg1 = mix(COLOR_1_BG1, COLOR_2_BG1, color_fade);
    vec3 color_bg2 = mix(COLOR_1_BG2, COLOR_2_BG2, color_fade);

    vec3 color = mix(color_bg1, color_bg2, odd);

    float dist_to_edge = abs(zonefrag - 0.5) * 2.0;
    float angle_to_edge = dist_to_edge * (TAU / 12.0);

    float hexradius = cos(TAU - angle_to_edge) * r;
    float depth = (hexradius * DEPTHSCALE) + realdepth;

    float ib = INNERBEATRATE * time;
    float ir = 2.1 +
        (3.0 * sin(ib)) +
        (4.0 * cos(ib)) -
        (      sin(ib * 2.0)) -
        (2.1 * cos(ib * 2.0));
    ir = INNERRADIUS - (INNERBEATSIZE * abs(ir));

    if (hexradius < ir) {
        if ((ir - hexradius) < INNERWALLSIZE) {
            color = color_fg;
        }
    } else {
        // float row = floor(depth);
        // float oddrow = mod(row, 2.0);
        // color = mix(color_fg, color, oddrow);

        float moddepth = floor(mod(depth, 128.0));
        int wallidx = int(moddepth);

#define wall(idx, val) if (wallidx == (idx)) { curwall = (val); } else

#define MAXWALL 126
    int curwall = 0;
        if (wallidx < MAXWALL) {
        if (wallidx < 37) {
        if (wallidx < 19) {
            wall( 1, 0x2a)
                wall( 4, 0x15)
                wall( 7, 0x2a)
                wall(10, 0x15)
                wall(13, 0x2a)
                wall(16, 0x1b)
            {}
        } else {
                wall(19, 0x2d)
                wall(22, 0x36)
            wall(25, 0x2d)
                wall(28, 0x1b)
                wall(31, 0x36)
                wall(34, 0x2f)
            {}
        }
        } else if (wallidx < 67) {
        if (wallidx < 53) {
            wall(37, 0x1b)
                wall(38, 0x09)
                wall(39, 0x24)
                wall(40, 0x12)
                wall(41, 0x09)
                wall(42, 0x24)
                wall(43, 0x12)
                wall(44, 0x09)
                wall(45, 0x2d)
                wall(50, 0x3e)
            {}
            } else {
            wall(53, 0x1b)
                wall(54, 0x12)
                wall(55, 0x24)
                wall(56, 0x09)
                wall(57, 0x12)
                wall(58, 0x24)
                wall(59, 0x09)
                wall(60, 0x12)
                wall(61, 0x36)
            {}
        }
        } else {
        if (wallidx < 104) {
            wall(67, 0x1f)
                wall(72, 0x3b)
                wall(77, 0x1f)
                wall(83, 0x1f)
                wall(88, 0x3b)
                wall(93, 0x2f)
                wall(99, 0x1f)
            {}
        } else {
            wall(104, 0x3b)
                wall(109, 0x3e)
                wall(114, 0x2a)
                wall(116, 0x2a)
                wall(120, 0x1f)
                wall(125, 0x2f)
            {}
        }
        }
        }

    
    int mask = 1;
    int izone = int(zone);
#define zmask(z,m) if (izone == z) {mask = m; } else
    zmask(1, 2)
    zmask(2, 4)
    zmask(3, 8)
    zmask(4, 16)
    zmask(5, 32)
    {}

    curwall = and(curwall, mask);
        if (curwall > 0) {
            color = color_fg;
        }
    }

    glFragColor = vec4(color, 1.0);
}
