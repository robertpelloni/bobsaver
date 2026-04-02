#version 420

// original https://www.shadertoy.com/view/stySDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Infinity isometric zoom

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  http://www.iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

#define h21(p) ( fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453) ) //hash21
#define hue(v) ( .6 + .26 * cos(6.3*(v) + vec4(0,23,21,0) ) ) //hue

#define L 4.  //cycle duration

//  Minimal Hexagonal Grid - Shane
//  https://www.shadertoy.com/view/Xljczw
vec4 getHex(vec2 p) //hex grid coords 
{
    vec2 s = vec2(1, 1.7320508);
    vec4 hC = floor(vec4(p, p - vec2(.5, 1))/s.xyxy) + .5;
    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + .5);
}

vec3 HexToSqr (vec2 st) //hexagonal cell coords to square face coords 
{ 
    vec3 r;
    if (st.y > -abs(st.x)*.57777)
        if (st.x > 0.) 
            r = vec3((vec2(st.x,(st.y+st.x/1.73)*.86)*2.),2); //right face
        else
            r = vec3(-(vec2(st.x,-(st.y-st.x/1.73)*.86)*2.),3); //left face
    else 
        r = vec3 (-(vec2(st.x+st.y*1.73,-st.x+st.y*1.73)),0); //top face
    return r;
}

void main(void)
{
	vec2 g = gl_FragCoord.xy;
	vec4 O = gl_FragColor;

    vec2 r = resolution.xy
        ,u = (g+g-r)/-r.y
        ,t;
    
    float   T = mod(time,L) //cycle timer
        ,   F = sin(T/L*3.14) //cycle fade 0 to 1 to 0
        ,   m
        ,   n = floor(time/L)            //num of cycle
        ,   f = T/L                       
        ,   k = 0.
        ,   sm = 3./resolution.y + F*.1; //smoothness factor + bloor during a transition 
    
    bool p = true;  //previous layer visibility

    u -= u * (length(u)*F*.15); //camera distortion during a transition
    u /= T / L * 8. + 2.;   //camera zoom
    u.y += -.7225;              //camera shift to centre of pyramid
    O -= O;

    vec3 s;

    for (float i=0.; i <5. ; i++)  //draw 5 layers of cubes
    {
        t = fract(s.xy*5.)-.5;
        m = smoothstep (3.,1.,i-f);
        sm += i*.01;
        O = mix (O, vec4(0),smoothstep(.45-sm,.5+sm,max(abs(t.x),abs(t.y)))*m);  //draw grid lines on previous layer
        
        vec4 h = getHex(u);  //hexagonal grid of curent layer
        s = HexToSqr(h.xy);  //cube sides coordinates
        
        m = (p && abs(h.z)-(h.w) <= 1. && h.w < 1.) ? //cube visibility mask
            smoothstep (4.,3.,i-f)  //hide smalless cubes
            :0.;

        O = mix (O,
                hue(h21(h.zw+i+n+k) //color of cube 
                + h21(floor(s.xy*5.)+s.z)*.1) // + color variation on sides of cube
                    *(1.2 + smoothstep(.7,.2,length(s.xy-.5))*.3   //light gradient on sides
                        - smoothstep(.8,1.,s.y+s.x)*.4 //"ambient occlusion"
                        - (s.z*.2)  //sides lighting variation
                        - (i-f)*.2) //make small cubes darkest
                        ,m);

        u.y += .57804; //shift for next layer
        h = getHex(u); 
        p = p && abs(h.z)-(h.w) <= 1. && h.w <= 1.;  //check visibility for next layer
        u = h.xy*5.;
        k = h21(h.zw); //color variation factor of the layers
    }

	glFragColor=O;    
}
