#version 420

// original https://www.shadertoy.com/view/wstXR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Submission to Cookie demo party fan zine -- by @connrbell
#define ANIMATE 1

// pR from mercury.sexy/hg_sdf
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// smin and sdBox by iq - https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k ){
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
float sdBox( vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
// --

float hollowBox(vec3 p, vec3 b, float edge) {
    float res = sdBox(p,b);
    float edgeLow = (1.0 - edge * 0.5);
    float edgeHigh = (1.0 + edge * 0.5);
    vec3 size = vec3(b.x*edgeLow, b.y*edgeLow, b.z*edgeHigh);

    res = max(res, -sdBox(p, size));
    res = max(res, -sdBox(p, size.xzy));
    res = max(res, -sdBox(p, size.zyx));
    return res;
}

float map(vec3 p) {
    float scale = .55, distFromCam = length(p)*3., res = 1e20;
    vec3 boxPos = p + vec3(0.,1.,-3.);

    p.xyz = mod(p.xyz, vec3(2.)) - vec3(1.);

    for (int i = 0; i < 7; i++) {
        p = abs(p) + vec3(-.5, -.5, -.5) * scale;

        pR(p.xz, 3.4 + cos( time + distFromCam + float(i)*0.333)*0.15);
        pR(p.xy, .35 + sin( time + distFromCam + float(i)*0.333)*0.15); 
   
        scale *= 0.6;
        
        res = min(res,sdBox(p,vec3(scale)));    
    }
    pR(boxPos.xz,1.570795*0.65+time);
    pR(boxPos.xy,1.570795*0.5+sin(time)*0.35);
    res = smin(res, hollowBox(boxPos,vec3(.2), 0.075), 0.125);
    return min(res, sdBox(boxPos,vec3(.1)));
}

void getColor (out vec4 glFragColor, in vec2 gl_FragCoord, vec3 ro) {
    
    //time2 = 4.65 + time * float(ANIMATE);
    vec2 p = -1.0+2.0*gl_FragCoord.xy/resolution.xy;
    p.x *= resolution.x/resolution.y;

    vec3 rd = normalize(vec3(p.x, p.y-0.5, 4.));
     float dist = 0.;   
    
    for (int i = 0; i < 65; i++) {
           dist += map(ro + rd * dist);
       }

    vec3 pos = ro + rd * dist;
    vec3 col = vec3(map(pos + normalize(vec3(0., .1, -3.)) * 0.0025 )) / 0.0015;
    
    col = mix(col, vec3(0.), clamp((dist)/5., 0., 1.));
    
    glFragColor = mix(vec4(.0), vec4(pow(col,vec3(0.5)), 1.), 1.-smoothstep(0.,1.,length(p)*0.5));
}

void main(void)
{
    float divergence = 0.01;
    vec4 red = vec4(0);
    vec3 ro = vec3(0.-divergence, -.75, 0.75);
    getColor(red, gl_FragCoord.xy, ro);
    vec4 cyan = vec4(0);
    ro = vec3(0.+divergence, -.75, 0.75);
    getColor(cyan, gl_FragCoord.xy, ro);
    glFragColor = vec4(red.r, cyan.gb, 1);
}
