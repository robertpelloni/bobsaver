#version 420

// original https://www.shadertoy.com/view/NlSSDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Simple rainbow gradient with entirely linear interpolation.
//It is totally unrealistic compared to visible spectrum in reality. 
vec3 Rainbow(float t) {
    vec3 c = vec3(1.0,0.0,0.0);//red
    
    t *= 6.0;
    c.g = mix(0.0, 1.0, clamp(t, 0.0, 1.0));//red to yellow
    
    t -= 1.0;
    c.r = mix(1.0, 0.0, clamp(t, 0.0, 1.0));//yellow to green
    
    t -= 1.0;
    c.b = mix(0.0, 1.0, clamp(t, 0.0, 1.0));//green to cyan
    
    t -= 1.0;
    c.g *= mix(1.0, 0.0, clamp(t, 0.0, 1.0));//cyan to blue
    
    t -= 1.0;
    c.r += mix(c.r, 1.0, clamp(t, 0.0, 1.0));//blue to purple
    
    t -= 1.0;
    c.b *= mix(1.0, 0.0, clamp(t, 0.0, 1.0));//purple to red
    
    return clamp(c, 0.0, 1.0);
}

mat2 RotationMatrix(float rotAng) {
    vec2 rot = vec2(cos(rotAng), sin(rotAng));
    return mat2(rot.x, rot.y, -rot.y, rot.x);
}

//sin and cos return the value between -1 to +1,
//so I normalize them to the range of 0 to +1 to save me few codes:
float sin01(float x) {
    return sin(x) * 0.5 + 0.5;
}

float cos01(float x) {
    return cos(x) * 0.5 + 0.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv *= 4.5;
    uv.x *= max(resolution.x, resolution.y) / min(resolution.x, resolution.y);
    uv.x *= 0.447;
    
    vec3 bgRainbow = 
        Rainbow(fract(uv.x / uv.y * 0.323 + time * 0.4)) + 
        Rainbow(fract(uv.x * uv.y * 1.403 - time * 0.33)) ;
    bgRainbow *= 0.125;
    
    const float pi = 3.141592653589793;
    const float tau = 6.283185307179586;
    const float sides = 6.0;
    const float angDiv = tau / sides;
    
    uv *= RotationMatrix(pi + time * 0.35);
    uv += time * 0.333;
    
    float squash = 0.877;
    uv.y /= squash;
    vec2 gv = floor(uv);
    float shift = fract(gv.y * 0.5) == 0.0 ? 0.5 : 0.0;
    uv.x += shift;
    uv = fract(uv) - 0.5;
    uv.y *= squash;
    
    float angle = atan(uv.x/uv.y);
    angle += uv.y < 0.0 ? pi : 0.0;
    angle += angle < 0.0 ? tau : 0.0;
    float angFrac = fract(angle * sides / tau) * angDiv;
    
    float beta = (pi - angDiv) * 0.5;
    float phi = pi - angFrac - beta;
    
    float radius = length(uv.xy);
    //radius = 1.0 - radius;
    
    //No idea why sin(phi) and sin(beta) shouldn't be inverted (according to the law of sines) to make this work:
    float dist = radius * sin(phi) / sin(beta);
    
    float dir = shift * 4.0 - 1.0;
    dist = cos01(dist * 10.78 * pow(3.0, 0.0) + time * 2.0 * dir);
    //dist = sin01(dist * 8.1 * pow(3.0, 2.0) + time * 2.0 * dir);
    float line = ((dist < 1.1) && (dist > 0.99775) ? 1.0 : 0.0);
    //dist = pow(dist, 0.5) * 0.13 - 0.1 + line;
    vec3 col = Rainbow(cos01(dist * 0.745 - time * 2.0));
    col = col * smoothstep(0.0, 1.0, pow(dist, 0.3) * 0.4) + line;
    
    float ring = clamp(radius / squash * 2.0, 0.0, 1.0);
    ring = smoothstep(0.0, 1.0, 1.0 - abs(ring * 2.0 - 1.0));
    
    vec3 radialRainbow = Rainbow(fract(angle/tau + time * dir * 0.23)) * ring;
    radialRainbow *= 0.5;
    col += radialRainbow + bgRainbow;
    
    // Output to screen
    glFragColor = vec4(dist,dist,dist, 1.0);
    glFragColor = vec4(col, 1.0);
    //glFragColor = vec4(radialRainbow, 1.0);
    //glFragColor = vec4(uv, dist, 1.0);
    //glFragColor = vec4(dist, angle/tau, 0.0, 1.0);
}
