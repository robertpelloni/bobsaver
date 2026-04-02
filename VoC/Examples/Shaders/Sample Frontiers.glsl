#version 420

// original https://www.shadertoy.com/view/NssSDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan, slerpy and wwrighter for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define PI acos(-1.)
#define rotation(a) mat2(cos(a),sin(a),-sin(a),cos(a))

// cosine palette from iq
// https://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette (float t, vec3 c)
{return vec3(0.5)+vec3(0.5)*cos(2.*PI*(c*t+vec3(0.,0.36,0.64)));}

// 2D mask returning 0 or 1 based on a threshold
// on repeated UVs
float mask (vec2 uv)
{
    // animate the UVs
    uv += time*.5;
    // draw a diagonal
    float m = uv.x+uv.y;
    // repeat it by taking the fractional part (= modulo by 1)
    // and shift the position by half a period
    // to put the shape in the center of the cell
    m = fract(m)-.5;
    // symmetrize the shape with absolute value
    m = abs(m);
    
    // return the mask by making a threshold of the value m
    return step(0.1, m);
}

// declare global variables for id of repetition
// and glow accumulation
float id, g1=0.;

// Signed Distance Function
// also called map() by many shadercoders
// this is our scene, our 3d shapes
float SDF (vec3 p)
{
    // store the original space
    vec3 pp = p;
    
    // symmetrize in the y axis
    p.y = abs(p.y)-10.;
    
    // declare a period for the repetition
    float period = 4.;
    // calculate the id of the cells
    id = floor(p.x/period);
    // repeat the space
    p.x = mod(p.x,period)-period*0.5;
    
    // "push" the shapes in the x axis based on a sine wave along z axis
    p.x += sin(p.z*id*0.2+time*2.)*0.5;
    // "push" the shapes in the y axis based on a sine wave along z axis
    p.y += cos(p.z*id*0.1+time*3.);
    
    // declare the shape, an infinite cylinder
    float c1 = length(p.xy)-0.5;
    
    // retrieve original position to clea all space transformations
    // made previously
    p = pp;
    // rotate the space in the z axis
    p.xy *= rotation(time);       
    
    // symmetrize the space on the x and y axis
    p.xy = abs(p.xy)-.8; 
    
    // declare the shape, a sphere
    float s = length(p)-0.5;
    // accumulation for making the sphere glowing
    g1 += 0.01/(0.01+s*s);
    
    // return all the shapes that compose our field
    // min = union, max = intersection, max(-shape,othershape) = subtraction
    return min(s,c1);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    // Normalized pixel coordinates (from -1 to 1)
    vec2 centered_uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    // kaleidoscopic effect on UVs
    //centered_uv = abs(centered_uv)-0.5;
    
    // fake diffraction by moving slightly the UVs
    // based on the 2D mask
    centered_uv += mask(centered_uv)*0.1;
    
    // declaring the camera
    vec3 ro = vec3(0.,0.,-3.), 
    rd = normalize(vec3(centered_uv,1.)),
    p = ro,
    // declaring the color background
    col = vec3(0.);
    
    bool hit = false;
    
    // will help us store the iterations 
    // for a supe chap and fake AO
    float shad;
    
    // raymarching loop
    for (float i=0.; i<64.; i++)
    {
        float d = SDF(p);       
        if(d<0.01)  // if we're really close to the shape
        {
            hit = true;
            shad = i/64.;
            break;
        }
        // moving along the ray 
        // with the technique of sphere-tracing
        p += d*rd*0.6;
    }
    
    if (hit)
    {
        col = palette(id,vec3(0.1));
        col *= 1.-shad;
    }
    
    // adding the glow on spheres
    col += g1*0.5;
    
    // Output to screen
    // sqrt() make a approx. gamma correction
    // the correct one is pow(col, vec3(1./2.2))
    glFragColor = vec4(sqrt(col),1.0);
}
