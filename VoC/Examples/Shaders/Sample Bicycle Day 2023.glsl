#version 420

// original https://www.shadertoy.com/view/mlt3z8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define pi acos(-1.)
#define deg pi/180.
#define time time*pi/10.

mat2 r2d(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

#define cs vec3(1.,2.,3)
#define R resolution.xy

vec3 rgb2hsv(vec3 c){vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));float d = q.x - min(q.w, q.y);float e = 1.0e-10;return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);}vec3 hsv2rgb(vec3 c){vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);}float bitm(vec2 uv,int c) {float h = 5.;float w = 3.;int p = int(pow(2.,w));float line1 = 9591.;uv = floor(vec2(uv.x*w,uv.y*h))/vec2(w,w);float c1 = 0.;float cc = uv.x + uv.y*w;c1 = mod( floor( float(c) / exp2(ceil(cc*w-0.6))) ,2.);c1 *= step(0.,uv.x)*step(0.,uv.y);c1 *= step(0.,(-uv.x+0.99))*step(0.,(-uv.y+1.6));return (c1);}vec3 slogo(vec2 uv, float ar, float size) {size = 240./size;uv.x = 1.-uv.x;vec2 px = vec2(1./3.,1./5.);float ls = 4.1;uv *= 240./5.25/size;ls += 2.;float ul = length(uv);ul = length(vec2(uv.x*0.5,uv.y)-0.5);uv -= 0.4;uv.x *= ar*1.75;uv.y *= 1.04;int s = 29671;int c = 29263;int r = 31469;int y = 23186;uv.x= 5.-uv.x;float b = bitm(uv,s);uv.x -= 1./3.*4.;b += bitm(uv,c);uv.x -= 1./3.*4.;b += bitm(uv,r);uv.x -= 1./3.*4.;b += bitm(uv,y);float rr = step(0.,uv.x+px.x*13.)*step(0.,uv.y+px.y)*step(0.,(-uv.x+px.x*4.))*step(0.,(-uv.y+px.y*6.));b = clamp(b,0.,1.);vec3 l = hsv2rgb(vec3(b+time/40.,0.1,rr-b*1.9))*rr;l -= 0.1-clamp(ul*0.1,rr*1.-b,0.1);return vec3(l);}

float smin( float a, float b, float k )
{
    float h = a-b;
    return 0.5*( (a+b) - sqrt(h*h+k) );
}

vec3 cpos() {
    vec3 c = vec3(0.);
    c.z -= 5.;
    c.y += 2.;
    c.x += 4.;
    c.z += sin(time*4.)*0.4;
    c.x += cos(time*2.-pi/2.)*0.6;
    c.y += cos(time*4.)*0.45;
    //if (mouse*resolution.xy.z > 0.) {
    //    c.xz *= r2d(-(mouse*resolution.xy.x/R.x)*pi*2.);
    //    c.y += (mouse*resolution.xy.y/R.y)*12.;
    //    c.y -= 4.;
    //}
    //c.yz *= r2d(-(mouse*resolution.xy.y/R.y)*pi);
    return c;
}

mat4 v() {
    vec3 c = cpos();
    vec3 l = c*0.;
    vec3 f = normalize(l-c);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 u = cross(f,r);
    return mat4(r,0,u,0,f,0,vec3(0.),1.);
}

float sdCyl(vec3 p, vec2 s) {
    return max(length(p.xz)-s.x,abs(p.y)-s.y);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}
