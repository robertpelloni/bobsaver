#version 420

// original https://www.shadertoy.com/view/tl2yDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define resolution resolution
#define time time
mat2 rot(float a){
    return mat2(cos(a), sin(a), sin(-a), cos(a));
}
void main(void)
{
    vec2 ouv = gl_FragCoord.xy / resolution.y;
    vec2 uv2 = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    vec2 uv3 = uv2;
    vec2 uv4 = uv2;
    vec2 uv = gl_FragCoord.xy / vec2(resolution.x*.6, resolution.y);
    vec2 st = gl_FragCoord.xy / vec2(resolution.x*.6, resolution.y);

    uv.y += .5;
    uv.x -= .833;
    float m = .8;
    uv.y *= 1.*pow(uv.y, (ouv.y*5.))+m;
    uv.y -= m;
    uv.x *= uv.y;
    uv2.y *= uv.y*75.;
    uv2.y += time*5.;
    uv *= rot(-((0*resolution.xy.x+(resolution.x*.5))-(resolution.x))/resolution.x*6.275);
    st.y += -.1;

    uv.y -= time*.1;

    uv = fract(uv*10.);

    float d = mix(.0, 1., smoothstep(.15, .145, distance(uv3, vec2(.0, .25))));
    float d2 = d;
    float d3 = mix(.0, 1., smoothstep(.4, .1, distance(uv3, vec2(.0, .25))));

    /*float l = smoothstep(.0, uv.x*1.5, .05);
    float r = smoothstep(1., uv.x*.966, .95);
    float b = smoothstep(.0 ,uv.y , .05);
    float t = smoothstep(1., uv.y, .95);*/
    float l = smoothstep(uv.x*1.333, .0, .05);
    float r = smoothstep(uv.x*.966, 1., .95);
    float b = smoothstep(uv.y , .0, .05);
    float t = smoothstep(uv.y, 1., .95);

    vec3 col = vec3(0.);

//    if (uv.x*1.5 >= .1 && uv.x*.966 <= .9 && uv.y >= .1 && uv.y <= .9 ){
    //col = vec3(1., .0, 1.);
//}
    /*col += l;
    col += r;
    col += b;
    col += t;*/
    float al = l*r*b*t;
    col = vec3(1.-al);
    col *= smoothstep(st.y, 1.5, .65);

    col *= vec3(1., .0, 1.);
    
    col *= pow(col, vec3(.24545));    //shhh, no witnesses
    col *= 5.;
    float ni = clamp(.0, .0, (sin(time+uv2.y-.5)+.5));
    ni = pow(ni,2.);
    vec3 dc = vec3(.8, .4, .1);
    vec3 dc2 = vec3(.8, .4, .1);
    uv4.y *= d2*2.;
    dc *= 1.+smoothstep(1., .0, 1.-uv4.y)-(1.-d);
    dc2 *= 1.+smoothstep(1., .0, 1.-uv4.y)-(1.-d3);
    d *= ni;
    if (d <= .0 && uv3.y <= .21){
        d2 *= d;
    }
    uv3.y += -.175*cos(uv3.x)+.175;
    float mi = smoothstep(.0, .5, uv3.y);
    vec3 mist = vec3(1., .1, .8);
    mist *= vec3(mi);
    col += vec3(dc*d2*.65+dc2*.5+mist*.5);
    col *= pow(col, vec3(.4545));
    glFragColor = vec4(col,1.0);
}
