#version 420

//////////////////////////////////
//                //
//          VRG corp              //
//                //
//        Le kubikoto,        //
//       Le kubikoto,        //
//        Le kubikoto,    //
//           ....        //
//   A les plus gros biscotos   //
//                   //
//////////////////////////////// *

//////////////////////////////////
//                //
//   Notes:                  //
//   - Remove // before the    //
//    #define in order to    //
//         activate the effects    //
//                //
//                   //
//////////////////////////////// *

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359

//#define MATRIX
//#define TRANQUILLE_LA_BITE

#ifdef TRANQUILLE_LA_BITE
    #define time (time*.1)
#endif

// original kali fratal function
// http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/
vec2 transform(vec2 p, float cx, float cy){
    p.x=abs(p.x);
    p.y=abs(p.y);
    float m=p.x*p.x+p.y*p.y;
    p.x=p.x/m+cx;
    p.y=p.y/m+cy;
    
    return p;
}
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 c2p(vec2 p){
    return vec2( length(p), atan(p.y, p.x));
}
vec2 p2c(vec2 p){
    return vec2(cos(p.y)*p.x, sin(p.y)*p.x);
}

void main( void ) {

    vec2 surfacePosition=( gl_FragCoord.xy / resolution.xy )-mouse;
    vec2 uv = 200000.*surfacePosition.xy / resolution.xy ;
    uv-=vec2(.5);
    uv.x*=resolution.x/resolution.y;
    
    uv = p2c(c2p(uv) + vec2(0., cos(time*10.)*0.01*PI));
    vec2 p = uv;
    //p += normalize(p)*cos(time)*4.;
    vec2 polar = c2p(p);
    float cxA = -.5;
    float cyA = -.5;
    float cxB = mix(-abs(cos(time*0.0005)*2.), -.5,  .5+.5*cos(time*.1));
    float cyB = mix(-abs(sin(time*0.005)*2.), -.5,  .5+.5*cos(time*.1));
    for(int n = 0; n < 16; n++){
        if(mod(float(n), 2.) == 0.){
            p = transform(p, cxA, cyA) ;
        } else {
            p = transform(p, cxB, cyB) ;
        }
            
    }
    float weight = cos(length(p))*.5+.5 + cos(time*.5)*.5+.5;
    
    #ifdef MATRIX
        vec3 color = mix(vec3(0.1, 0.1, 0.1), vec3(0.1, 1., 0.1), smoothstep(.45, .75, weight*.5)) ;
    #else
        vec3 color = hsv2rgb(vec3(1.-weight, 1., weight*.25+.5));
    #endif
    
    vec2 textCoord = gl_FragCoord.xy/resolution.xy;
    textCoord-=normalize(uv)*.001;
    color =mix(color, texture2D(backbuffer, textCoord.xy).rgb, smoothstep(0.9, 1., 0.01*length(uv)));
    glFragColor = vec4( vec3(color), 1.0 );

}
