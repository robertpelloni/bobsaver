#version 420

// original https://www.shadertoy.com/view/WlGfWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//simplex noise from the book of shader
//cloudy noise octaves from here :
//https://www.shadertoy.com/view/4tdSWr

const vec3[3] c = vec3[3](vec3(.14,0.,.27),
                             vec3(.73,0.,.84),
                             vec3(.96,.45,.91));//colors
const float t = .98;//threshold for last color
const float o = .47;//noise octave diminution
const float s = .2;//scale
const float d = 1.1;//distorsion
const float f = 1.;//factor before color
const float e = 1.;//exponent before color
const float ts = .05;//time speed

//usefull for snoise
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

//cloudy noise octaves
const mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

float fbm(vec2 n) {
    float total = 0.0, amplitude = 1.;
    for (int i = 0; i < 7; i++) {
        total += snoise(n) * amplitude;
        n = m * n;
        amplitude *= o;
    }
    return total;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    float n = ((fbm(uv*0.7+time*ts)+
            fbm(uv*0.7-time*ts)+
            fbm(uv*3.))+3.)/6.;
    uv+=n * d;
    uv*= s;
    n = (fbm(uv*3.)+1.)/2. * n * f;
    n = clamp(n, 0.,1.);
    
    n = (0.5-abs(n-0.5))*2.;
    n = pow(n,e);
    vec3 col;
    if(n>=t){
        col = c[2];
    }
    else{ 
        col = mix(c[0], c[1], n);
    }
    
    // Output to screen
    glFragColor = vec4(col,1.);
}
