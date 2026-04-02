#version 420

// original https://www.shadertoy.com/view/ttG3Dd

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define rot(a) mat2(cos(a + PI*0.5*vec4(0,1,3,0)))

vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    float zoom = exp(-time*0.1);
    uv *= mix(20.0, 70.0, zoom); // progressive zoom
    uv.y += 1.0;
    
    const vec3 background = vec3(0.8, 0.85, 0.9);
    const vec3 light = normalize(vec3(1, 2, 3));
    const vec3 lightColor = vec3(0.9, 0.8, 0.5);
    
    float dd = dot(uv,uv);
    glFragColor = vec4(background, 1);
    
    vec2 mou = (mouse*resolution.xy.xy-resolution.xy*0.5)/resolution.xy*4.0;
    //if (mouse*resolution.xy.z < 0.5) mou = vec2(0);
    
    #define LAYERS 20
    
    for (int i = min(0, frames) ; i < 2 ; i++) {
        for (int r = min(0, frames) ; r < LAYERS ; r++) {
            
            int rr = i == 0 ? LAYERS - r - 1: r;
            float radius = float(rr*rr+1)*0.05;
            
            vec3 pHere = vec3(uv, sqrt(max(0.0, radius*radius-dd)));

            float sig = float(i*2-1);
            vec3 p = pHere;
            p.z *= sig;
            vec3 n = p/radius;
            n *= sig;

            float dist = max(0.0, 2.0 - p.z);

            float time = time*0.05 + float(rr)*0.3;
            p.zy *= rot(2.2+mou.y);
            p.xz *= rot(-0.1+mou.x);
            p.yx *= rot(time);
            p.xz *= rot(sin(time*8.145)*0.2);
            p.zy *= rot(sin(time*6.587)*0.2);

            float at = atan(p.x, p.y);
            float rad = (sin(at*5.0)*0.6 + 0.2)*radius;
            
            // anti-aliased petal border
            float df = rad-p.z;
            float aa = fwidth(df);
            float sm = smoothstep(aa, -aa, df);
            // anti-aliased wrap around border
            float dfs = dd-radius*radius;
            float aas = fwidth(dfs);
            sm *= smoothstep(aas, -aas, dfs);

            // fake normal mapping
            float str = cos(at*5.0)*20.0;
            str *= smoothstep(0.1, 0.0, abs(str/30.0));
            float dotl = max(0.0, dot(light, n)+str*0.05);
            // basic lighting + fog
            vec3 albedo = vec3(0.2, 0.3, 0.8);
            float ao = 1.0-min(1.0, exp((p.z/radius-1.0)));
            vec3 col = albedo*lightColor*dotl*3.0 + albedo*background*0.4*ao;
            col = mix(background, col, exp(-dist*0.1));
            // accumulate color
            glFragColor.rgb = mix(glFragColor.rgb, col, sm);

        }
        
    }
        
    // gamma correction, vignette, dithering
    glFragColor.rgb = pow(glFragColor.rgb, vec3(1.0/2.2));
    vec2 uu = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.xy;
    glFragColor.rgb = mix(glFragColor.rgb, vec3(0), dot(uu,uu)*0.5);
    glFragColor.rgb += (hash33(vec3(gl_FragCoord.xy, frames))-0.5)*0.02;
    
}
