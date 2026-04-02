#version 420

// original https://www.shadertoy.com/view/WsXyW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sat(x) clamp(x,0.,1.)
 
float remap01(float a,float b,float t)
{
    return sat((t-a)/(b-a));
}
 
float remap(float a,float b,float c,float d,float t)
{
    return sat((t-a)/(b-a))*(d-c)+c;
}

vec3 rect(vec2 uv, float left, float right, float bottom, float top, float blur)
{
    return (vec3(smoothstep(left,left+blur, uv.x)) - vec3(smoothstep(right,right+blur, uv.x))) * 
        (vec3(smoothstep(bottom,bottom+blur, uv.y)) - vec3(smoothstep(top,top+blur, uv.y)));
}

vec3 circle(vec2 uv, vec2 offset, float radius, float blur)
{
    return 1. - vec3(smoothstep(radius, radius+blur, length(uv - offset)));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x / resolution.y;
    uv -= .5;
    
    // background
    vec3 col = vec3(0., .858, .447);
    
    // face
    uv.x *= 1.55;
    float a=sin(time*8.)*0.02;
    col += circle(uv, vec2(-.1,.1+a),.3, 0.003);
    col = mix(col, vec3(0., .858, .447), smoothstep(0.25, 0.248, length(uv - vec2(.15,-.1-a))));
    col += circle(uv, vec2(.15,-.1-a),.23, 0.003);
    
    // eye
    uv.x /= 0.85;
    float o = sin(time*10.)*0.01;
    float eyes = smoothstep(.04,.037,length(uv - vec2(-0.23+o,.2))) + smoothstep(.04,.037,length(uv - vec2(-0.+o,.2)));
    eyes += smoothstep(.034,.031,length(uv - vec2(0.1-o,-0.02))) + smoothstep(.034,.031,length(uv - vec2(0.27-o,-0.02)));
    col = mix(col, vec3(0., .858, .447), eyes);
    
    // tail
    float x = uv.x+.3; float y = uv.y+.14;
    x -= y*.4; y -= x;
    col += rect(vec2(x,y-a),-.05,.05,-.05,.05, 0.01);
    
    x=uv.x-.26; y=uv.y+.26;
    x += y*.4; y += x;
    col += rect(vec2(x,y+a),-.05,.05,-.05,.05, 0.01);
    
    glFragColor = vec4(col,1.0);
}
