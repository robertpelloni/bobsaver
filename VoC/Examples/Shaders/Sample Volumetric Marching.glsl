#version 420

// original https://www.shadertoy.com/view/WtyczG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://www.youtube.com/watch?v=8OrvIQUFptA
// https://shaderbits.com/blog/creating-volumetric-ray-marcher

/*

 trying to figure out how volumetric rendering works... wish me luck
 
 just some notes:
     so if i get it right, to create volumetric cloud like thingies, we need:

     1. Perlin-Worley noise to create a cloud like noise 
     2. Adjust the raymarcher to takes fixed steps when inside the volume.
     3. Take sample points by checking the density?
     
     
     (not used in implementation)
     4. Calculate light energy at that point?
          - Beer's Law
          - Henyey Greenstein
          - In-scattering probabilities
          
          E : energy
          d : depth in cloud
          
          E = 2e^{-d} * (1 - e^{-2d})      "Beer's-Powder"
          
          - Powder effect?
*/
#define MIN_MARCH_DIST 0.001
#define MAX_MARCH_DIST 20.
#define MAX_MARCH_STEPS 100.
#define MAX_VOLUMETRIC_STEPS 64.

// noise function from another shader, https://www.shadertoy.com/view/MdGSzt
// copy from https://www.shadertoy.com/view/4l2GzW
float random(float n)
{
     return fract(cos(n*89.42)*343.42);
}
vec3 random(vec3 n)
{
     return vec3(
        random(n.x*23.62-300.0+n.y*34.35),
        random(n.x*45.13+256.0+n.y*38.89),
        random(n.x*76.13+311.0+n.y*42.15)); 
}
float worley(vec3 n,float s)
{
    float dis = 2.0;
    for(int x = -1;x<=1;x++)
    {
        for(int y = -1;y<=1;y++)
        {
            for(int z = -1; z <= 1; z++) {
                vec3 p = floor(n/s)+vec3(x,y,z);
                float d = length(random(p)+vec3(x,y,z)-fract(n/s));
                if (dis>d)
                {
                    dis = d;   
                }
            }
            
        }
    }
    return 1.0 - dis;
    
}

// copy from https://www.shadertoy.com/view/4sc3z2
#define MOD3 vec3(.1031,.11369,.13787)

vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
float perlin_noise(vec3 p)
{
    vec3 pi = floor(p);
    vec3 pf = p - pi;
    
    vec3 w = pf * pf * (3.0 - 2.0 * pf);
    
    return     mix(
                mix(
                    mix(dot(pf - vec3(0, 0, 0), hash33(pi + vec3(0, 0, 0))), 
                        dot(pf - vec3(1, 0, 0), hash33(pi + vec3(1, 0, 0))),
                           w.x),
                    mix(dot(pf - vec3(0, 0, 1), hash33(pi + vec3(0, 0, 1))), 
                        dot(pf - vec3(1, 0, 1), hash33(pi + vec3(1, 0, 1))),
                           w.x),
                    w.z),
                mix(
                    mix(dot(pf - vec3(0, 1, 0), hash33(pi + vec3(0, 1, 0))), 
                        dot(pf - vec3(1, 1, 0), hash33(pi + vec3(1, 1, 0))),
                           w.x),
                       mix(dot(pf - vec3(0, 1, 1), hash33(pi + vec3(0, 1, 1))), 
                        dot(pf - vec3(1, 1, 1), hash33(pi + vec3(1, 1, 1))),
                           w.x),
                    w.z),
                w.y);
}

// not so worley anymore
float perlinworley3d(vec3 p) {
    float noise = perlin_noise(20.*p + time) * .8 + .05
                + perlin_noise(40.*p + time) * .5
                + perlin_noise(70.*p + time) * .25
      //          * worley(12.*p, 1.0);
      ;
    //noise += perlin_noise(12.*p) * .5;
    return noise;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

# define BBOX 1
float sdBoundingBox( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

int id = 0;

float map(vec3 p) {
    id = 0;
    float volBox = sdBox(p, vec3(0.27));
    float bBox = sdBoundingBox(p, vec3(0.27), 0.005);
    if(bBox < volBox) {
        id = BBOX;
    }
    
    return min(volBox, bBox);
}

vec3 normal(in vec3 p) {
    float eps = MIN_MARCH_DIST;
    vec2 h = vec2(eps, 0);
    return normalize(vec3(map(p+h.xyy) - map(p-h.xyy),
                          map(p+h.yxy) - map(p-h.yxy),
                          map(p+h.yyx) - map(p-h.yyx)));
}

mat2 rotate(float a) {
    float si = sin(a), co = cos(a);
    return mat2(co, si, -si, co);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,-1.);
    ro.xz *= rotate(time/8.);
    vec3 ta = vec3(0,0,0);
    vec3 ww = normalize(ta-ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = normalize(cross(uu,ww));
    vec3 rd = normalize(uv.x*uu + uv.y*vv + 1.0*ww);
    
    vec3 col = vec3(0,0,0);
    vec3 p = vec3(0);
    float t = 0.;
    float i = 0.;
    float sampleDensity = 0.;
    bool inside = false;
    float StepSize = 1. / MAX_VOLUMETRIC_STEPS;    
    vec3 C = vec3(0,0,0);
    vec3 C2 = vec3(0);
    
    for(i=0.; i < MAX_MARCH_STEPS; i++) {
        p = ro + t*rd;
        float d = map(p);
        if(inside && d > 0.) {
            // there is nothing behind the volume atm
            // so just break when we exit the volume.
            break;
        }
        if(d < MIN_MARCH_DIST) {
            if(id == BBOX) {
                break;
            }
            if(!inside) {
                // fix weird plane visuals
                t += random(dot(p, p) + time) * StepSize;
                p = ro + t*rd;
            }
            inside = true;
            float density = perlinworley3d(p);
            
            
            // method1
            sampleDensity += clamp(density, 0., 1.) * StepSize;
            // Cout(v) = Cin(v) * (1 - Opacity(x)) + Color(x) * Opacity(x)
            C = C * (1. - density * StepSize) + vec3(1,0,0) * density * StepSize;
            
            
            // method2
            float absorbance = exp(-density * StepSize);
            C2 += vec3(1,0,0) * (1.-absorbance);
            
            
            t += StepSize;
        }
        else {
            t += d;
        }
        if(t > MAX_MARCH_DIST)
            break;
    }
    if(i >= MAX_MARCH_STEPS) {
        t = MAX_MARCH_DIST;
    }
    
    float strength = 14.;
    sampleDensity *= strength;
    C *= strength;
    
    if(t < MAX_MARCH_DIST) {
        if(id == BBOX) {
            vec3 L = normalize(ro-rd - cross(vec3(0,1,0),rd)*.2);
            vec3 N = normal(p);            
            vec3 c = vec3(.7) * clamp(dot(L, N), 0., 1.) + vec3(0.1);
            col = mix(c, C, sampleDensity);
        }
        else col = C2*14.;// C2*14.;
    }
    
    glFragColor = vec4(pow(col, 1./vec3(2.2)), 1);
}
