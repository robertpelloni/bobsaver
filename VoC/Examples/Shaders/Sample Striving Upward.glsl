#version 420

// original https://www.shadertoy.com/view/dllyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi acos(-1.)
#define deg pi/180.
#define time time*pi/10.
#define R resolution.xy
#define ar R.x/R.y
vec3 cs = vec3(1.,2.,3.);
mat2 r2d(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}
vec3 rgb2hsv(vec3 c){vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));float d = q.x - min(q.w, q.y);float e = 1.0e-10;return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);}vec3 hsv2rgb(vec3 c){vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);}float bitm(vec2 uv,int c) {float h = 5.;float w = 3.;int p = int(pow(2.,w));float line1 = 9591.;uv = floor(vec2(uv.x*w,uv.y*h))/vec2(w,w);float c1 = 0.;float cc = uv.x + uv.y*w;c1 = mod( floor( float(c) / exp2(ceil(cc*w-0.6))) ,2.);c1 *= step(0.,uv.x)*step(0.,uv.y);c1 *= step(0.,(-uv.x+0.99))*step(0.,(-uv.y+1.6));return (c1);}vec3 slogo(vec2 uv, float ar_, float size) {size = 240./size;uv.x = 1.-uv.x;vec2 px = vec2(1./3.,1./5.);float ls = 4.1;uv *= 240./5.25/size;ls += 2.;float ul = length(uv);ul = length(vec2(uv.x*0.5,uv.y)-0.5);uv -= 0.4;uv.x *= ar*1.75;uv.y *= 1.04;int s = 29671;int c = 29263;int r = 31469;int y = 23186;uv.x= 5.-uv.x;float b = bitm(uv,s);uv.x -= 1./3.*4.;b += bitm(uv,c);uv.x -= 1./3.*4.;b += bitm(uv,r);uv.x -= 1./3.*4.;b += bitm(uv,y);float rr = step(0.,uv.x+px.x*13.)*step(0.,uv.y+px.y)*step(0.,(-uv.x+px.x*4.))*step(0.,(-uv.y+px.y*6.));b = clamp(b,0.,1.);vec3 l = hsv2rgb(vec3(b+time/40.,0.1,rr-b*1.9))*rr;l -= 0.1-clamp(ul*0.1,rr*1.-b,0.1);return vec3(l);}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 tv = uv;
    vec3 col = vec3(0.);
    uv -= 0.5;
    uv.x *= ar;
    vec2 ov = uv;
    //uv = log(abs(uv))/sin(length(uv)/pi+time/8.)*0.4+time;
    uv = vec2((length(uv)),atan(uv.x,uv.y));
    vec2 cv = uv;
    uv.x = log(uv.x);
    //uv *= r2d(deg*45.);
    //uv *= r2d(deg*45.)*2.;
    //uv.x += sin(time*8.+uv.y*2.)/100;
    //uv.x += sin(time*2.+uv.y*2.)/4.;
    uv /= pi;
    uv *= 8.;
    uv.x += time*-1.;
    //uv.y = abs(uv.y);
    uv.x -= time/4.;
    col += smoothstep(0.9,0.,length(ov))*(sin(atan(ov.x,ov.y)+cs+log(cv.x)*2.)*0.2+0.8);
    col -= smoothstep(0.5,0.,length(ov))*1.2;
    //uv *= 0.1;
    //uv *= r2d(deg*45.)*2.;
    //uv.x += sin(time)*8.;
    vec2 uv1 = uv;
    float s = 0.5+floor(sin(uv.x*4.*sin(uv.x*0.4*sin(uv.x*0.02+time*0.1)*0.002))*8.);
    s = 10.;
    vec2 f1 = floor(uv*s-0.5);
    vec2 f2 = floor(uv*s);
    uv = (fract(uv*s-0.5)-0.5)/10.;
    uv1 = (fract(uv1*s)-0.5)/10.;
    //uv += vec2(sin(time+f1.x),cos(time+f1.y))*0.01;
    //uv1 += vec2(cos(time+f2.y),sin(time+f2.x))*0.01;
    float bl = smoothstep(0.,0.7,cv.x+0.15);
    float lv1 = (cos(f1.x/4.+f1.y*4.+time*2.)*0.5+0.5)*0.00;
    float lv2 = (sin(f2.y/4.+f2.x*4.+time*2.)*0.5+0.5)*0.00;
    float cv1 = sin(f1.y*9.)*sin(f1.x*8.)*2.;
    float cv2 = cos(f2.y*9.)*cos(f2.x*9.)*2.;
    col += smoothstep(0.01,0.,abs(length(uv)-0.02+cv1*0.01)-0.00)*(sin(time*8.+cv1+cs+atan(uv.x,uv.y)))*bl*0.98;
    col += smoothstep(0.01,0.,abs(length(uv1)-0.02+cv2*0.01)-0.00)*(sin(time*8.+cv2+cs+atan(uv1.x,uv1.y)))*bl*0.98;
    
    float os = sin(cv.y*8.*sin(cv.y*1.*sin(cv.y*2.+3.+time*0.25)+time*0.5))+sin(sin(cv.y*90.)*sin(cv.y*88.)+cv.x*63.+time*5.)*0.4;
    col += clamp(((sin(os+cv.y*2.-cv.x*10.)*0.7+0.5)*0.9+smoothstep(.4,0.,cv.x)*2.)*smoothstep(0.25,0.,cv.x)+smoothstep(0.1,0.,cv.x),0.,3.)*0.6;
    col = clamp(col, 0., 1.);
    col += slogo(tv,1.,300./0.5)*(sin(vec3(cs*0.6+tv.x*20.))*0.4+0.6)*0.35;
    glFragColor = vec4(col,1.0);
}
