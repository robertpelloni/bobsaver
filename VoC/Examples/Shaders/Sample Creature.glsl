#version 420

// original https://www.shadertoy.com/view/XdtyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a, b) smoothstep(-aa, aa, b-(a))
#define si(a) (sin(a)+1.)*2.
#define PI acos(-1.)

// 2d rotation
mat2 r2D(float a){
    return mat2(sin(a), cos(a), -cos(a), sin(a));
}

//bg vignette
float BG(vec2 uv){
    return 1.-length(uv);
}
//EYES (circles with custom aspect * rotation)
//s - size, r - angle, a - aspect, t - time, aa - antialiasing
float Eye(vec2 uv, float s, float r, float a, float t, float aa){
    uv *= r2D(r);
    uv.x *= a;
    float eye = 1.-S(s, length(uv));
    return eye;
}

//CREATURE
//s - size, t - time, aa - antialiasing
float Creature(vec2 uv, float s, float t, float aa){
    vec2 st = uv;
    
    //mouse input (thanks rigel!)
    // if (mouse*resolution.xy.w > .0) {
    //  vec2 ms = (mouse*resolution.xy.xy - resolution.xy * .5) / resolution.y;
    //  t = atan(ms.y-uv.y,ms.x-uv.x);
    //}
    
    //body warping motion
    //               cycles     amplitude
    st.x += cos(uv.y * 33. + t) * .007;
    st.y += sin(uv.x * 35. + t) * .009;
    
    //draw body
    float body = S(s, length(st)+abs(sin(atan(st.y,st.x)*25.)*.26*s));
    
    //x1pos, x2pos = position of the eyes on x
    //           offset      animation
    float x1pos =  .3*s +  si(t)*.01;
    float x2pos = -.3*s +  si(t)*.01;
 
    float ypos = .01;

    //rotation angle
    float an = -1.2;
  
    //                         pos offset       scale (offset+anim)     angle   aspect
    float eye1  = Eye(uv - vec2( x1pos, ypos), .27*s + si(t * 2.4)*.0016,   an,    1.2, t, aa);
    
          eye1 -= Eye(uv - vec2( x1pos + cos(t * 1.1)* .12*s, -.02 + ypos+sin(t)*.01), .08*s+si(t*2.4)*.0016, an, 1.2, t, aa);

    float eye2  = Eye(uv-vec2(x2pos, ypos), .27*s+si(t*2.2)*.0017, -an, 1.2, t, aa);
          eye2 -= Eye(uv-vec2(x2pos+cos(t*1.1+12.)*.12*s, -.015+ypos+sin(t*1.2+12.)*.01), .02+si(t*2.4)*.0016, an, 1.2, t, aa);
    
    body += eye1 + eye2;
    return body;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y;
    //vec2 uv = (gl_FragCoord/resolution.xy - .5)*vec2(resolution.x/resolution.y, 1.);
  
    float t = time*.5;
    
    float aa = 1./resolution.y;
   
    float creatures = Creature(uv, .3, t, aa);
    creatures *= Creature(uv+vec2(.55+sin(t*.2)*.07, .2+cos(t*.2)*.07), .2, t*.8, aa);
    creatures *= Creature(uv+vec2(-.45+sin(t*.2)*.07, -.2+cos(t*.2)*.07), .16, t*.6, aa);
    
 
    float col = BG(uv)*creatures;
    vec3 color = vec3(col);
    glFragColor = vec4(color,1.0);
}
