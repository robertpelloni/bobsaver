#version 420

// original https://www.shadertoy.com/view/3s2XW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float xor(float a, float b) {
    return a*(1.-b) + b* (1.-a);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5 * resolution.xy)/resolution.y;

    vec3 col = vec3(0.);
    
    // Rotação
    float angle = .78;
    float sinA = sin(angle);
    float cosA = cos(angle);
    uv*= mat2(cosA, -sinA, sinA, cosA);
    
    // Scale
    uv*= 15.;
    
    vec2 gv = fract(uv)-.5;
    
    vec2 id = floor(uv);
    
    float circle = 0.;
    float time = time;
    
    
    for(float y=-1.; y<=1.; y++){
        for(float x=-1.; x<=1.; x++){
            vec2 offs = vec2(x,y);
            float dist = length(gv-offs);
            
            float distUV = length(id+offs)*.3;
            float radiusPos = sin(distUV-time)*.5 + .5;
            
            float radius = mix(.3, 1.5, radiusPos);
            
            float blur = mix(.8, .9, -sin(dist));
            
            circle = xor(circle, smoothstep(radius,radius*blur,dist));
            
        }
    }
    
    //col.rb = gv;
    col += mod(circle, 2.);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
