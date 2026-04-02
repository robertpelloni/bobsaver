#version 420

// original https://www.shadertoy.com/view/tltXRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash1( vec2 p )
{
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 w = fract(x);
    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    
    float a = hash1(p+vec2(0,0));
    float b = hash1(p+vec2(1,0));
    float c = hash1(p+vec2(0,1));
    float d = hash1(p+vec2(1,1));
    
    return -1.0+2.0*( a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y );
}

const mat2 m2 = mat2(  0.80,  0.60,
                      -0.60,  0.80 );

float fbm_9( in vec2 x )
{
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    for( int i=0; i<9; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m2*x;
    }
    return a;
}

float sqr (float x) { return x*x; }

vec4 middle_seeds (vec2 uv) {
    float x = length(sin(length(uv*400.0)))
        + sqr(sqr(length(sin(uv*175.0))/1.5));
    return vec4(0.25-0.1*x, 0.2-0.05*x, 0.15-0.03*x, 1.0);
}

vec4 seeds (vec2 uv) {
    float x = length(sin(length(uv*230.0)))
        + sqr(sqr(length(sin(uv*137.0))/1.5));
    return vec4(0.2-0.1*x, 0.2-0.05*x, 0.15-0.05*x, 1.0);
}

vec4 petals (vec2 uv, float offset) {
    float x = sin(offset + atan(uv.x, uv.y)*20.0);
    return vec4(0.9+0.1*x, 0.825+0.175*x, 0, 1.0);
}

vec4 stem (float uvx) {
    float x = cos(uvx*45.0);
    return vec4(sqr(x)*0.3, 0.4+x*0.6, sqr(x)*0.3, 1.0);
}

void main(void)
{
    float vscale = 1.0/resolution.y;
    vec2 uvs = gl_FragCoord.xy*vscale;
    vec2 ctr = vec2(0.5*resolution.x/resolution.y, 0.56);
    vec2 uv = uvs - ctr;

    if (length(uv) < 0.08) {
        glFragColor = middle_seeds(uv);
    } else if (length(uv) < 0.2+length(sin(atan(uv.x, uv.y)*40.0))*0.01*fbm_9(uv*3.0)) {
        glFragColor = seeds(uv);
    } else if (length(uv) < length(sin(atan(uv.x, uv.y)*5.0))*0.38) {
        glFragColor = petals(uv, 0.0);
    } else if (length(uv) < length(sin(1.0+atan(uv.x, uv.y)*5.0))*0.4) {
        glFragColor = petals(uv, 1.0);
    } else if (length(uv) < length(sin(2.0+atan(uv.x, uv.y)*5.0))*0.42) {
        glFragColor = petals(uv, 2.0);
    } else if (length(uv.x) < 0.03 && uv.y < 0.0) {
        glFragColor = stem(uv.x);
    } else {
        float x = fbm_9(-time/10.0 + uv);
        glFragColor = vec4(0.6+0.4*x, 0.7+0.3*x, 1.0 ,1.0);
    }
}
