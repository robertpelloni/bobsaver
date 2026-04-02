#version 420

// original https://www.shadertoy.com/view/WlsSDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// function to return a random number
float random (vec2 p) {
    p = fract(p*vec2(123.45, 678.91));
    p += dot(p, p+23.45);
    return fract (p.x * p.y);
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 pattern = vec3(0);
    
    
    float units = 18.;
    vec2 gv = fract(uv * units) - .5;
    vec2 id = floor(uv * units) + .5; // add .5 here to center
    
    float d = length(gv);
    
    float minRadius = .2;
    float maxRadius = .4;
    float speed = 10.2;
    float time = time * speed;
    float pulseAmount = 3.;
    float radiusTime = sin(random(id) * time) * .5 + .5; 
    
    float radius = mix(
        minRadius, 
        maxRadius,
        radiusTime);
        //sin(length(pulseAmount*gv - id) - time)*.5+.5); // how to offset sine based on id
        
    pattern += smoothstep(radius, radius*mix(.4,.7,(radiusTime)),d);
    
    float t = sin(length(gv - id) - time)*.5+.5;
    vec3 color = vec3(random(id));
    
    //vec3 color = vec3(t);
    glFragColor = vec4(color * pattern,1.);
}
