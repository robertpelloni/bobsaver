#version 420

// original https://www.shadertoy.com/view/sdfSz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)

float layer(vec2 p, float sc, float flip){
    vec2 uv = fract(p)-0.5;
    vec2 id = floor(p);
    
    vec2 randP = fract(sin(id*123.456)*567.89);
    randP += dot(randP,randP*34.56);
    float rand = fract(randP.x*randP.y);
    float scale = 0.05;
    
    float lineW = 0.14;
    
    if(rand<0.5 || rand>=0.8){
        float dir = (rand>=0.8)?1.0:-1.0;
        uv*=Rot(radians(dir*45.0*flip));
        uv.x = abs(uv.x);
        uv.x-=0.355;
        lineW = 0.1;
    }
    
    lineW*=sc;
    float d = max(-(uv.x+(lineW*0.5)),(uv.x-(lineW*0.5)));
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    uv.xy *= Rot(radians(sin(time*.3)*20.0));
    
    float d2 = abs(uv.y);
    float k = 1. / d2;
    uv = uv * k + vec2(0, k);
    uv.x-=time*0.5;
    
    vec2 prevUV = uv;
    uv*= 3.0;
    
    uv.y-= time*2.2;
    
    vec3 col = vec3(0.0);
    float d = layer(uv,0.6,1.0);
    
    col = mix(col,vec3(1.0,1.0,1.0),S(d,0.0));
        
    uv = prevUV;
    uv*= 2.6;
    uv.y-= time*2.1;
    d = layer(uv,0.4,-1.0);
    col = mix(col,vec3(0.5,0.7,1.0),S(d,0.0));

    uv = prevUV;
    uv*= 2.4;
    uv.y-= time*2.5;
    d = layer(uv,1.8,1.0);
    col = mix(col,vec3(1.0,0.2,0.5),S(d,-0.2));
    
    vec3 prevCol = col;
    
    uv = prevUV;
    uv*= 2.2;
    uv.y-= time*2.6;
    d = layer(uv,1.8,-1.0);
    col *= S(d,-0.2);
    
    col = prevCol+(col*6.0);
    
    col*=d2*1.5;
    
    float brightness= 0.9;
    glFragColor = vec4(col*brightness,1.0);
}
