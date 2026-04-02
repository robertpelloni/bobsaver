#version 420

// original https://www.shadertoy.com/view/wlfyzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 p) {
    p = fract(p * vec2(233.34, 851.74));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

float qCircle(vec2 uv){
    float p;
    float d = length(uv);
    
    p = smoothstep(0.2,0.19,d);
    p -= smoothstep(0.1,0.09,d);
    
    return p;
    
}

vec3 layer(vec2 uv, float size, vec2 scroll, vec3 color,vec3 canvas){
    uv *= size;
    uv += scroll;
    
    vec2 gv = fract(uv);
    vec2 id = floor(uv);
    float n = hash21(id);
    n = floor(n*2.0);
    
    float d1,d2;
    float off = 1.0;
    
    if (n==0.0){
        d1 = length(gv-vec2(0.0,0.0));
        d2 = length(gv-vec2(off,off));  
    } else {
        d1 = length(gv-vec2(off,0.0));
        d2 = length(gv-vec2(0.0,off));
    }
    
    // truchet
    float p = smoothstep(0.65,0.64,d1);
    p -= smoothstep(0.35,0.34,d1);
    p += smoothstep(0.65,0.64,d2);
    p -= smoothstep(0.35,0.34,d2);
    
    // inner circle
    p += qCircle(gv-vec2(0.0));
    p += qCircle(gv-vec2(0.0,off));
    p += qCircle(gv-vec2(off,0.0));
    p += qCircle(gv-vec2(off,off));
    
    // add color
    if (p==1.0){
        canvas = color;
    }
    
    return canvas;
    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    vec3 canvas = mix(vec3(1.0,1.0,0.0),vec3(1.0,0.0,0.0),uv.x);
    glFragColor = vec4(canvas,1.0);
    
    float a = time/4.0;
    uv = uv * mat2(cos(a),-sin(a),sin(a),cos(a));
    
    vec3 l = layer(uv,50.0,vec2(time/8.0,0.0),vec3(0.2),canvas);
    l = layer(uv,20.0,vec2(0.0,sin(time/4.0)),vec3(0.5),l);
    l = layer(uv,8.0,vec2(time/2.0,sin(-time/2.0)),vec3(0.7),l);
    l = layer(uv,6.0,vec2(cos(-time/1.5),time/1.5),vec3(0.98),l);
    glFragColor = vec4(l,1.0);
    
    
}
