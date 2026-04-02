#version 420

// original https://www.shadertoy.com/view/wllSzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 surface (vec2 uv)
{
    vec2 k = vec2(0.0,0.0); 
    for (float i=0.0;i<64.0;i++)
    {
        vec2 q = vec2(i*127.1+i*311.7,i*269.5+i*183.3);
        vec2 h = fract(sin(q)*43758.5453);
        vec2 p = cos(h*time+1.0);
        float d = length(uv-p);
        k+=(1.0-step(0.06,d))*h;
    }
    return vec3(0.0,k.x,k.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = (2.0 * uv-1.0) / (1.0-uv.y) ;  
    vec3 c = vec3(0.0,0.0,0.0);
    vec2 d = (vec2(0.0,-1.0)-p)/float(80);
    float w = 1.0;
    vec2 s = p;
    for( int i=0; i<80; i++ )
    {
        vec3 res = surface(s);
        c += w*smoothstep( 0.0, 1.0, res );
        w *= .97;
        s += d;
    }
    c = c * 0.12;
    glFragColor = vec4( c,1.0 );
}
