#version 420

// original https://www.shadertoy.com/view/Wd2BDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// OMG I made something glow - thanks to 
// https://www.shadertoy.com/view/3ltGD7 for 
// helping me get attenuation a bit..
// I feel I need to learn structs to
// start getting into some real marching demos. 

#define MAX_DIST      75.
#define MIN_DIST     .001

#define PI          3.1415926
#define PI2         6.2831853

// common stuff and sdf's thanks to @iq
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm

mat2 r2( float a ) { 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}

float tube( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float pry( in vec3 p, float s ) {
  p.xz*=r2(45.*PI/180.);
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float box( vec3 p, vec3 b ) {
      vec3 d = abs(p) - b;
      return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

vec3 get_mouse( vec3 ro ) {
    float x = .1;
    float y = .0;
    if(x>-.1)x=-.1;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}

vec2 map(in vec3 pos) {
    pos.xz*=r2(time*.05);
    float size = 20.;
    float hlf = size/2.;
    
     vec2 res = vec2(1.,0.);
      vec3 p = pos-vec3(0., 0., 0.);
    vec3 r = p;
    
    vec3 id = vec3(
        floor((p + hlf)/size)
    );
    
    vec3 q = vec3(
        mod(p.x+hlf,size)-hlf,
        p.y,
        mod(p.z+hlf,size)-hlf
    );

    float wd = 5. + 6. * cos(time*.75);

    float sphere = length(r-vec3(0.,0.+wd,0))-2.75;
    if(sphere<res.x) res = vec2(sphere,3.);
    
    float y = distance(id.xz,vec2(.0));
       float base = box(q-vec3(0.,0.+y,0.),vec3(4.,1.5,4.));
    base = min(box(q-vec3(0.,-58.25+y,0.),vec3(5.5,59.,5.5)),base);
    base = min(box(q-vec3(0.,-59.+y,0.),vec3(7.,59.,7.)),base); 
        
    float prymid = pry(abs(q)-vec3(4.65,.75+y,4.65),.75);
    prymid = min(pry(abs(q)-vec3(6.15,0.+y,6.15),.75),prymid);
    if(prymid<res.x)res = vec2(prymid,2.);
    
    q=vec3(abs(r.x),r.y,abs(r.z));
    float hole = tube(r-vec3(0,-1.,0.),3.5,55.);

    float boxframe = box(q-vec3(8.,-2.,0.),vec3(25.,1.,1.6));
    float boxclip = box(q-vec3(0.,-2.,8.),vec3(1.6,1.,25.));
    boxframe = min(boxclip,boxframe);
    base = min(boxframe,base);
    base = max(base,-hole);
    if(base<res.x)res = vec2(base,1.);
   
    float ps = 3.;
    float rbase = tube(r-vec3(0.,7.,0.),4.5,.1);
    rbase = min(tube(r-vec3(0.,6.,0.),4.5,.1),rbase);
    rbase = min(tube(r-vec3(0.,5.,0.),4.5,.1),rbase);
    rbase = max(rbase,-hole);
    if(rbase<res.x)res = vec2(rbase,4.);
        
    float dbase = tube(q-vec3(ps,3.,ps),.25,4.25);
    if(dbase<res.x)res = vec2(dbase,5.);
    float gbase = tube(q-vec3(ps,2.25,ps),.45,.75);
    if(gbase<res.x)res = vec2(gbase,6.);

      return res;
}

vec3 get_normal(in vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(.01,.0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
    );
    return normalize(n);
}

float size = 3.15;

vec2 get_volume( in vec3 ro, in vec3 rd , in vec3 lp) {
    float depth = 0.;
    float decay = 1.;
    float atm = 0.;
    for (int i = 0; i<175;i++) {
        vec3 pos = ro + depth * rd;
        vec2 dist = map(pos);
        atm += (dist.x) * decay / pow(length(pos - lp), size);
        decay *= 1.01;
        if(dist.x<MIN_DIST) break;
          depth += dist.x*.75;
        if(depth>MAX_DIST) break;
    }
    return vec2(atm,decay);
}

vec2 get_march( in vec3 ro, in vec3 rd) {
    float mat = 0.;
    float depth = 0.;
    for (int i = 0; i<150;i++)
    {
         vec3 pos = ro + depth * rd;
        vec2 dist = map(pos);
        mat = dist.y;
        if(dist.x<MIN_DIST*depth) break;
        depth += dist.x*.75; 
        if(depth>MAX_DIST) break;
    }
    return vec2(depth,mat);
}

float get_light(vec3 p, vec3 lpos) {
    vec3 l = normalize(lpos-p);
    vec3 n = get_normal(p);
    float dif = clamp(dot(n,l),0. , 1.);
    
    float shadow = get_march(p + n * MIN_DIST * 2., l).x;
    if(shadow < length(p -  lpos)) dif *= .5;
 
    return dif;
}

vec3 get_color(float m) {
    vec3 tint = vec3(0.);
    if(m==1.) tint = vec3(.19,.15,.2);
    if(m==2.) tint = vec3(.0,.3,.9);
    if(m==3.) tint = vec3(.0,.3,.6);
    if(m==4.) tint = vec3(.0,.6,.1);
    if(m==5.) tint = vec3(.6,.5,.0);
    if(m==6.) tint = vec3(.0,.1,.6);
     return tint;   
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 color = vec3(.0);
    vec3 lc1 = vec3(0.,.2,.7);
    vec3 lc2 = vec3(0.7,.2,.0);
    
    vec3 fadeColor = vec3(.01);
    
    float speed = time *.75;
    float dist = 15.;
    vec3 lpos1 = vec3(dist*sin(speed*.95), 6.-4.*sin(time*1.75),dist*cos(speed*.95));
    vec3 lpos2 = vec3(dist*cos(speed), 7.-4.*cos(time*2.),dist*sin(speed));
    
    vec2 ray = get_march(ro, rd);
    float t = ray.x;
    
    vec2 vol = vec2(get_volume(ro, rd,lpos1).x,get_volume(ro, rd,lpos2).x);
    
    if(t<MAX_DIST) {
        vec3 p = ro + t * rd;
        vec3 tint=get_color(ray.y);
        vec3 diff  = (lc1 * get_light(p, lpos1))+(lc2 * get_light(p, lpos2));

        color += tint * diff;
        // if mat is reflect >0 and so all things..
        if(ray.y>0.) {
            vec3 rcolor = vec3(0.);
            vec3 n = get_normal(p);
            vec3 rr=reflect(rd,n);
            vec2 tm=get_march(p,rr);
            vec2 vm = vec2(get_volume(p, rr,lpos1).x,get_volume(p, rr,lpos2).x);
                if(tm.x<MAX_DIST){
                    p+=tm.x*rr;
                    rcolor = get_color(tm.y) * get_light(p, lpos1);
                }
            color += rcolor;
            color += (lc1*vm.x) + (lc2*vm.y);
        }
    } 
     // std fog stuff
    color = mix( color, fadeColor, 1.-exp(-0.00001*t*t*t));
    // add glow ontop
    color += (lc1*vol.x) + (lc2*vol.y);
    
    // correct yo gamma
    return pow(color, vec3(0.4545));
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    vec3 c = ro + cf * 1.1;
    vec3 i = c + uv.x * cr + uv.y * cu;
    return i-ro; 
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/
        max(resolution.x,resolution.y);

    float bmod = mod(time*.1,5.);
    float stnd = bmod<2.5 ? 55. : 25.;
    size = bmod<2.5 ? 2.2 : 1.9;
    vec3 lp = vec3(0.,9.,0.);
    vec3 ro = vec3(0.,11.,stnd);
    
    ro = get_mouse(ro);
    
    vec3 rd = ray(ro, lp, uv);
    vec3 color = render(ro, rd, uv);

    glFragColor = vec4(color,1.0);
}
