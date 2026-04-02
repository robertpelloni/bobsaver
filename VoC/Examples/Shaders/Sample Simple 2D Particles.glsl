#version 420

// original https://www.shadertoy.com/view/4syfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TOTAL_PARTICLES 80

struct Particle {
    float radius;
    vec2 pos;
    vec2 vel;
    vec3 color;
};

// function to create a circle
float createCircle(vec2 uv, vec2 pos, float r){
    float d = length(pos - uv);
    
    // smoothstep to correct aliasing
    return smoothstep(r, r-d*0.05, d);
}

vec3 updateParticles(vec2 uv){
    
    vec3 c = vec3(0.0);
    for(int i = 0; i < TOTAL_PARTICLES; i++){
        float t = time * float (i)*0.5;
        Particle p = Particle(0.1, vec2(0.0, 0.0), vec2(0.0, 0.0), vec3(0.1, 1.0, 1.0));
        p.pos.x = sin(t*0.1) * 0.3 + cos(t * 0.07) * 0.3;
        p.pos.y = cos(t*0.13) * 0.3 + sin(t * 0.09) * 0.3;
        
        p.radius = sin(t*0.23)*0.02+0.03;
        p.color = vec3(0., 0., 0.);
        p.color.rb = vec2(sin(t*0.13)*0.5+0.5);
        
        c += vec3(createCircle(uv, p.pos, p.radius)) * p.color;
        
    }
    
    return c;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
     
    // remapping coordinates from (0 <> 1) to (-0.5 <> -0.5)
    uv -= .5;
    
    // adjusting screen ratio to distorted image
    float ratio = resolution.x/resolution.y;
    uv.x *= ratio;
    
    vec3 c = updateParticles(uv);
    
    // Output to screen
    glFragColor = vec4(c,1.0);
}
