#version 420

uniform float time;
uniform vec2 mouse, resolution;

out vec4 glFragColor;

// nabr
// https://www.shadertoy.com/view/tdlGWr
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

#define AA 1
#define R(p, a) p = (cos(a) * (p) + sin(a) * vec2(p.y, -p.x))
#define RR resolution

vec3 tex( in vec2 st) {
    
    float tm = time * 2.5;
    
    // scale
    float tmp = .45;
    tmp *= .5*exp(mouse.y*2.) ;
    
    // texure coords
    st = (vec2(mod(0.001 - st * tmp, vec2(2.513, 2.513)))) - 1.256;
   
    vec3 rd = vec3(abs(st), -2.081), pt = vec3(0.0);
    
    // colors
    lowp vec3 tmpc = vec3(0.0), finc = vec3(0.0), O = vec3(0.0);
    
    // surface
    vec3 s = vec3(sin(tm + rd.y), 10. * cos(tm + rd.y) * .5 - .5, 200.);
    
    R(s.yz, tm * .0251);
    R(s.zx, tm * .0521);
  
    
    // -------- RAYMARCH 
    float t = 0.001, d = 0.0;
  
    for (float i = 0.; i <= 1.0; i += 0.08333) 
    {
        
        if (t > 8.0 && d > 0.1) break;
        
        // surface
        if (sin(t) > 0.7)
            rd = reflect(-rd, 0.5 * normalize(s * vec3(6.283186 * tan(pt.x * 3.141) * (125. - sin(tm)),0.6 * max(2.0, (cos(tm) - 55.) * sin((pt.y - tm * 0.1)) * RR.y),120.0 * max(-24.0, cos(tm) - 0.1001 * RR.y * tan(pt.y * 3.141)) - .1)));
        
        // formula
        d = min(cos(pt.y), abs(pt.x) - 4.0);
        d = ((sqrt((pt.y - d) * (pt.y - d) * 0.094) - 0.92) + min(abs(1.5 + 0.1 * sin(tm * 0.1 - pt.z * 0.2) - (cos(pt.y * 0.06) * 1.091 - cos(pt.x * 0.05))), length(pt) - 2.2));
        
        pt = vec3(pt.xy, pt.z * 1.66) + (rd * d);
        
        t = t + d;
        
    };
    
    // -------- shade    
    O = vec3(0.31, 0.29, 0.28) + (d - 1.25) * 0.5 + t * 0.03 + t * vec3(0.2, 0.14, 0.12) * 0.255 * -(rd.x);
    
    tmpc = (O * vec3(1.185, 1.225, 1.251));
    
    if ((t < 8.25)) {
        finc = clamp(((1.0 - O) / 0.5), 0.0, 1.0);
        O = (O * (finc * (finc * (3.0 - (2.0 * finc)))));
        tmpc = (tmpc + ((0.5 * fract((sin(dot(vec2((st.x * RR.y), 0.001), vec2(13., 79.))) * 43758.))) * O));
        tmpc = (tmpc + ((0.4 * fract((sin(dot(vec2(st.y * RR.y), vec2(13., 79.))) * 43758.))) * O));
    };
        
    O = clamp((tmpc / (2.5 - O)), 0.0, 1.0);
    
    
    return pow(clamp((O * (O * (3.0 - (2.0 * O)))), 0.0, 1.0), vec3(0.245));

}

void main()
{
    
    vec3 col = vec3(0.);
    
    // planes
    vec3 pl = vec3(0, 0, 3), 
         pn = normalize(vec3(0, 0, 1));
    vec3 pl1 = vec3(0, 0, 2.901), 
         pn1 = normalize(vec3(0, 0, .1));

    // antialiasing - https://www.shadertoy.com/view/tslGz7
    // thx to IQ!
    for (int jj = 0; jj < AA; jj++)
        for (int ii = 0; ii < AA; ii++) {

            vec2 q = gl_FragCoord.xy + vec2(float(ii), float(jj)) / float(AA);
            vec2 st = (2. * q - RR.xy) / min(RR.x, RR.y);
            
            // frame
             //if(iMouse.z <= 0.0)
            if ((abs(st.x)) > 1.677 || abs(st.y) > .829) 
            
            //if ((abs(st.x)) > 1. || abs(st.y) > .749)     
            {
                glFragColor = vec4(vec3(1.45 - max(abs(-st.y * .75), 0.)), 1.);
                return;
            };
            
            vec3 ray = normalize(vec3(st, 1.33511) - vec3(0., 0., -.1));
            
            // raytracing planes
            float a = dot(-pl, pn), b = dot(pn, -ray), t = a / b;
            float a1 = dot(-pl1, pn1), b1 = dot(pn1, -ray), t1 = a1 / b1;
            
            // shade
            (t1 > 0. || t > 0.) ?
            col += pow(.5 * ((tex(ray.xy * t) + tex(ray.yx * 1.025 * t1))), vec3(1.35))
                : col;
        };
            
    col = col / float(AA * AA);
    
    glFragColor.rgb = col;
    glFragColor.w = 1.0;
}
