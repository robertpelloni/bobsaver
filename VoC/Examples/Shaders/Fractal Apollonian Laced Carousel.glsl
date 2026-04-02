#version 420

// original https://www.shadertoy.com/view/ttSczw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// APOLLONIAN NET FRACTAL
//
// shader inspiration and help
// https://www.shadertoy.com/view/llG3Dt @Gijs
// https://www.shadertoy.com/view/Xtlyzl @GregRostami / @Fabrice
//
// also 
// @iq percise normal, hsl & ao + @shane
//
// VR ready - decent on a rift-s / PC

#define MAX_DIST     55.
#define MAX_STEPS     186

#define PI          3.1415926
#define R             resolution
#define T            time

#define r2(a)  mat2(cos(a), sin(a), -sin(a), cos(a))

float isvr = 0.;

vec3 get_mouse( vec3 ro ) {
    float x = -.05;
    float y = 0.;
    ro.zy *= r2(x);
    ro.zx *= r2(y);
    return ro;
}
 
vec2 dom (vec2 p) {
    float size = .5, hlf = size/2.;
     return mod(p+hlf,size)-hlf;
}

vec3 apollo (vec3 p) {
    float scale = 1.25;
    vec3 q = p;
    float orb =10000.;
    float ph = .7 + ( .6 + .6 * cos(time*.08) );
    ph = clamp(ph,.9,1.4);
    for( int i=0; i<5;i++ ) {
        p = -1.+2.*fract(.5*p+.5);
        float r2 = dot(p,p);  
        float k = ph/r2;
        p *= k;
        scale *= k;
        orb = min( orb, r2);
    }
    
    float thx = .01;
    float tubes = length(dom(p.xz))-thx;
    tubes =   min(length(dom(p.xy))-thx,tubes);
    tubes =   min(length(dom(p.zy))-thx,tubes);
    float d = max(abs(p.y),tubes)/scale;
    float adr = 0.7*floor((0.5*p.y+0.5)*8.0);

    return vec3(d*.4,adr, orb);
}

vec3 map (in vec3 p) {
    p=get_mouse(p);
    if(isvr==0.) p.xz*=r2(time*.02);
    p+=vec3(0.,.25,0.);

    vec3 d = apollo(p);
    return d;
}

//@iq percise normal
vec3 get_normal(in vec3 pos, in float t) {
    float pre = 0.0001 * t * 0.95;
    vec2 e = vec2(1.0,-1.0)*pre;
    return normalize( 
        e.xyy*map( pos + e.xyy ).x + 
        e.yyx*map( pos + e.yyx ).x + 
        e.yxy*map( pos + e.yxy ).x + 
        e.xxx*map( pos + e.xxx ).x );
}

vec3 ray_march( in vec3 ro, in vec3 rd ) {
    float t = 0.01;
    vec2  data = vec2(0.);
    for( int i=0; i<MAX_STEPS; i++ ) {
        float surface = 0.0008*t;
        vec3  r = map(ro + rd * t);
        float h = r.x;
        data = r.yz;
        if(abs(h)<surface || t>MAX_DIST) break;
        t += h;
    }

    if( t>MAX_DIST ) t=-1.0;
    return vec3( t, data );
}

float get_diff(vec3 p, vec3 lpos, vec3 n) {
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),0. , 1.);
    vec3 shadow = ray_march(p + n * 0.0005 * 2., l);
    if(shadow.x < length(p -  lpos)) dif *= .3;
    return dif;
}

float get_ao(vec3 p, vec3 n){ //@iq & @shane - i like your ao <3
    float r = 0., w = 1., d;
    for (float i=1.; i<3.+1.1; i++){
        d = i/5.;
        r += w*(d - map(p + n*d).x);
        w *= .5;
    }
    return 1.-clamp(r,.0,1.);
}

vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 color = vec3(0.);
    vec3 fadeColor = hsv2rgb(vec3(.32,.3,.45));
    vec3 ray = ray_march(ro, rd);
    
    if(ray.x<MAX_DIST) {
        vec3 p = ro + ray.x * rd;
        vec3 n = get_normal(p, ray.x);
        // lighting and shade
        vec3 lpos1 = vec3(.25, .15, .05);
        vec3 lpos2 = vec3(-.15, .75, .75);
        vec3 diff = vec3(3.75)*get_diff(p, lpos1, n) + vec3(3.25)*get_diff(p, lpos2, n);
        // spec
        vec3 h = normalize(-rd + lpos1);
        float spe = pow(clamp(dot(h, n), 0., 1.), 32.0);
          float ao = get_ao(p,n);
        // color
        float hue = .35 + (ray.y *.18) + (ray.z*.5)+(ray.x*.03);
        vec3 tint =hsv2rgb(vec3(hue,.7,.45))*2.;
        //mixdown
        color +=  tint * diff * ao * (spe+.15);
    } else {
        color = fadeColor;   
    }
    //change fog on zoom switch
    float fd = .21 ;
    color = mix( color, fadeColor, 1.-exp(-fd*ray.x*ray.x*ray.x));
    return color;
}

vec3 ray( in vec3 ro, in vec3 lp, in vec2 uv ) {
    vec3 cf = normalize(lp-ro);
    vec3 cp = vec3(0.,1.,0.);
    vec3 cr = normalize(cross(cp, cf));
    vec3 cu = normalize(cross(cf, cr));
    vec3 c = ro + cf * .85;
    
    vec3 i = c + uv.x * cr + uv.y * cu;
    return i-ro; 
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    float zoom = .6;
    vec3 ro = vec3(0.,0.1,zoom);
    vec3 lp = vec3(0.,0.,0.);

    vec3 rd = ray(ro, lp, uv);
    
    vec3 col = render(ro, rd, uv);
    col= pow(col, vec3(0.4545));
    glFragColor = vec4(col,1.0);
}
    
