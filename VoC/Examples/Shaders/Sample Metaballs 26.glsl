#version 420

// original https://www.shadertoy.com/view/3lycWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//simplified by iq
float smin(float a, float b, float k, float p, out float t)
{
    float h = max(k - abs(a-b), 0.0)/k;
    float m = 0.5 * pow(h, p);
    t = (a < b) ? m : m-1.0;
    return min(a, b) - (m*k/p);
}
#define smix(a, b, t) mix(a, b, abs(t))

#define iR resolution

void main(void)
{
    vec4 O = glFragColor;
    vec2 pos = gl_FragCoord.xy;

    //data
    float p0 = distance(pos, vec2(iR.x*0.5 - 50.0, iR.y*0.5)) - 50.0 + sin(time*0.45)*10.0;
    float p1 = distance(pos, vec2(iR.x*0.5 + 50.0 + sin(time * 0.5)*20.0  , iR.y*0.5)) - 50.0;
    float p2 = distance(pos, iR.xy*0.5 + vec2(sin(time), cos(time)*0.75)*150.0 ) - 50.0;
    
    vec3 p0c = vec3(1.0, 0.5, 0.25);
    vec3 p1c = vec3(0.25,0.5, 1.0);
    vec3 p2c = vec3(0.5, 0.0, 0.5);
    
    //distance and color track
    float d = 100.0;
    vec3 c = vec3(1.0);
    
    //smoothing radius and exponent
    float k = 60.0 + sin(time*0.23) * 20.0;
    float p = 3.5;
    
    //--
    float t = 0.0;
    d = smin(p0, p1, k, p, t);
    c = smix(p0c, p1c, t);
    
    d = smin(d, p2, k, p, t);
    c = smix(c, p2c, t);
   
    //--
    O.xyz = vec3( min(max(-d, 0.0), 1.0) ) * c; 
    O.xyz *= 0.25 + pow(-d/60.0, 0.2)*0.75;

    glFragColor = O;
}
