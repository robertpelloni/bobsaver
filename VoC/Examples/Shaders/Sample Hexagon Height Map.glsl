#version 420

// original https://www.shadertoy.com/view/WljyD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//     Hexagon Tiled Height Map
// 
//    Golf anyone?
//    
//  Hex tutorial from @BigWIngs 
//  https://www.youtube.com/watch?v=VmrIDyYiJBA
// 
//////////////////////////////////////////

#define R resolution
#define T time
#define S smoothstep
// https://www.shadertoy.com/view/wsjfRD
// A white noise function.
float rnd(vec3 p) {
    return fract(sin(dot(p, vec3(12.345, 67.89, 412.12))) * 42123.45) * 2.0 - 1.0;
}

// A perlin noise function.
float PR(vec3 p) {
    vec3 u = floor(p),
         v = fract(p),
         s = S(0., 1., v);
    
    float a = rnd(u),
          b = rnd(u + vec3(1., 0., 0.)),
          c = rnd(u + vec3(0., 1., 0.)),
          d = rnd(u + vec3(1., 1., 0.)),
          e = rnd(u + vec3(0., 0., 1.)),
          f = rnd(u + vec3(1., 0., 1.)),
          g = rnd(u + vec3(0., 1., 1.)),
          h = rnd(u + vec3(1., 1., 1.));
    
    return mix(mix(mix(a, b, s.x), mix(c, d, s.x), s.y),
               mix(mix(e, f, s.x), mix(g, h, s.x), s.y),
               s.z);
}

float hd(vec2 p) {                                        // hex functions
    return max(dot(abs(p),normalize(vec2(1.,1.73))),abs(p.x)); 
}

vec4 hx(vec2 p) {
    vec2 r = vec2(1.,1.73),
         hr = r*.5,
         GA = mod(p,r)-hr,
         GB = mod(p-hr,r)-hr,
         G = dot(GA,GA)<dot(GB,GB) ? GA : GB; 
    return vec4(atan(G.x,G.y),0.5-hd(G),(p-G));
}

void main(void) {
    vec2 F = gl_FragCoord.xy;

    vec2 U = (2.*F.xy-R.xy)/max(R.x,R.y);                // set up coords

    vec3 lp = vec3(0.),
         ro = vec3(-3.21,8.,-8.);

    vec3 cf = normalize(lp-ro),                            // set camera/ray
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .95,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec3 C = vec3(0.),
         p = vec3(0.);

    vec4 t = vec4(0.),
         d = vec4(0.);

    for (int i = 0; i<128;i++)                            // marching
    {
        p = ro + d.x * rd;
        
        p.xz*= mat2(cos(T*.16+vec4(0,11,33,0)));        //@Fabrice
        p += vec3(50.,2.,T*1.15);                        // map
        vec4 H = hx(p.xz*.25) * 1.;
        float PR = PR(vec3(H.zw,T*1.25)),
              Hmap = .12*(p.y-PR)/1.;
        t = vec4(Hmap,PR,H.z,H.y);

        d.yzw = t.yzw;
        if(t.x<.0001*d.x||d.x>50.) break;
        d.x += t.x;
    }

    float M = 1.+1.*sin(d.z+T);                            // mate and color
    if(d.x<50.) {
        C += vec3(M,1.-M,1.)*S(.04,.05,d.w);
        C += vec3(1.-M,M,1.)*S(.2,.21,d.w);
    }
    glFragColor = vec4(pow(C, vec3(0.4545)),1.);                    // gamma out
}

