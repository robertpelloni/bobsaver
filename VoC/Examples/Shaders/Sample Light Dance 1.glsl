#version 420

// original https://neort.io/art/bq9cja43p9f6qoqnmh2g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float hash(int x) { return fract(sin(float(x))*7.847); } 

float rand(float x)
{
    return fract(sin(x) * 4358.5453123);
}

float dSegment(vec2 a, vec2 b, vec2 c)
{
    vec2 ab = b-a;
    vec2 ac = c-a;

    float h = clamp(dot(ab, ac)/dot(ab, ab), -3.0, 3.);
    vec2 point = a+ab*h;
    return length(c-point);
}

vec3 hsv2rgb(float h, float s, float v)
{
    return ((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy-0.5;
    uv.x *= resolution.x/resolution.y;
    uv *= 6.0; 
    
    float t = time * 0.4 * .1;
    float s = sin(t);
    float c = cos(t);
    mat2 rot = mat2(c, -s, s, c); 
    uv *= rot;

    
    vec3 color = vec3(0.);
    vec3 hsv = hsv2rgb(time*0.05,1.0,0.7);
    //color = mix(vec3(0.0, 0.0, 0.0), color, abs(uv.x)*0.8);
    color = mix(hsv, color, abs(uv.x)*0.8);
    
    float power = 1.0-fract(time*2.1);
    //float power = 0.8;
    
        for(int i=0; i < 80 ; ++i)
    {
        vec2 a = vec2(hash(i)*3.-1., hash(i+1)*3.-1.)*1.0;
        vec2 b = vec2(hash(10*i+1)*2.-1., hash(11*i+2)*2.-1.);
        float z = 1.0-0.7*rand(float(i)*1.4333);
        vec3 lineColor = vec3(hash(2+i), hash(5+i*3), hash(18+i*10));
        float speed = b.y*2.5;
        float size = ((0.005 + 0.3*hash(5+i*i*2))*z)*0.5 + ((0.5+0.5*sin(a.y*3.+time*speed))*z)*0.5;
        
        a += vec2(sin(a.x*20.+time*speed), sin(a.y*15.+time*0.4*speed)*0.5);
        b += vec2(b.x*5.+cos(time*speed), cos(b.y*10.+time*2.0*speed)*0.5);
        float dist = dSegment(a, b, uv);
    
        color += mix(lineColor, vec3(0.), smoothstep(0., 1.0, pow(dist/size,power*(0.5+0.5*sin(time*2.+size+lineColor.x*140.))*0.20) ));
    }

    glFragColor = vec4(color, 1.0);
}
