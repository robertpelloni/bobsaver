#version 420

// original https://www.shadertoy.com/view/7d3SD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float pattern( in vec2 p )
{
    vec2 q = vec2( fbm( p + vec2(0.0,0.0) ),
                   fbm( p + vec2(5.2,1.3) ) );

    vec2 r = vec2( fbm( p + 4.0*q + vec2(1.7,9.2) ),
                   fbm( p + 4.0*q + vec2(8.3,2.8) ) );

    return fbm( p + 4.0*r );
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy*3.;
    vec2 oSt = st;
    st += fbm(st + 0.2*time - distance(st, vec2(0.5)));
    // st += st * abs(sin(u_time*0.1)*3.0);
    vec3 color = vec3(0.0);

   
    float a = fbm(st + 3.*fbm(oSt + vec2(0.2*time, 0.)));
    float b = fbm(st + 3.*fbm(oSt + vec2(a, 0.) ));
    float c = fbm(st + 3.*fbm(oSt + vec2(b, 0.) ));
   

 

    color = mix(vec3(a*a*a*a, b, c),
                vec3(196./255., 116./255., 174./255.),
                a);
  
    color = mix(color,
                vec3(156./255., 116./255., 196./255.),
                b*b);
     color = mix(color,
                vec3(1.),
                c*c);

    glFragColor = vec4(color,1.);
}
