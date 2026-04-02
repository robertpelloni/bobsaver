#version 420

// original https://www.shadertoy.com/view/tslcW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float a=1.0;
const float b=.1759;
const float PI=3.14159265359;

float spiralSDF(vec2 p,vec2 c){
    // t = theta
    p = p - c;
    float t=atan(p.y, p.x) + time*8.0;
    // t=(t+PI)/(2.*PI);
    float r=length(p.xy);
    
    float n=(log(r/a)/b-t)/(2.*PI);

    // Cap the spiral
    // float nm = (log(0.11)/b-t)/(2.0*PI);
    // n = min(n,nm);
    // return (n+1.0)/100.0;
    float upper_r=a*exp(b*(t+2.*PI*ceil(n)));
    float lower_r=a*exp(b*(t+2.*PI*floor(n)));
    // float lower_r = 0.0;
    
    return min(abs(upper_r-r),abs(r-lower_r));
}

void main(void)
{
    vec2 R=resolution.xy;
    vec2 uv=(2.*gl_FragCoord.xy-R)/R.y;
    vec2 c = vec2(0.0,0.0);
    
    // Uncomment for more swirl
    // vec2 c = vec2(0.7*sin(time*1.3), 0.3*sin(time)*2.0);
    float r = length(uv);
    float d = spiralSDF(uv,vec2(c));

    // Alter distance for a satisfying visual
     float v = pow(d, 1.32) / 0.23;
    glFragColor.rgb=vec3(v);
    //O.rgb = O.rgb*1.0/r;
    // O.xy=uv;
}
