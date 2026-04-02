#version 420

// original https://www.shadertoy.com/view/MXdSDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 palette(float t) {
    vec3 a = vec3(0.5,0.5,0.5);
    vec3 b = vec3(0.5,0.5,0.5);
    vec3 c = vec3(0.5,0.5,0.5);
    vec3 d = vec3(0.3 + abs(.2*sin(time)), .2, .2 + .05*sin(time));
    
    return a + b*cos( 6.28318*(c*t+d) );
}

mat2 rot2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

// distance to the scene
float map(vec3 p) {   
    
    p.z += time; // movement towards camera
    
    
    // space repitition
    p.xy = (mod(p.xy, 1.) - 0.5); // spacing = 1
    p.z = mod(p.z, 0.125) - 0.0625; // spacing = 0.25
    
    p.yz *= rot2D(1.57079632679);
    
    float torus = sdTorus(p, vec2(.2 + 0.01*sin(time), .02 + 0.01*cos(time))); // creates torus sdf
    
    return torus; // returns the closest distance to the scene which practically merges the two objects
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    
    /// initialization
    vec3 ro = vec3(0, 0, -3); // sets ray origin as vector3
    vec3 rd = normalize(vec3(uv, 1)); // sets ray direction by using uv coordinates and z direction as 1, normalizes to have all values between 0 and 1   
    vec3 col = vec3(0); // sets vec3 which represents final pixel color
    
    float t = 0.; // sets total distance travelled by ray from the origin
    

    /// raymarching
    int i; 
    for (i=0; i<80; i++) {        
        vec3 p = ro + rd * t; // finds position along ray by multiplying distance by ray direction and adding it to ray origin
   
        p.x += cos(t)*.3*cos(time);
        p.y += sin(t)*.3*cos(time);
        p.xy *= rot2D(0.5*t/0.25*.2*(sin(time)));
        
        float d = map(p); // returns current distance to the scene, which is distance that can be safely travelled without overstepping on an object
        
        t += d; // marches the ray forward by d each iteration
        
        if (d < .00001 || t > 10000.) break; // stop early if it is close enough / too far

    }

    /// coloring
    col = palette(t*.05 + float(i)*0.004); // color based on distance travelled

    
    glFragColor = vec4(col, 1.);
}
