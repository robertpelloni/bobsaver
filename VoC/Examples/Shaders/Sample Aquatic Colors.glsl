#version 420

// original https://www.shadertoy.com/view/WtffWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const mat2 m = mat2( 0.60,  0.80, -0.80,  0.60 ); // everybody use this matrix

float noise(vec2 p)
{
    float a = fract(100.*sin(220.*p.x+34.24)*sin(520.*p.y+2.68));
    
    return a;
}

vec2 random_direction(vec2 p)
{
    float f = noise(p);
    return vec2(cos(6.283185307*f), sin(6.283185307*f));
}

float smoothing(float a, float b, float t)
{
    t = t * t * t * (t * (t * 6. - 15.) + 10.);
    return a + (b-a)*t;
}

float perlin(vec2 p, float N)
{
    p *= N;
    vec2 r = floor(p);
    vec2 q = fract(p);
    
    float n00 = dot(q-vec2(0.,0.),random_direction(r+vec2(0.,0.)));
    float n10 = dot(q-vec2(1.,0.),random_direction(r+vec2(1.,0.)));
    float n01 = dot(q-vec2(0.,1.),random_direction(r+vec2(0.,1.)));
    float n11 = dot(q-vec2(1.,1.),random_direction(r+vec2(1.,1.)));
    
    return .5*(1.+smoothing(smoothing(n00, n10, q.x),smoothing(n01, n11, q.x), q.y));
}

float perlin_octaves(vec2 p)
{
    float N = 7.;// + .5*sin(0.0003*time);
    int oct = 4;
    
    float ns = perlin(p, N);
    float A = 1.;
    float MAX = 1.;
    for (int i = 0; i < oct; ++i) {
        N *= 2.;
        A *= .5;
        ns += A*perlin(p + N*vec2(1., 2.), N);
        MAX += A;
    }
    return ns / MAX;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x + vec2(0.02,0.05)*time + vec2(-0.05*sin(0.4*time), -0.03*sin(0.3*time));

    vec2 p = uv;
    float per0 = perlin_octaves(p);
    float per1 = perlin_octaves(m*p + vec2(1., 3.));
    float per2 = perlin_octaves(m*m*p + vec2(2., 2.));
    float per3 = perlin_octaves(m*m*m*p + vec2(1., 1.));
    
    float super_perlin0 = perlin_octaves(m*(vec2(per0, per1) + 0.5*(per1*sin(.07*time)+per3*cos(.07*time))));
    float super_perlin1 = perlin_octaves(m*m*vec2(per2, per3));// + 0.7*sin(0.2*time)*(per2+per3));
    
    float mega_perin = perlin_octaves(m*m*m*vec2(super_perlin0, super_perlin1));
    
    vec3 col = vec3(mega_perin, mega_perin, mega_perin);
    
    col *= per1*vec3(.4, .8, .3) + per3*vec3(.5, .25, .8) + per2*vec3(.0, .02, .0);
    col *= 1.7;
    
    // to calibrate noise
    float ns = .5+.5*noise(uv);
    //col = vec3(ns, ns, ns);
    
    glFragColor = vec4(col,1.0);
}
