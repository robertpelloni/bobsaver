#version 420

// original https://www.shadertoy.com/view/tdGGD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 p) {
    return fract(7346.2*sin(845.1*p.y+635.2*p.x));
}
 
float checker(vec2 p) {
    return 2.*mod(p.x+p.y, 2.)-1.;
}

float pattern(vec2 p, vec2 seed) {
    vec2 uv = p-.5;
    uv.y += time*.1;
    float scale = 8.;
    vec2 gv = fract(uv*scale)-.5;
    vec2 id = floor(uv*scale);
    
    float check = checker(id);
    float flip = 1.;
        
    if (hash21(id+seed) < .5) flip = -1.;
    
    gv.x *= flip;
    vec2 cUv = gv-sign(gv.x+gv.y+.0001)*.5;
    float angle = atan(cUv.x,cUv.y);
    float d = length(cUv);
    float width = .07;
    float mask = smoothstep(.01,-.01,abs(d-.5)-width);

    return mask;    
    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.y)/resolution.y;
    float scale = (sin(time*.2)+1.)*6.+1.;
    vec2 gv = fract(uv*scale)-.5;
    vec2 id = floor(uv*scale);
    
    float check = checker(id);
    bool ch = true;
    if (check > 0.) ch = false;
    float flip = 1.;
        
    if (hash21(id) < .5) flip = -1.;
    
    gv.x *= flip;
    vec2 cUv = gv-sign(gv.x+gv.y+.0001)*.5;
    float angle = atan(cUv.x,cUv.y);
    float d = length(cUv);
    float width = .15;
    float edge = .1;
    float a = asin((d-.5)/width);
    float mask = 1.7-1.5*abs(a);
    float flow = sin(time*10.+check*angle*10.);
    
    vec2 xy = vec2(fract(check*angle/1.5708),a*check*flip*width*2.);
    
    
    vec3 col = vec3(pattern(xy, id))*mask;
     
                    
   // if (gv.x > .47 || gv.y > .47) col = vec3(1.0,0,0); //border
    glFragColor = vec4(col,0.0);
}