float sdVCap( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRhombus(vec3 p, float la, float lb, float h, float ra)
{
  p = abs(p);
  vec2 b = vec2(la,lb);
  float f = clamp( (ndot(b,b-2.0*p.xz))/dot(b,b), -1.0, 1.0 );
  vec2 q = vec2(length(p.xz-0.5*b*vec2(1.0-f,1.0+f))*sign(p.x*b.y+p.z*b.x-b.x*b.y)-ra, p.y-h);
  return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}

float bikeframe(vec3 p) {
    vec3 o = p;
    float th = 0.015;
    float mk = 0.0002;
    float d = sdVCap(p.yxz+vec3(-0.9,0.7,0.),1.58,th);
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*20.),p.z)+vec3(0.4,0.45,0.),1.54,th),mk);
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*-43.),p.z)+vec3(-0.2,0.5,0.),1.65,th),mk);
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*20.),p.z)+vec3(-1.15,-0.2,0.),0.7,th),mk);
    vec2 fb = p.xy*r2d(deg*20.);
    p.z = abs(p.z)-(0.-(fb.x)*1.)*0.1;
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*-30.),p.z)+vec3(1.1,1.,0.),1.4,th),mk);
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*-100.),p.z)+vec3(-0.6,1.34,0.),1.2,th),mk);
    p = o;
    d = smin(d,sdCappedTorus(vec3(p.z,p.yx*r2d(deg*-20.))+vec3(0.,-0.1,-1.15),vec2(1.,0.),0.07,0.02),mk);
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*20.),abs(p.z)-0.07)+vec3(-1.15,0.9,0.),1.,th),mk);
    //p.z = abs(p.z)-(0.2-fb.y)*0.1;
    //d = smin(d,sdVCap(vec3(p.xy*r2d(deg*20.),p.z)+vec3(-1.15,0.4,0.),0.7,th),mk);
    return d;
}

float wheels(vec3 p) {
    vec3 o = p;
    p.x = abs(p.x)-1.45;
    p.y += 0.38;
    float d = sdTorus(p.xzy,vec2(0.9,0.01));
    d = min(d,length(p)-0.01);
    p.xy = vec2(length(p.xy),atan(p.x,p.y));
    p.y /= pi;
    float sc = 16.;
    p.y = (fract(p.y*sc+time/pi*30.*(step(o.x,0.)-0.5)*2.)-sc*1.54)/sc;
    p.y *= pi;
    p.xy = vec2(p.x*sin(p.y),p.x*cos(p.y));
    d = min(d,sdVCap(p.yxz,0.9,0.01));
    return d;
}

float handlebars(vec3 p) {
    vec3 o = p;
    p.z = abs(p.z)-0.6;
    float th = 0.015;
    float mk = 0.0002;
    float d = (sdVCap(vec3(p.yx,p.z)+vec3(-1.3,-0.75,0.),0.2,th));
    d = smin(d,sdCappedTorus(vec3(p.yx,p.z)+vec3(-1.4,-0.98,0.),vec2(1.,0.),0.1,0.02),mk);
    d = smin(d,sdVCap(vec3(p.yx,p.z)+vec3(-1.5,-0.68,0.),0.24,th*2.),mk);
    d = smin(d,sdVCap(vec3(p.x,-p.z,p.y)+vec3(-0.72,-0.,-1.28),01.24,th*2.),mk);
    return d;
}

float seat(vec3 p) {
    vec3 o = p;
    float s = 0.9;
    p /= s;
    p += vec3(0.8,-1.4,0.);
    float d = smin(sdRhombus(p.zyx, 0.1, 0.3, 0.01, 0.1),sdRhombus(p+vec3(0.2,0.,0.), 0.1, 0.15, 0.01, 0.2)-0.01,0.002);
    d *= s;
    p /= s;
    p.y += 0.04;
    d = min(d,smin(sdRhombus(p.zyx, 0.1, 0.3, 0.01, 0.1),sdRhombus(p+vec3(0.2,0.,0.), 0.1, 0.15, 0.01, 0.2),0.002)*s);
    p = o;
    float th = 0.01;
    float mk = 0.;
    float sl = 0.64;
    d = smin(d,sdVCap(vec3(p.xy*r2d(deg*20.),p.z)+vec3(0.4,-1.1+sl/2.,0.),sl,th),mk);
    return d;
}

