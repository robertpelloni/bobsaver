#version 420

// original https://www.shadertoy.com/view/XlXSD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float clamps(float val) {
    return clamp(val,0.,1.);    
}

float distanceToSegment( in vec2 p, in vec2 a, in vec2 b, float size )
{
    //iq's function
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    
    return 1.-clamp((length( pa - ba*h )-size)*500.,0.,1.);
}
float rectangle(vec2 uv, vec2 pos, vec2 size) {
    //Not really mine but edited, you can replace circles with rectangles maybe?
    return 1.-clamp(length(max(abs(uv-pos)-size,0.))*500.,0.,1.);
}
float circle(vec2 uv, vec2 pos, float size) {
    return 1.-clamp((length(uv-pos)-size)*500.,0.,1.);
}

void main(void)
{
     vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 suv = vec2(((uv.x-0.5)*(resolution.x / resolution.y))+0.5,uv.y);
    float time = time*2.;
    float drawing = 0.;
    for (float i = 0.; i < 30.; i++) {
        vec2 position = vec2((sin(time*((i/50.)+1.))/5.)+0.5,(0.2+(i*0.01))+(cos(time*((i/50.)+1.))*0.001));
        drawing += (clamp(distanceToSegment(suv,vec2(0.5,1.),position,0.005-((i)/7000.))+circle(suv,position,0.04-(i*0.0004)),0.,1.))/((i*0.01)+1.);
    }
    glFragColor = vec4(vec3(drawing),1.0);
}
