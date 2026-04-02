#version 420

// original https://www.shadertoy.com/view/DddfRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Sat(a) clamp(a, 0., 1.)
#define getN(p) normalize(cross(dFdx(p), dFdy(p)))

mat2 rot(float a){
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void)
{
   
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    
    vec2 n, q, u = vec2(uv);
    float d = dot(u, u), s = 9., t = time, o, j;
    
    for(mat2 m = rot(5.);j < 16.; j++){
        u *= m;
        n *= m;
        q = u * s + t * 4. + sin(t * 4. - d * 6.) * 0.8 + j + n;
        o += dot(cos(q)/s, vec2(2.));
        n -= sin(q);
        s *= 1.2;
    }

    vec3 N = getN(vec3(u, o));
    
    vec4 col = vec4(pow(Sat(dot(N, normalize(vec3(0.7, 0.5, 1)))), 5.));
    
    col += mix(vec4(1., .2, .3, 0), vec4(4, 2, 1, 0), tanh(o * 0.5));  
    
    glFragColor = col;
}
