#version 420

// original https://www.shadertoy.com/view/3lVBRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.2831853071

float circle(vec2 uv, vec2 pos, float radius){
    float px = length(1./resolution.xy);
    return smoothstep(px, 0., distance(uv, pos)-radius);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv = ( gl_FragCoord.xy - 0.5* resolution.xy ) / resolution.y;
    
    float t = mod(time*0.7, 15.); // 
    float amt = min(sin(fract(t)*TAU/4.0)*1.5, 1.0) + floor(t) + 1.0;
    
    float sum = 0.0;
    
    float spacing = 0.2;
    
    float turn = TAU/amt;
    for(float i=0.; i<amt; i++){
        sum = mix(sum,1.-sum,circle(uv, vec2(cos(i*turn), sin(i*turn))*spacing, 0.3));
    }

    vec3 col = vec3(1.-sum);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
