#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wlBcWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Based on http://staffwww.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
The pdf gives details and code for both perlin and simplex noise in Java.
*/
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

    // vec3 ijk1, ijk2;

    vec3 ijk1 =
        float(xyz0.x >= xyz0.y && xyz0.x >= xyz0.z)*vec3(1,0,0) +
        float(xyz0.y >= xyz0.x && xyz0.y >= xyz0.z)*vec3(0,1,0) +
        float(xyz0.z >= xyz0.x && xyz0.z >= xyz0.y)*vec3(0,0,1);

    vec3 ijk2 =
        float(xyz0.x < xyz0.y && xyz0.x < xyz0.z)*vec3(0,1,1) +
        float(xyz0.y < xyz0.x && xyz0.y < xyz0.z)*vec3(1,0,1) +
        float(xyz0.z < xyz0.x && xyz0.z < xyz0.y)*vec3(1,1,0);

    /*
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
    */

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

float noise(vec3 pos)
{
    float x0 = A*simplex3d(pos*F);
    float x1 = A*A*simplex3d(pos*F*2.);
    float x2 = A*A*A*simplex3d(pos*F*4.);
    float x3 = A*A*A*A*simplex3d(pos*F*8.);
    float x4 = A*A*A*A*A*simplex3d(pos*F*16.);

    return 4.*(x0 + x1 + x2 + x3 + x4);
}

#define MAX_ITERS 100

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5)/(resolution.xy-1.);
    uv = 2.*uv-1.;
    uv.x *= resolution.x/resolution.y;

    uv *= 4.;
    // vec3 camera_pos = vec3(2.*cos(time), 0., 2.*sin(time));
    // vec3 camera_pos += vec3(0., 0., 2.+sin(time));
    // vec3 camera_lookat = vec3(0.);
    vec3 camera_pos = vec3(0., 0., -time);
    vec3 camera_lookat = camera_pos + vec3(0., 0., -1.);
    vec3 camera_forward = normalize(camera_lookat - camera_pos);
    vec3 world_up = vec3(0., 1., 0.);
    vec3 camera_right = normalize(cross(camera_forward, world_up));
    vec3 camera_up = normalize(cross(camera_right, camera_forward));
    float focal_dist = 1.;
    vec3 pixel_pos = camera_pos + focal_dist*camera_forward + uv.x*camera_right + uv.y*camera_up;

    vec3 ray_o = camera_pos;// pixel_pos;
    vec3 ray_d = normalize(pixel_pos - camera_pos);

    vec3 acc = vec3(0.);
    vec3 d = vec3(0.);

    for(int i=0; i<MAX_ITERS; i++)
    {
        acc.x += noise(ray_o + d.x*ray_d);
        acc.y += noise(ray_o + d.y*ray_d);
        acc.z += noise(ray_o + d.z*ray_d);
        d += vec3(0.01, 0.02, 0.04);
        if(acc.x > 100.)break;
    }

    // vec3 col = vec3(simplex3d(vec3(uv, time)));
    vec3 col = vec3(acc*.01);
    // vec3 col = pow(acc*.05, vec3(4.));
    glFragColor = vec4(col,1.0);
}
