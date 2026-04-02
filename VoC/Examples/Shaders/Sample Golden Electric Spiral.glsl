#version 420

// original https://www.shadertoy.com/view/csj3zt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float seg(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float a = atan(uv.y, uv.x);
    vec2 p = cos(a + time) * vec2(cos(0.5 * time), sin(0.3 * time));
    vec2 q = (cos(time)) * vec2(cos(time), sin(time));
    
    float d1 = length(uv - p);
    float d2 = length(uv - 0.);
    
    vec2 uv2 = 2. * cos(log(length(uv))*0.25 - 0.5 * time + log(vec2(d1,d2)/(d1+d2)));///(d1+d2);
    //uv = mix(uv, uv2, exp(-12. * length(uv)));
    //uv = uv2;
    
    vec2 fpos = fract(4. *  uv2) - 0.5;
    float d = max(abs(fpos.x), abs(fpos.y));
    float k = 5. / resolution.y;
    float s = smoothstep(-k, k, 0.25 - d);
    vec3 col = vec3(s, 0.5 * s, 0.1-0.1 * s);
    col += 1./cosh(-2.5 * (length(uv - p) + length(uv))) * vec3(1,0.5,0.1);
    
    float c = cos(10. * length(uv2) + 4. * time);
    col += (0.5 + 0.5 * c) * vec3(0.5,1,1) *
           exp(-9. * abs(cos(9. * a + time) * uv.x
                       + sin(9. * a + time) * uv.y 
                       + 0.1 * c));
    
    glFragColor = vec4(col,1.0);
}
