#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlXfz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// MARCHING SQUARES
// See https://en.wikipedia.org/wiki/Marching_squares and https://youtu.be/0ZONMNUKTfU for more details.

// Simplex noise in 3d

#define R2 .6
#define A .5
#define F 1.

const vec3[] grad = vec3[](
    vec3(1,1,0),vec3(-1,1,0),vec3(1,-1,0),vec3(-1,-1,0),
    vec3(1,0,1),vec3(-1,0,1),vec3(1,0,-1),vec3(-1,0,-1),
    vec3(0,1,1),vec3(0,-1,1),vec3(0,1,-1),vec3(0,-1,-1)
);

const int perm[] = int[](151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180);

int hash(ivec3 p)
{
    return perm[p.x+perm[p.y+perm[p.z]]]%12;
}

vec3 skew(vec3 p)
{
    return p+(p.x+p.y+p.z)/3.;
}

vec3 unskew(vec3 p)
{
    return p-(p.x+p.y+p.z)/6.;
}

float simplex3d(vec3 xyz)
{
    vec3 ijk = floor(skew(xyz));
    vec3 XYZ0 = unskew(ijk);

    vec3 xyz0 = xyz - XYZ0;

    vec3 ijk1, ijk2;
    if(xyz0.x >= xyz0.y)
    {
        if(xyz0.y >= xyz0.z)
        {
            ijk1 = vec3(1,0,0);
            ijk2 = vec3(1,1,0);
        }
        else if(xyz0.x >= xyz0.z)
        {
            ijk1 = vec3(1,0,0);
            ijk2 = vec3(1,0,1);
        }
        else
        {
            ijk1 = vec3(0,0,1);
            ijk2 = vec3(1,0,1);
        }
    }
    else
    {
        if(xyz0.y < xyz0.z)
        {
            ijk1 = vec3(0,0,1);
            ijk2 = vec3(0,1,1);
        }
        else if(xyz0.x < xyz0.z)
        {
            ijk1 = vec3(0,1,0);
            ijk2 = vec3(0,1,1);
        }
        else
        {
            ijk1 = vec3(0,1,0);
            ijk2 = vec3(1,1,0);
        }
    }

    vec3 xyz1 = xyz0 - unskew(ijk1);
    vec3 xyz2 = xyz0 - unskew(ijk2);
    vec3 xyz3 = xyz0 - unskew(vec3(1,1,1));

       ivec3 IJK = ivec3(ijk) & 0xFF;
    int gi0 = hash(IJK);
    int gi1 = hash(IJK + ivec3(ijk1));
    int gi2 = hash(IJK + ivec3(ijk2));
    int gi3 = hash(IJK + ivec3(1,1,1));

    float n0 = pow(max(R2 - dot(xyz0, xyz0), 0.), 4.)*dot(grad[gi0], xyz0);
    float n1 = pow(max(R2 - dot(xyz1, xyz1), 0.), 4.)*dot(grad[gi1], xyz1);
    float n2 = pow(max(R2 - dot(xyz2, xyz2), 0.), 4.)*dot(grad[gi2], xyz2);
    float n3 = pow(max(R2 - dot(xyz3, xyz3), 0.), 4.)*dot(grad[gi3], xyz3);

    return 32.*(n0+n1+n2+n3);
}

// Square marching starts here

bool random_bool(ivec2 p)
{
    //return simplex3d(vec3(p,0.))>0.;
    return simplex3d(vec3(vec2(p)*.1,time))>0.;
}

int combine(bool b3, bool b2, bool b1, bool b0)
{
    return int(b3)*8+int(b2)*4+int(b1)*2+int(b0);
}

const vec2[] axes = vec2[](
    vec2(1,0),
    normalize(vec2(1,1)),
    normalize(vec2(-1,1)),
    vec2(0,1),
    normalize(vec2(1,1)),
    normalize(vec2(-1,1)),
    vec2(1,0),
    normalize(vec2(-1,1)),
    normalize(vec2(-1,1)),
    vec2(1,0),
    normalize(vec2(1,1)),
    normalize(vec2(1,1)),
    vec2(0,1),
    normalize(vec2(-1,1)),
    normalize(vec2(1,1)),
    vec2(1,0)
);

// lines passing through (-4,-2) will be offscreen for all the 4 different slopes we use.
const vec4[] points = vec4[](
    vec4(-4,-4,-4,-2),
    vec4( 0,-1,-4,-2),
    vec4( 0,-1,-4,-2),
    vec4( 0, 0,-4,-2),

    vec4( 0, 1,-4,-2),
    vec4( 0, 1, 0,-1),
    vec4( 0, 0,-4,-2),
    vec4( 0, 1,-4,-2),

    vec4( 0, 1,-4,-2),
    vec4( 0, 0,-4,-2),
    vec4( 0, 1, 0,-1),
    vec4( 0, 1,-4,-2),

    vec4( 0, 0,-4,-2),
    vec4( 0,-1,-4,-2),
    vec4( 0,-1,-4,-2),
    vec4(-4,-4,-4,-2)
);

float line_d(vec2 p, vec2 axis, float width)
{
    return abs(dot(p,axis))-width;
}

vec2 combine_dots(vec2 dot1, vec2 dot2)
{
    return dot1.x <= dot2.x ? dot1 : dot2;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5)/(resolution.xy-1.);
    uv = 2.*uv-1.;
    uv.x *= resolution.x/resolution.y;

    uv *= 10.;

    ivec2 bl = ivec2(floor(uv));
    ivec2 br = bl + ivec2(1,0);
    ivec2 tl = bl + ivec2(0,1);
    ivec2 tr = bl + ivec2(1,1);

    bool bbl = random_bool(bl);
    bool bbr = random_bool(br);
    bool btr = random_bool(tr);
    bool btl = random_bool(tl);
    int index = combine(btl, btr, bbr, bbl);
    //int index = combine(random_bool(tl), random_bool(tr), random_bool(br), random_bool(bl));

    vec2 xy = 2.*fract(uv)-1.;
    vec4 points_on_lines = points[index];
    vec2 axis = axes[index];
    const float line_width = 0.1;
    float d1 = line_d(xy-points_on_lines.xy, axis, line_width);
    float d2 = line_d(xy-points_on_lines.zw, axis, line_width);
    float d = min(d1, d2);
    float mask = smoothstep(0.,.01,d);
    vec3 col = vec3(mask);
    //col -= vec3(fract(uv),0.); // for debugging purposes

    // dots
    const float dot_size = .1;
    float dbl = length(uv-vec2(bl))-dot_size;
    float dbr = length(uv-vec2(br))-dot_size;
    float dtl = length(uv-vec2(tl))-dot_size;
    float dtr = length(uv-vec2(tr))-dot_size;
    vec2 dot_dist = combine_dots(vec2(dbl,bbl), vec2(dbr, bbr));
    dot_dist = combine_dots(dot_dist, vec2(dtr, btr));
    dot_dist = combine_dots(dot_dist, vec2(dtl, btl));
    //float dot_dist = min(min(min(dbl, dbr), dtl), dtr);
    float dot_mask = smoothstep(0.,.01, dot_dist.x);
    col = mix(col, vec3(dot_dist.y), 1.-dot_mask);
    col = 1.-col; // dark mode

    glFragColor = vec4(col,1.0);
}
