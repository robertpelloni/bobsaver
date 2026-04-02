#version 420

// original https://www.shadertoy.com/view/3llBR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time2 time*0.5
// All components are in the range [0…1], including hue.
//rgb2hsv & hsv2rgb from http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

 

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
mat2 r2d(float a) {
    return mat2(sin(a),cos(a),-cos(a),sin(a));
}

float cr(vec2 uv) {
    float col = 0.;
    col = (sin(uv.y+time2*1.));
    col += (sin(uv.x*10.));
    return col;
}

//from https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec2 getDist(vec3 p) {
    //d = min(d,sdBox(vec3(p.x+5.,p.y+bd+2.,p.z),vec3(bd3,bd2,bd2)));
    //return d;
    float rd = 0.02;
    
    float id = 0.+p.y*0.02;
    //p = floor(p*2)/10.;
    //p.zy *= r2d(mouse.x*2.);
    //p.xz = (fract(p.xz*rd)-0.5)/rd;
    p.xz = (fract((abs(p.xz)+5.)*rd)-0.5)/rd;
    //p.xy *= r2d(mouse.y*2.);
    //float ps = floor(p.y*0.15-2.5)*0.3;
    float ps = 0.9;
    vec3 p1 = p;
    float t = time2;
    float sc = 3.;
    float wl = 0.3;
    p1.zx *= r2d(t+t);
    p1 = floor(p1*ps)/ps;
    //p1.z -= 2.;
    p1.zx *= r2d(p1.y*wl-t);
    p1.xy += sc;
    //p1 = floor(p1*ps)/ps;
    vec3 p2 = p;
    p2.zx *= r2d(t+t);
    p2 = floor(p2*ps)/ps;
    //p2.z -= 0.9;
    p2.zx *= r2d(p2.y*wl-t+3.);
    p2.xy += sc;
    //p1.yx *= r2d(time2*0.01);
    float s = 0.1294+(p.y*p.y*p.y+500.)*0.001;
    //float s = 0.1294;
    //p1 = floor(p1*0.5)*0.09;
    //p1.xz = fract(p1.xz);
    float d = length(p1.xz)-s;
    float d2 = length(p2.xz)-s;
    d = min(d,d2);
    if (d2 > d) {
        id += 0.3;
        //d *= 02.9;
    }
    d = min(d,p.y+8.);
    if (p.y+7.99 < d) {
        float cs = 2.;
        vec2 fp = p.xz*0.02;
        fp.xy *= r2d(p1.y*1.-time2+3.);
        fp = floor(fp.xy*cs)/cs;
        //fp.xy *= r2d(p1.y*1.+time2*0.1);
        id = (mod(fp.x + mod(fp.y, 2.0), 2.0));
        //if (id < 0.) {
        //    id = 0.;
        //}
        //id = floor(id);
        //id = 0.3;
        if (d < 0.) {
            d = 40.0;
        }
        //d = abs(d);
    }
    //if (d < 0.) {
    //        d = -20.;
    //    }
    return vec2(d,id);
}

vec2 RM (vec3 ro, vec3 rd) {
    float dO = 0.;
    float ii = 0.;
    for (int i=0;i<200;i++) {
        vec3 p = ro+rd*dO;
        float dS = getDist(p).x;
        dO += dS*0.3;
        ii += 0.01;
        if (dS < 0.01 || dO > 1000.) {
            break;
        }
    }
    return vec2(dO,ii);
}

vec3 mainKL(vec2 uv)
{
    //vec2 uv = -1. + 2. * inData.v_texcoord;
    //vec2 tv = inData.v_texcoord;
    vec2 tv = uv;
    vec3 col = vec3(0.);
    uv.x *= resolution.x/resolution.y;
    float c = length(uv);
    //uv *= 0.5;
    float t = time2*0.1;
    vec3 ro = vec3(0,-2,-0.);
    ro.z += time2*30.;
    //ro.z += mouse*resolution.xy.x*0.5;
    //ro += mouse.y*20.;
    vec3 rd = normalize(vec3(uv,0.8));
    //rd.zx *= r2d(-mouse.x*20.);
    rd.zy *= r2d(1.9);
    rd.zx *= r2d(tv.x+t*5.);
    //rd.zy *= r2d(2.5);
    vec2 d = RM(ro,rd);
    vec3 p2 = rd*d.x;
    vec3 p = ro+rd*d.x;
    col = vec3(d.x/100.);
    float ci = getDist(p).y;
    //col = hsv2rgb(vec3(ci,1.,(d.y)+(d.x*0.001)));
    col = hsv2rgb(vec3(ci,1.,1.));
    if (d.x > 999.) {
        col *= 0.8;
    }
    //d.y += -ci*2.;
    col += ((d.y*0.9)/(d.x*0.01)-1.)*0.2+d.y*0.2;
    vec3 cf = fwidth(col);
    col -= cf;
    //col = (1.-col)+cf;
    //col = 1.-cf;
    //cf = fwidth(col);
    //col = cf-col;
    col -= vec3(d.x*0.05)*cf;
    col = mix(col,vec3(0.),clamp(d.x*0.003,0.,1.));
    return col;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = mainKL(uv-0.5);
    glFragColor = vec4(col,1.0);
}
