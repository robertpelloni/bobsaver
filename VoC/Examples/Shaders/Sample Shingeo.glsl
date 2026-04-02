#version 420

// original https://www.shadertoy.com/view/3sjGDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author @patriciogv ( patriciogonzalezvivo.com ) - 2015

#ifdef GLES
precision mediump float;
#endif
#define PI 3.14159265359

float box(in vec2 st, in vec2 size){
    size = vec2(0.5) - size * 0.5;
    vec2 uv = smoothstep(size,
                        size+vec2(0.003),
                        st);
    uv *= smoothstep(size,
                    size+vec2(0.003),
                    vec2(1.0)-st);
    return uv.x*uv.y;
}

float cross2(in vec2 st, float size){
    return  box(st, vec2(size,size/4.)) +
            box(st, vec2(size/4.,size));
}

float circle(in vec2 st, in float radius){
    vec2 l = st-vec2(0.5);
    return 1.-smoothstep(radius-(radius*0.01),
                         radius+(radius*0.01),
                         dot(l,l)*4.0);
}

mat2 rotate2d(float angle){
    return mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}

float borderBox(vec2 st, vec2 size, float border){
    return box(st, size + border) - box(st, size );
}

vec2 circleMovement(float time){
    return vec2(sin(time)  ,cos(time)*1.5);
}

// Limit one is used so the color variable never goes beyond 1.0.
// If it goes beyond 1 or 0 it makes things more complicated than they need to be :(
vec3 limit(vec3 limited, float nMin, float nMax){
    return min(vec3(nMax),max(vec3(nMin), limited));
}
float limit(float limited, float nMin, float nMax){
    return min(nMax,max(nMin, limited));
}
vec3 limitone(vec3 limited){
    return limit(limited,0.,1.);
}
float limitone(float limited){
    return limit(limited,0.,1.);
}

vec3 seeThroughBox(vec2 st, vec3 color, vec2 size, float border, float time, vec3 bg ){
    
    
    st+= circleMovement(time ) * 0.2;
    // Always limit color to 0->1.
    // Then, clip the background with that same inside
    // This functions is the same as BorderBox, but instead multiplies the values together
    // Giving only the insides of the rectangle
    float inside = box(st, size + border) * box(st, size );

    // First make the inside black to start with, so the color that was there before doesn't interfiere
    // If we remove this part, when we perform the next step, color will be always 1, because we keep adding and adding numbers.
    // Thus, making the inside white, and sometimes red in the borders
    color = limitone(color - inside);
    // Then, introduce the background color only in the inside
    // Since the inside is 1 and outside is 0. The multiplication will make sure only the inside gets the background
    color =  limitone(color + bg * inside);
    // And add the border
    color += vec3(-1) * vec3(borderBox(st,size,border));
    
    return color;
    
}
void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec3 color = vec3(1.0);
    
    // Math: pink insite and outside black + black inside and white outside 
    // In a sum, colors take presedence over black, so it ends up like this
    vec3 centerBox = vec3(0.9, 0.3,0.3) * limitone( circle(st,0.3 )) + vec3(1.) * ( 1. - limitone( circle(st,0.3 )));
    // color += centerBox;
    
    st -= 0.5;
    // Slightly rotate them from the center
    // Give a really cool effect
    st *= rotate2d(PI * sin(time / 8.) * 1.); 
    st += 0.5;
    
    vec2 size = vec2(0.4,0.25);
    float border = 0.01;
    
    float PI2 = PI + PI;
    
    color = seeThroughBox(st,color,size,border,time + PI2/5. * 0., centerBox);
    color = seeThroughBox(st,color,size,border,time + PI2/5. * 1., centerBox);
    color = seeThroughBox(st,color,size,border,time + PI2/5. * 2., centerBox);
    color = seeThroughBox(st,color,size,border,time + PI2/5. * 3., centerBox);
    color = seeThroughBox(st,color,size,border,time + PI2/5. * 4., centerBox);
    
    glFragColor = vec4(color, 1.0);
}
