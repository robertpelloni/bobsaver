#version 420

// original https://www.shadertoy.com/view/tljyWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;

mat2 r2d(float a){float sa = sin(a);float ca=cos(a);return mat2(ca,sa,-sa,ca);}

float sat(float a)
{
    return clamp(a, 0., 1.);
}

float cir(vec2 p, float r)
{
    return length(p)-r;
}

// Thanks IQ :)
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

vec3 rdr(vec2 uv)
{
    vec3 col;
    
    col = mix(vec3(33, 75, 166)/255., vec3(0.1), sat(length(uv)));
    
    int i = 0;
    while (i < 4)
    {
        float xPos = float(i)*.2-.25;
        
        float yPos = (sin(float(i)*15.)*.2+.5)*mix(-1.,-8., sat(pow(sin(float(i)+time*0.9), 5.)));
        float body = (sdSegment(uv, vec2(xPos*1.5, -1.), vec2(xPos,.3*yPos))-.05);
        col = mix(vec3(0.), col, sat(body*200.));
        vec2 headP = vec2(xPos, .3*yPos);
        vec2 blink = vec2(1., 1.-max(pow(sin(time*4.-float(i)*1.2), 50.), 0.1));
        float eyes = min(cir((uv-headP-vec2(0.02, 0.002*abs(uv.x)))/blink,.01), cir((uv-headP-vec2(-0.02, 0.02*(uv.x)))/blink, .01));
        col = mix(vec3(235, 202, 19)/255., col, sat(eyes*400.));
        ++i;
    }
    
    return col;
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-vec2(.5)*resolution.xy)/resolution.xx;
     
    vec3 col = rdr(uv);
    
    glFragColor = vec4(col,1.0);
}
