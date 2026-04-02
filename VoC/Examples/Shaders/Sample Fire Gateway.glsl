#version 420

// original https://www.shadertoy.com/view/slSXRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAXD 100.
#define SURF 0.01

mat2 r2d(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

// All components are in the range [0…1], including hue.
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
//Taken from http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl.

//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

vec4 map(vec3 p) {
    
    //float d = 
    float pd = 0.1;
    float psz = floor(p.z);
    p.xy *= r2d(psz+psz*09.5);
    vec3 o = p;
    p -= 5.;
    p = (fract(p*pd)-0.5)/pd;
    p = abs(p)-1.0;
    //*/
    for (int i=0;i<4;i++) {
        //
        p.xy = vec2(length(p.xy),atan(p.x,p.y));
        p.xy = abs(p.xy)+0.3;
        p.xy *= r2d(0.3);
        p.xy = vec2(p.x*sin(p.y),p.x*cos(p.y));
        p = abs(p)-sin(o.z*0.06+time*0.01)*2.;
        p.xy *= r2d(o.z*0.02);
    }
    //float d = length(p)+0.1;
    
    float an = 3.14*0.75;
    float d = sdCappedTorus(p,vec2(sin(an),cos(an)),1.,0.)+0.0;
    d = max(d,-(length(o.xy)-0.4));
    return vec4(p.xy,o.z,d);
}

vec2 RM(vec3 ro, vec3 rd,float c) {
    float dO = 0.;
    float ii = 0.;
    int steps = 60-int(c*20.);
    for (int i=0;i<steps;i++) {
        vec3 p = ro+rd*dO;
        float dS = map(p).w;
        dO += dS*0.2;
        ii += 0.1;
        if (dO > MAXD || dS < SURF) {break;}
    }
    return vec2(dO,ii);
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = 1.- 2.*uv;
    // Output to screen
    //glFragColor = vec4(col,1.0);
    //vec2 uv = -1. + 2. * inData.v_texcoord;
    vec2 R = resolution.xy;
    float ar = R.x/R.y;
    uv.x *= ar;
    vec3 col = vec3(0.);
    //uv *= 0.1;
    float c = length(uv);
    //uv *= r2d(sin(c*8.+time)*0.01);
    vec3 ro = vec3(0.,0.,-5.);
    ro.z += time*0.6;
    vec3 rd = normalize(vec3(uv,1.));
    vec2 d = RM(ro,rd,c);
    //col = d.xxx*0.006;
    vec3 p=map(ro+rd*d.x).rgb;
    //col = sin(d.xxx*0.8+time)*0.5+0.5;
    //col = d.xxx*0.001;
    //col += 1.-d.xxx*0.007;
    //col.r -= d.y;
    //col = sin(d.yyy);
    //col = sin(p.zzz*0.02)*0.5+0.5;
    float pzn = p.z-ro.z;
    //d.x = clamp(d.x*0.05,0.,1.);
    col = hsv2rgb(vec3(p.y*0.04+p.z*0.004+d.x*0.01-0.05,1.-d.y*0.03,sin(p.z*0.2-ro.z*0.12)*0.6+0.4));
    //col = hsv2rgb(vec3(p.z*0.05,sin(p.x*0.002-c*4)*0.5+0.5,sin(d.x*0.1-ro.z*0+c)*0.5+0.5));
    //vec3 bak = texture(prevFrame,inData.v_texcoord).rgb;
    if (d.x > MAXD+(c+0.5)) {
        col *= 0.;
    }
    //col = fract(col*1.5+time*0.04);
    //col = sin(col*6.);
    //bak = fract(bak+col*0.01);
    //col = mix(col,bak,0.93);
    //col = hsv2rgb(vec3(d.x*0.009,d.x*0.005,d.x*0.1));
    //col = hsv2rgb(vec3(d.x*0.0025,0.6,d.y*4.-19.5));
    glFragColor = vec4(col,1.);
}

    