float pedals(vec3 p) {
    float th = 0.02;
    float s = 0.6;
    float s2 = 0.1;
    float mk = 0.0002;
    vec3 o = p;
    float ps = 4.;
    p += vec3(0.2,0.5,0.);
    p.xy *= r2d(time*-ps);
    float d = (sdVCap(vec3(p.xz,p.y)+vec3(0.,s/4.,0.),s/2.,th));
    d = smin(d,sdVCap(vec3(p.yx,p.z)+vec3(0.,0.,s/4.),s2,th),mk);
    d = smin(d,sdVCap(vec3(p.yx,p.z)+vec3(0.,s2,-s/4.),s2,th),mk);
    vec3 p1 = vec3(-s2,0.,s/2.);
    vec3 p2 = vec3(s2,0.,-s/2.);
    p1 = p+p1;
    p2 = p+p2;
    
    p1.yx *= r2d(time*-ps);
    p2.xy *= r2d(time*ps);
    //vec3 p1 = vec3(p.yx,p.z)+vec3(0.,0.,s/2.);
    //vec3 p2 = vec3(p.yx,p.z)+vec3(0.,s2,-s/2.);
    s2 *= 1.4;
    //d = smin(d,sdBox(p1,vec3(s2*1.2,th,s2),0.),mk);
    //d = smin(d,sdBox(p2,vec3(s2*1.2,th,s2),0.),mk);
    d = smin(d,sdBoxFrame(p1,vec3(s2*1.2,th,s2),0.),mk);
    d = smin(d,sdBoxFrame(p2,vec3(s2*1.2,th,s2),0.),mk);
    d = smin(d,sdBoxFrame(p1,vec3(s2*.5,th,s2),0.),mk);
    d = smin(d,sdBoxFrame(p2,vec3(s2*.5,th,s2),0.),mk);
    return d;
}

vec4 map(vec3 p, float rt) {
    vec3 o = p;
    p = (v()*vec4(p,1.)).xyz+cpos();
    //p.xz *= r2d(deg*-75.+time*2.+rt);
    //float d = sdCyl(p,vec2(0.1,0.5));
    p.x += .5;
    float d = bikeframe(p);
    d = min(d,wheels(p));
    d = min(d,handlebars(p));
    d = min(d,seat(p));
    d = min(d,pedals(p));
    p.y += 1.4;
    float px = floor(p.x+time/pi*5.);
    p.x = fract(p.x+time/pi*5.)-0.5;
    px = fract(px/5.)-0.5;
    px = abs(px);
    d = min(d,sdBoxFrame(p,vec3(0.5,0.1,0.4+px),0.));
    return vec4(p,d);
}

vec3 calcNorm(vec3 p, float rt) {
    vec2 h = vec2(0.001,0.);
    return normalize(vec3(
        map(p-h.yyx,rt).w-map(p+h.yyx,rt).w,
        map(p-h.yxy,rt).w-map(p+h.yxy,rt).w,
        map(p-h.xyy,rt).w-map(p+h.xyy,rt).w
    ));
}

vec2 RM(vec3 ro, vec3 rd, float rt) {
    float dx = 0.;
    float ii = 0.;
    for (int i=0;i<70;i++) {
        vec3 p = ro+rd*dx;
        float dS = map(p,rt).w;
        dx += dS/5.;
        ii += 0.01/5.;
        if (dx > 20. || dS < 0.015) {break;}
    }
    return vec2(dx,ii);
}

vec3 colo(vec3 p, vec3 n, vec3 ro, vec3 rd, vec2 d, float rt) {
    vec3 col = vec3(0.);
    float ebg = exp(-0.05*d.x);
    //col += d.x/20.;
    vec3 bg = vec3(0.);
    float mrd = max(atan(rd.x-d.x,rd.y),atan(rd.x+d.x,rd.y));
    col += n;
    col = (col*ebg)+(bg*(1.-ebg));
    col = clamp(col,0.,1.);
    col += sin(cs+d.y*20.+time*4.+(rt)*pi/20.+atan(rd.x,rd.y)*0.+mrd*120.);
    col -= floor(col)*0.1;
    
    col = sin(atan(rd.x-d.y,rd.y)*20.+atan(rd.x+d.y,rd.y)*20.+cs)*0.3+col*0.7;
    col += sin(cs+d.y*80.+time*4.)*0.1+0.2;
    vec3 acol = col;
    col -= 0.34;
    col *= 1.;
    col = floor(col*4.)/5.;
    col = mix(col,acol,sin(length(rd.xy)*50.+time*-10.)*0.2+0.8);
    return col;
}

