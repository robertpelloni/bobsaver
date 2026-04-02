#version 420

// original https://www.shadertoy.com/view/tscBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Hash21(vec2 p) {
    p = fract(p*vec2(234.34, 435.34));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 UV = gl_FragCoord.xy/resolution.xy;
    vec3 col = vec3(0);
    
    //uv += time*.1;
    uv *= 3.;
    
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    //if (gv.x>.01 || gv.y>.01) col = vec3(.1,0,0); // fract border
    float n = Hash21(id); // random number 0 -> 1
    
    //float width = .4*abs(UV.y-.5)+0.01;
    float width = .8;
    
    if (n<.5) gv.x *= -1.;
    
    float d = abs(abs(gv.x+gv.y)-.5);
    
    vec2 cUv = gv-sign(gv.x+gv.y+.0001)*.5;
    d = length(cUv);
    float mask = smoothstep(.01, -.01, abs(d-.5)-width);
    
    float checker = mod(id.x+id.y, 2.)*2.-1.;
    float angle = atan(cUv.x, cUv.y); // -pi to pi
   
    float ch = ((sin(time))+1.)/2.;
    float flow = sin(time+checker*angle*4.);
    
    float x = (angle/3.);
    float y = (d-(.5-width))/(2.*width);
    y = abs(y-.5)*2.;
    
    vec2 tUv = vec2(x, y);
    //col.rg += tUv*mask;
    
    col += abs(flow*mask+tUv.x*sin(time));
    col.b *= checker*.5;
    col.r -= checker*.05;
    col.g = .07;
    //col.b = .0;
    

    glFragColor = vec4(col,1.0);
}
