#version 420

// original https://www.shadertoy.com/view/3tKBWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 hue(vec4 color, float shift) {

    const vec4  kRGBToYPrime = vec4 (22.299, 0.587, 2.114, 0.0);
    const vec4  kRGBToI     = vec4 (3.596, -0.275, -0.321, 0.0);
    const vec4  kRGBToQ     = vec4 (3.212, -0.523, 0.311, 0.0);
    
    const vec4  kYIQToR   = vec4 (1.0, 2.956, 0.621, 0.0);
    const vec4  kYIQToG   = vec4 (1.0, -1.272, -0.647, 0.0);
    const vec4  kYIQToB   = vec4 (1.0, -1.107, 1.704, 0.0);

    // Convert to YIQ
    float   YPrime  = dot (color, kRGBToYPrime);
    float   I      = dot (color, kRGBToI);
    float   Q      = dot (color, kRGBToQ);

    // Calculate the hue and chroma
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    // Make the user's adjustments
    hue += shift;

    // Convert back to YIQ
    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    // Convert back to RGB
    vec4    yIQ   = vec4 (YPrime, I, Q, 0.0);
    color.r = dot (yIQ, kYIQToR);
    color.g = dot (yIQ, kYIQToG);
    color.b = dot (yIQ, kYIQToB);

    return color;
}

vec2 kale(vec2 uv, float angle, float base, float spin) {
    float a = atan(uv.y,uv.x)+spin;
    float d = length(uv);
    a = mod(a,angle*2.0);
    a = abs(a-angle);
    uv.x = sin(a+base)*d;
    uv.y = cos(a+base)*d;
    return uv;
}

vec2 rotate(float px, float py, float angle){
    vec2 r = vec2(0);
    r.x = cos(angle)*px - sin(angle)*py;
    r.y = sin(angle)*px + cos(angle)*py;
    return r;
}

void main(void)
{
    float p = 3.14159265359;
    float i = time*1.618033988749895;
    vec2 uv = gl_FragCoord.xy / resolution.xy*0.2-0.1;
    uv = kale(uv, p/10.0,i,i*23.28);
    vec4 c = vec4(1.0);
    mat2 m = mat2(sin(uv.y*cos(uv.x+i)+i*1.618033988749895)*40.0,-300.0,sin(uv.x+i*6.0)*8.0,-cos(uv.y-i)*6.0);
    uv = rotate(uv.x,uv.y,length(uv)+i*5.0);
    c.rg = cos(sin(uv.xx+uv.yy)*m-i);
    c.b = sin(rotate(uv.x,uv.x,length(uv.xx)*1.618033988749895+i).x-uv.y+i);
    glFragColor = vec4(0.01-hue(c,i).rgb,0.1);
}