vec3 frm(vec2 uv, float rt) {
    vec3 col = vec3(0.);
    float r = 10./4.;
    uv = fract(uv)-0.5;
    //uv = (fract(uv*r)-0.5);
    vec3 ro = vec3(0.);
    vec3 rd = normalize(vec3(uv,1.4));
    vec2 d = RM(ro,rd,rt);
    vec3 p = ro+rd*d.x;
    vec3 n = calcNorm(p,rt);
    col += colo(p,n,ro,rd,d,rt);
    col = clamp(col,0.,1.);
    return col;
}

vec3 tabs(vec2 uv) {
    vec3 col = vec3(0.);
    uv *= 1.1;
    uv += 0.5;
    
    vec2 ov = uv;
    float r = 1.;
    //uv.y = log(uv.y+0.5);
    if (abs(uv.x) > 0.4) {
        
        //uv *= r2d(sin(time*2.)*deg*90.);
        //uv.y = abs(uv.y);
        //uv *= r2d(-time);
        //uv.x += time/10.+floor(uv.y*r-0.)/5.5;
    }
    uv.y += sin(time*2.+uv.x*25.)*0.005;
    uv.x += cos(time*2.+uv.y*24.)*0.005;
    //uv.y += time/pi/10.*5.;
    vec2 cv = uv;
    uv = (fract(uv*r-0.5)-0.5)/r;
    //col += sin(atan(uv.x,uv.y)+cs);
    vec2 dv = uv;
    float dr = 600./pi;
    dv = (fract(dv*dr-0.5)-0.5)/dr;
    vec3 pc = sin(atan(dv.x,dv.y)+cs+time*20.+ov.y*100.+ov.x*40.);
    float perf = smoothstep(0.001,0.,min(abs(uv.x),abs(uv.y))-0.001)*(sin(uv.x*600.+uv.y*600.)*0.5+0.5);
    col += perf*pc;
    //col += frm(cv*5.,0.);
    col += frm(fract(cv*r),abs(abs(floor(cv.x*r))-1.)+floor(cv.y*r)*pi*2.);
    //col += frm(fract(cv*r),floor(cv.x*10.)+floor(cv.y*10.));
    //col += sin(abs(uv.x*20.)*10.+cs+sin(abs(uv.y)*20.)*10.)*0.7;
    //col -= sin(perf*1.+4.+sin(ov.y)*20.)*perf;
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float ar = R.x/R.y;
    vec2 tv = uv;
    uv -= 0.5;
    uv.x *= ar;
    //uv *= 0.4;
    vec3 col = vec3(0.);
    float br = 582./388.;
    vec2 brv = vec2(tv.x,1.-tv.y);
    brv -= 0.5;
    brv.x /= br;
    brv *= 1.5;
    brv += 0.5;
    vec3 bikeref = vec3(0.0); //texture(iChannel0,brv).xyz;
    vec3 t = tabs(uv);
    //col = frm(uv);
    col = t;
    col = clamp(col,0.,1.);
    col *= smoothstep(0.08,0.,max(abs(uv.x),abs(uv.y))-0.4);
    //col = mix(col,bikeref,0.2);
    tv.x -= 0.2;
    tv.x *= ar;
    
    col += slogo(tv,1.,300./1.)*(sin(vec3(cs*0.6+tv.x*20.))*0.4+0.6)*0.5;
    glFragColor = vec4(col,1.0);
}