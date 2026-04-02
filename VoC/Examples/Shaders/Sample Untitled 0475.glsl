#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Hash21(vec2 p) {
    p = fract(p*vec2(234.34, 435.345));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}

vec2 lerp(vec2 a, vec2 b, float w) {
    float x = (1. - w) * a.x + w * b.x;
    float y = (1. - w) * a.y + w * b.y;
    return vec2(x,y);
}

void main( void ) {
    vec2 uv1 = ( gl_FragCoord.xy-.5*resolution.xy) / resolution.y ;
    vec2 uv2 = ((gl_FragCoord.xy ) / resolution.xy -.5) ;
    
    float aspectRatio = resolution.y / resolution.x;
    
    vec3 color = vec3(0);
    
    float w = (cos(time ) + 1.) / 2.;
    
    vec2 uv = lerp(uv1, uv2, w);
    
    //uv += time * .2;
    uv *= 50. + ((cos(time ) + 1.) / 2.) * 40.;
    
    //uv.x += time ;
    
    vec2 id = floor(uv);    
    

    vec2 gv = fract(uv) - .5;
    
    
    float n = Hash21(id); // random number between 0 and 1;
    float width = .2;
    
    
    if(n<.5) gv.x *= -1.;
    
    float mask = smoothstep(.01, -.01, abs(gv.x+gv.y) -width);
    mask += smoothstep(.01, -.01, abs(abs(gv.x+gv.y) -1.) -width);
    
    color += mask;
    
    //if(gv.x > .48 || gv.y > .48) color = vec3(1,0,0);
    
    glFragColor = vec4(color, 1.0 );

}
