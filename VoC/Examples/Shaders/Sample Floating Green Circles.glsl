#version 420

// original https://www.shadertoy.com/view/7dKXDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 keyLime = vec3(236., 243., 158.)/255.;
const vec3 olivine = vec3(144., 169., 85.)/255.;
const vec3 sapGreen = vec3(79., 119., 45.)/255.;
const vec3 hunterGreen = vec3(49., 87., 44.)/255.;

float sdCircle(vec2 st, float r){ 
return length(st) - r; 
} 

float stroke(float x, float w, float s){ 
    w *= .5; 
    return 1.-smoothstep(w-s,w+s,abs(x)); 
} 

float fill(float sdf,float s){
    return 1.-smoothstep(-s,s,sdf);
}

vec3 draw(vec3 col, vec3 addCol, vec2 uv, float mult){
    uv *= mult;
    uv.x += time;
    uv.y += (time*.01*mult) * step(1.,mod(uv.x,2.));
    uv.y -= (time*.01*mult) * (1.-step(1.,mod(uv.x,2.)));
    uv = fract(uv);
    col = mix(col,vec3(.05),fill(sdCircle(uv-.5,.2),.04));
    col = mix(col,addCol,stroke(sdCircle(uv-.5,.15),.1,.0015*mult));
    return col;
}

void main(void) {
    vec3 col = hunterGreen;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;

    col = draw(col, keyLime, uv, 10.);
    col = draw(col, olivine, uv, 5.5);
    col = draw(col, sapGreen, uv, 3.5);

    glFragColor = vec4(col,1.0);
}
