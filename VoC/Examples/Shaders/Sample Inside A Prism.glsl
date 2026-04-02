#version 420

// original https://www.shadertoy.com/view/ldy3WG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define IT 256
#define ITF float(IT)
#define STR 1.5/sqrt(ITF)
#define A 1.0

#define M_PI 3.14159254

vec3 colorFilter(vec3 c) {
    vec3 color;
    
    float g = (c.r+c.g+c.b)/3.0;
    float s = abs(c.r-g)+abs(c.g-g)+abs(c.b-g);
    
    color = c*s+(1.0-s)*(c-s);
    
    return color*color;
}

vec3 value(vec3 pos) {
    vec3 color;
    
    color.r = sin(pos.x);
    color.g = sin(pos.y);
    color.b = sin(pos.z);
    
    return color;
}

vec3 scan(vec3 pos, vec3 dir){
    vec3 c = vec3(0.5);
    for (int i=0; i<IT; i++) {
        float f = (1.0- float(i)/ITF)*STR;
        
        vec3 posMod = value(pos);
        vec3 newPos;
        newPos.x = posMod.y*posMod.z;
        newPos.y = posMod.x*posMod.z;
        newPos.z = posMod.x*posMod.y;
        
        c+=value(pos+newPos*4.0)*f;
        pos+=dir*2.0;
    }
    return colorFilter(c);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.0)/resolution.y;
    float a = time*0.125;
    
    vec3 pos = vec3(cos(a/4.0+sin(a/2.0)),cos(a*0.2),sin(a*0.31)/4.5)*16.0;
    vec3 on = vec3(1.0,uv.x,uv.y);
    vec3 n;

    n = normalize(pos + vec3(cos(a*2.3),cos(a*2.61),cos(a*1.62)));
    vec3 crossRight = normalize( cross(n,vec3(0.0,0.0,1.0)));
    vec3 crossUp = normalize(cross(n, crossRight));
    n = n*1.5 + crossRight*uv.x + crossUp*uv.y;
    
    glFragColor.rgb = scan(pos,normalize(n)).rgb;
}
