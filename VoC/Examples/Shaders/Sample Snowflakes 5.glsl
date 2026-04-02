#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/fsjXzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592654
#define flake_radius_range .05
#define flake_radius_min .05
# define flake_speed .15
# define num_flakes 20

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 cart2polar(vec2 cart){
    float r = length(cart);        
    float theta = atan(cart.y/cart.x);   
    if (cart.x < 0. && cart.y > 0.)
        theta +=  PI;    
    if (cart.x < 0. && cart.y < 0.)
        theta -= PI;    
    if (theta < 0.)
        theta += 2.* PI;        
    return vec2(r,theta);
}

float snowflake(vec2 center, float radius, vec2 point, int i){ // a binary in/out check

    float r1 = .5 + 5. * rand(vec2(i,1)) ; 
    float r2 = 1. + 4. * rand(vec2(i,2)); 
    float r3 = .4 * rand(vec2(i,3)); // controls thiness (higher = thinner)
    float r4 = 6.*(rand(vec2(i,4)-.5)); // speed of rotation
        
    vec2 polar = cart2polar(point - center);
    float theta = polar.y;
    float r = polar.x;
    if (r>radius) {return 0.;} //outside, return 0    
    theta *= 6.;
    
    if (i % 2 == 0){
        theta += time;
        }
    else{
        theta -=time;
    }
    
    float a = sin(theta); // ensure 6 fold rotational symmetry and rotation    
    float b = cos(r1 * r/radius * 2. * PI);      
    float c = sin(r2 * r/radius * 2. * PI);
    
    return step(r3, (a + b + c)/3.);

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float gradient = uv.y;    
    //uv = uv * 2. - vec2(1,1);      
    uv.y = -uv.y; // flip coords so +y is down
    uv.y += 1. + flake_radius_min + flake_radius_range; // offset so (0,0) is above top left and we won't see flake pop in
    float aspect = resolution.x/resolution.y;
    uv.x *= aspect; // correct aspect ratio
   
    
    // Time varying pixel color
    // vec3 col = vec3(0,0,1)* (1.-uv.y);
    vec3 bg = mix(vec3(0,0,1), vec3(.2,.2,.2), gradient);

    // vec3 col = vec3(1,1,1) * uv.x;
    // Output to screen
    glFragColor = vec4(bg,1.0);
        
    
    for (int i = 0; i<num_flakes; i++){
        vec2 c = vec2(0, 5. * rand(vec2(i,1)));
        float y = c.y + flake_speed * time * (.5 + .5*rand(vec2(i,i))); // fall speed
        c.y  = mod(y, 2.);
        int pass = int(floor(y/2.)); 
        
        int flake_number = i +  pass * num_flakes; // ensure new flake everytime around
        c.x = aspect *  rand(vec2(flake_number, .1));
        float radius = flake_radius_min  + flake_radius_range * rand(vec2(flake_number, .2));
        vec3 col = vec3(1,1,1) * snowflake(c, radius, uv, flake_number);

        glFragColor += vec4(col, 1.);
    }
}
