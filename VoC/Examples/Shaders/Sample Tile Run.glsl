#version 420

// original https://www.shadertoy.com/view/sdBBWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 brickTile(vec2 _st, float _zoom){
    _st *= _zoom;

    // Here is where the offset is happening
    _st.x += step(1., mod(_st.y,2.0)) * 0.5;

    return fract(_st);
}

float box(vec2 _st, vec2 _size){
    _size = vec2(0.5)-_size*0.5;
    vec2 uv = smoothstep(_size,_size+vec2(1e-4),_st);
    uv *= smoothstep(_size,_size+vec2(1e-4),vec2(1.0)-_st);
    return uv.x*uv.y;
}

float blackCircle(vec2 uv, float r)
{
    return smoothstep(-0.02, 0.02, length(uv - vec2(0.5)) - r);
}

vec2 circleTile(vec2 uv, float zoom)
{
    uv *= zoom;
    float tc = fract(time);
    
    float xOffset = (step(1.0, mod(uv.y, 2.0)) - 0.5) * 2.0 * 2.0 * mod(tc, 0.5);
    float yOffset = (step(1.0, mod(uv.x, 2.0)) - 0.5) * 2.0 * 2.0 * mod(tc, 0.5);
    
    uv += mix(vec2(xOffset, 0.0), vec2(0.0, yOffset), step(0.5, tc));
    return fract(uv);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv.x *= resolution.x / resolution.y;
    
    vec2 st = circleTile(uv,10.0);

    //vec3 color = vec3(box(st,vec2(0.9)));
    
    vec3 color = vec3(blackCircle(st, 0.4)); 

    // Output to screen
    glFragColor = vec4(color,1.0);
}
