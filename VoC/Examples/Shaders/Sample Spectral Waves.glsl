#version 420

// original https://www.shadertoy.com/view/MsdcWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circled(vec2 uv, vec2 pos, float rad) {
    float d = length(pos - uv) - rad;
    return d;
}

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

#define nCircles 128

void main(void)
{
    vec2 uv = gl_FragCoord.xy;
    vec2 center = resolution.xy * 0.5;
    float radius = 0.0125* resolution.y;
    
    float anginc = (3.143*2.0)/float(nCircles);
    float ang = 0.0;
       glFragColor = vec4(0.1,0.2,0.3,1.0);
    vec4 col = vec4(0.5 + 0.5*cos(time+uv.xyx*0.01+vec3(0,2,4)),1.0);

    float func = 1000.0;
    for(int i=0; i<nCircles;i++)
    {
        float phaseoffs = sin(float(i)*0.25*sin(time*0.001));

        float move = cos(time+ang*time*0.1);
        vec2 ps = center + vec2(cos(ang+phaseoffs*0.77),sin(ang+phaseoffs))*resolution.x*0.26*move; 
        func = smin(func,circled(uv, ps, radius*abs(move)),70.0/resolution.x);
        ang+=anginc*4.0;
    }
    
    glFragColor = mix(glFragColor,col*max(0.0,-func),0.225);
}
