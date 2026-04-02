#version 420

// original https://www.shadertoy.com/view/WdsBRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Hall Of Mirrors
// -> adding my 50 cents upon mu6k and XT95 origins by
//
//
// mixing  30 torus by XT95 -> https://www.shadertoy.com/view/3dlcWl
// with    origin by mu6k -> https://www.shadertoy.com/view/XdfGzS
//

#define object_speed_modifier 1.0
#define render_steps 64
#define offset1 4.5
#define offset2 1.8
#define att 12.

// helpers
float hash1(float s) { return fract(sin(s)*42422.42); }
mat2 rot(float v) { float a = cos(v), b = sin(v); return mat2(a,b,-b,a); }
float torus(vec3 p, vec2 q) { return length( vec2(length(p.xz)-q.x,p.y) ) - q.y; } 

// global + params
float id;
vec3 glow;
vec3 sync;

float hash(float x)
{
    return fract(sin(x*.0127863)*17143.321); //decent hash for noise generation
}

float rnd(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.98,78.23))) * 43758.54);
}

vec3 rotate_y(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, +.0, -sa,
        +.0,+1.0, +.0,
        +sa, +.0, +ca);
}

vec3 rotate_x(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +1.0, +.0, +.0,
        +.0, +ca, -sa,
        +.0, +sa, +ca);
}
    

// distance function
float map( vec3 p ) {
    // rotate the world
    //p.xz *= rot(time*.05);
    //p.xy *= rot(time*.2);
    
    // small point light on the center
    float d =  length(p);
    glow += vec3(1.) / ( .1 + d*200.);
    
    float t = time*object_speed_modifier+5.0;
    p.x += t;    
    p.z += t*.4;

    float s = length(p);

    p.y  = abs(p.y);
    p.y -= 5.0;
    
    d = 0.5-p.y;
    
    for (int i=0; i<21; i++)
    {
        float fi = float(i);
        
        p+=vec3(1.25-fi,0.0,1.75+fi);
        vec3 pm;
        
        float rep = 10.0+sin(fi*2.0+1.0)*4.0 * sync.g * 0.00005;
        
        pm.xz = mod(p.xz+vec2(rep*.5),vec2(rep))-vec2(rep*.5);
        
        float width  = 1.0  + sin(fi) * .8;
        float height = 2.0  + cos(fi) * 1.2 + ( sync.b * 0.3);
        float offset = -0.5 + cos(fi) * 1.8;

        vec3 df = abs(vec3(pm.x,p.y+1.0/width,pm.z))-vec3(width,height,width);
        float box = max(max(df.x,df.y),df.z);
        

        //box= length(max(df,0.0)) + min(max(df.x,max(df.y,df.z)),0.0) - 0.095;
        
        // we accumulate the lighting here
        float intensity = 1. / ( 1. + pow(abs(box*att),1.3));
        if(i == 2 && id == 0.) {
            glow += vec3(1.,.3,1.) * intensity;
        } else if(i == 5 && id == 4.) {
              glow += vec3(0.,0.,.6) * intensity; 
        } else if(i == 7 && id == 1.) {
              glow += vec3(1.,1.,.1) * intensity;
        } else if(i == 14 && id == 2.) {
              glow += vec3(.1,1.,.1) * intensity;
        } else if(i == 17 && id == 5.) {
              glow += vec3(0.16,0.0,0.32) * intensity;            
        } else if(i == 20 && id == 3.) {
              glow += vec3(.1,1.,1.) * intensity;
        }

        d = min(d,box);
    }

    return d;    
    
    
}

vec3 getNormal(vec3 p) {
    vec3 eps=vec3(.1,0,0);
    return normalize(vec3(map(p+eps.xyy),map(p+eps.yxy),map(p+eps.yyx)));
}

float amb_occ(vec3 p)
{
    float acc=0.0;

    acc+=map(p+vec3(-0.5,-0.5,-0.5));
    acc+=map(p+vec3(-0.5,-0.5,+0.5));
    acc+=map(p+vec3(-0.5,+0.5,-0.5));
    acc+=map(p+vec3(-0.5,+0.5,+0.5));
    acc+=map(p+vec3(+0.5,-0.5,-0.5));
    acc+map(p+vec3(+0.5,-0.5,+0.5));
    acc+=map(p+vec3(+0.5,+0.5,-0.5));
    acc+=map(p+vec3(+0.5,+0.5,+0.5));
    return acc*.05+.5;
}

float ao1(vec3 p, vec3 n, float d) {

    float s = sign(d);
    float o = s*.5+.5;
    for (float i = 4.0; i > 0.; --i) {
        o -= (i*d - map(p+n*i*d*s)) / exp2(i);
    }
    return o;
    
}

//render background
vec3 background(vec3 p,vec3 d) {
    return vec3(0.);
}

void main(void)
{
    //time = time + 10.;
    
    // uv stuff
    vec2 uv = gl_FragCoord.xy/resolution.xy;
      vec2 v = uv*2.-1.;
      v.x /= resolution.y / resolution.x;
    vec3 mouse = vec3(0.0);//vec3(mouse*resolution.xy.xy/resolution.xy - 0.5,mouse*resolution.xy.z-.5);
    
    
    float fft = 0.0;//texture(iChannel0, vec2(.4, .25)).r * 2.; 
    sync = vec3( fft, 4.0*fft*(1.0-fft), 1.0-fft ) * fft;

    id = floor(hash1(floor(time*2.*hash(floor(time*.2))))*5.);
    
    // ray setup
      vec3 ro = vec3(0.,0.,-4.);
      vec3 rd = normalize(vec3(v, 1.));
    rd.z -= length(rd)*.54; //lens distort
    rd = normalize(rd);
    rd = rotate_x(rd,1.5);
    rd = rotate_y(rd,mouse.x*9.0+offset2);
    
    if( mouse.y != 0. )  rd = rotate_x(rd,mouse.y*9.0+offset1);
    
    // raymarching by distance field
      vec3 p = ro + rd ;
      glow   = vec3(.0);
    
    float dd;
    vec3 sp = p;
    
      for(int i=0; i<render_steps; i++) {
        dd = map(p);
        p += dd * rd;
        if (dd<.001) break;
      }

    vec3 n   = getNormal(p);
    float a  = ao1(p, n, 0.51);
    float s  = ao1(p, n, -0.435);
    vec3 cB  = vec3(a);
    float ao = amb_occ(p);
    
    rd=reflect(rd,getNormal(p));
    p+=rd;
    
    for (int i=0; i<render_steps/2; i++)
    {
        p += rd * map(p);
    }    
     
    float duration = 15.; 
    float parabola = 0.75;
    float saw = mod(time/duration,1.);
    parabola = 0.8-pow(4.*saw*(1.-saw),2.)*0.6;

    // glow + background + vignetting + gamma correction
      vec3 col = glow * s;
      
     if (dd>0.1) col = background(sp,rd);
   
    col *= pow(uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .8)*2.;
      col = pow(col,vec3(1./2.2));
    
    col += 0.25*(0.5-rnd(uv.xy*time))*parabola;    

      glFragColor = vec4( mix( col, cB, 0.3 ) * ao, 1. );
}
