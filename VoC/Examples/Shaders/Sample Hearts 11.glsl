#version 420

// original https://www.shadertoy.com/view/wt2GWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash22(vec2 p) 
{
    return fract(sin(vec2(dot(p,vec2(263.135,198.742)),dot(p,vec2(624.235,321.217))))*13.635); 
}

float vorohearts( vec2 x)
{
    vec2 n = floor(-x);
    vec2 f = fract(-x);
    
    float md = 1.0;
    
    for( int j=-1; j<=1; j++ )
    {
        for( int i=-1; i<=1; i++ )
        {
            vec2  g = vec2(float(i), float(j));
            vec2  o = hash22( n + g );
            vec2  r = g - f + (.5+.5*sin(time+o*6.28));
            r.x *= .8*(1.+sin(.5+sin(6.*time))*.03);
            r.y *= .95+sin(1.5+sin(3.*time))*.07;
            r.y += .08;
            r.y -= sqrt(abs(r.x))*.52;
            float d = length(r);
            if( d < md ) {md = d;}
        }
    }
    return md;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    
    //Heart uv
    uv = uv*3.;
    float d = vorohearts(uv);
    d = smoothstep(.38, .25, d);
    
    //Heart color
    vec3 p = vec3(1.6*d*(.6+sin(.5+sin(6.*time))*.1), d*(1.8+sin(.5+sin(6.*time))*.3), 2.1*(1.+sin(.5+sin(6.*time))*.3));
    vec3 col = vec3(d) * p;
    
    //Background
    col += vorohearts(uv) * .35 * p;
    
    glFragColor = vec4(col,1.);
}
