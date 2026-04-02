#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdSSWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 ones = vec4(1.0);

float sum(vec4 a)
{
    return dot(a,ones);   
}
float sum(vec3 a)
{    
    return dot(a,ones.xxx);
}
float sum(vec2 a)
{
    return dot(a,ones.xx);
}

int floor_to_int(float x)
{
    return int(floor(x));
}

int quick_floor(float x)
{
    return int(x) - 1 + int(step(0.,x));
}

float integer_noise(int n)
{
    int nn;
    n = (n + 1013) & 0x7fffffff;
    n = (n >> 13) ^ n;
    nn = (n * (n * n * 60493 + 19990303) + 1376312589) & 0x7fffffff;
    return 0.5 * (float(nn) / 1073741824.0);
}

uint hash(uint kx, uint ky, uint kz)
{
#define rot(x, k) (((x) << (k)) | ((x) >> (32 - (k))))
#define final(a, b, c) \
{ \
    c ^= b; c -= rot(b, 14); \
    a ^= c; a -= rot(c, 11); \
    b ^= a; b -= rot(a, 25); \
    c ^= b; c -= rot(b, 16); \
    a ^= c; a -= rot(c, 4);  \
    b ^= a; b -= rot(a, 14); \
    c ^= b; c -= rot(b, 24); \
}
    // now hash the data!
    uint a, b, c, len = 3u;
    a = b = c = 0xdeadbeefu + (len << 2u) + 13u;

    c += kz;
    b += ky;
    a += kx;
    final (a, b, c);

    return c;
#undef rot
#undef final
}

uint hash(int kx, int ky, int kz)
{
    return hash(uint(kx), uint(ky), uint(kz));
}

float bits_to_01(uint bits)
{
    return (float(bits) / 4294967295.0);
}

float cellnoise(vec3 p)
{
    int ix = quick_floor(p.x);
    int iy = quick_floor(p.y);
    int iz = quick_floor(p.z);

    return bits_to_01(hash(ix,iy,iz));
}

vec3 cellnoise_color(vec3 p)
{
    float r = cellnoise(p.xyz);
    float g = cellnoise(p.yxz);
    float b = cellnoise(p.yzx);

    return vec3(r, g, b);
}

void node_tex_voronoi(vec3 co, float scale, float exponent, float coloring, float metric, float feature, out vec4 color, out float fac)
{
    vec3 p = co * scale;
    int xx, yy, zz, xi, yi, zi;
    float da[4];
    vec3 pa[4];

    xi = floor_to_int(p[0]);
    yi = floor_to_int(p[1]);
    zi = floor_to_int(p[2]);

    da[0] = 1e+10;
    da[1] = 1e+10;
    da[2] = 1e+10;
    da[3] = 1e+10;

    for (xx = xi - 2; xx <= xi + 2; xx++) {
        for (yy = yi - 2; yy <= yi + 2; yy++) {
            for (zz = zi - 2; zz <= zi + 2; zz++) {
                vec3 ip = vec3(xx, yy, zz);
                vec3 vp = cellnoise_color(ip);
                vec3 pd = p - (vp + ip);

                float d = 0.0;
                if (metric == 0.0) { /* SHD_VORONOI_DISTANCE 0 */
                    d = dot(pd, pd);
                }
                else if (metric == 1.0) { /* SHD_VORONOI_MANHATTAN 1 */
                    d = sum(abs(pd));
                }
                else if (metric == 2.0) { /* SHD_VORONOI_CHEBYCHEV 2 */
                    d = max(abs(pd[0]), max(abs(pd[1]), abs(pd[2])));
                }
                else if (metric == 3.0) { /* SHD_VORONOI_MINKOWSKI 3 */
                    d = pow(sum(pow(abs(pd), vec3(exponent))), 1.0/exponent);
                }

                vp += ip;
                if (d < da[0]) {
                    da[3] = da[2];
                    da[2] = da[1];
                    da[1] = da[0];
                    da[0] = d;
                    pa[3] = pa[2];
                    pa[2] = pa[1];
                    pa[1] = pa[0];
                    pa[0] = vp;
                }
                else if (d < da[1]) {
                    da[3] = da[2];
                    da[2] = da[1];
                    da[1] = d;

                    pa[3] = pa[2];
                    pa[2] = pa[1];
                    pa[1] = vp;
                }
                else if (d < da[2]) {
                    da[3] = da[2];
                    da[2] = d;

                    pa[3] = pa[2];
                    pa[2] = vp;
                }
                else if (d < da[3]) {
                    da[3] = d;
                    pa[3] = vp;
                }
            }
        }
    }
    /* Color output */
    vec3 col = vec3(fac, fac, fac);
    if (feature == 0.0) { /* F1 */
        col = pa[0];
        fac = abs(da[0]);
    }
    else if (feature == 1.0) { /* F2 */
        col = pa[1];
        fac = abs(da[1]);
    }
    else if (feature == 2.0) { /* F3 */
        col = pa[2];
        fac = abs(da[2]);
    }
    else if (feature == 3.0) { /* F4 */
        col = pa[3];
        fac = abs(da[3]);
    }
    else if (feature == 4.0) { /* F2F1 */
        col = abs(pa[1] - pa[0]);
        fac = abs(da[1] - da[0]);
    }

    if (coloring == 0.0) {
        color = vec4(fac, fac, fac, 1.0);
    }
    else {
        color = vec4(cellnoise_color(col), 1.0);
    }
}

const float scale = 0.005;
const float exponent = 0.5;
const float coloring = 1.;
const float metric = 0.;
const float feature = 1.;

void main(void)
{
    vec3 p = vec3(gl_FragCoord.xy,time*50.);
    vec4 color;
    float fac;
    node_tex_voronoi(p,  scale,  exponent,  coloring,  metric,  feature, color, fac);
    glFragColor = color * (1.-sin(fac*150.));
}
